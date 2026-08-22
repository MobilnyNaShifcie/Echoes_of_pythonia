class_name TerminalSaveV15Importer
extends RefCounted

const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const TerminalSaveV15MapperClass := preload("res://core/save/terminal_save_v15_mapper.gd")

const REPORT_VERSION := 1
const MAX_SOURCE_BYTES := 16 * 1024 * 1024

var _save_service: SaveGameServiceClass
var _explicit_source_paths: Array[String] = []


func _init(save_service: SaveGameServiceClass, explicit_source_paths: Array[String] = []) -> void:
	_save_service = save_service
	_explicit_source_paths.assign(explicit_source_paths)


func discover_sources() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for path: String in _candidate_paths():
		if not FileAccess.file_exists(path):
			continue
		var inspection := inspect_source(path)
		inspection["path"] = path
		inspection["source_slot"] = _slot_from_path(path)
		results.append(inspection)
	return results


func inspect_source(source_path: String) -> Dictionary:
	var read_result := _read_source(source_path)
	if not read_result.ok:
		return read_result
	var mapping := (
		TerminalSaveV15MapperClass
		. map_to_godot(
			read_result.payload,
			1,
			SaveGameServiceClass.FORMAT_ID,
			SaveGameServiceClass.SCHEMA_VERSION,
		)
	)
	if not mapping.ok:
		return mapping
	var validation := _save_service._deserialize_payload(mapping.payload, 1)
	if not validation.ok:
		return _failure("Nie można bezpiecznie odwzorować zapisu: %s" % validation.message)
	return {
		"ok": true,
		"message": "Terminalowy zapis v0.24.7 jest gotowy do importu.",
		"player_name": validation.session.player.display_name,
		"level": validation.session.player.level,
		"day": validation.session.day,
		"source_sha256": read_result.sha256,
		"source_size_bytes": read_result.size_bytes,
		"audit": mapping.audit,
	}


# Import always targets an empty Godot slot. The source is opened READ-only,
# hashed before and after the operation, and never renamed, removed, or written.
# Guard clauses keep every refusal explicit and ensure that no write happens
# before all source and destination preconditions pass.
# gdlint: disable=max-returns
func import_copy(source_path: String, target_slot: int) -> Dictionary:
	if _save_service == null:
		return _failure("Usługa zapisów Godota nie jest dostępna.")
	var destination_path := _save_service.slot_path(target_slot)
	if destination_path.is_empty():
		return _failure("Nieprawidłowy docelowy slot Godota.")
	if _save_service.save_exists(target_slot):
		return _failure("Docelowy slot Godota nie jest pusty. Import niczego nie nadpisuje.")
	var report_path := _report_path(destination_path)
	if FileAccess.file_exists(report_path):
		return _failure("Raport dla docelowego slotu już istnieje. Import niczego nie nadpisuje.")
	var source_absolute := _absolute_path(source_path)
	var destination_absolute := _absolute_path(destination_path)
	if source_absolute.to_lower() == destination_absolute.to_lower():
		return _failure("Źródło terminalowe i kopia docelowa wskazują ten sam plik.")

	var read_result := _read_source(source_path)
	if not read_result.ok:
		return read_result
	var mapping := (
		TerminalSaveV15MapperClass
		. map_to_godot(
			read_result.payload,
			target_slot,
			SaveGameServiceClass.FORMAT_ID,
			SaveGameServiceClass.SCHEMA_VERSION,
		)
	)
	if not mapping.ok:
		return mapping
	var validation := _save_service._deserialize_payload(mapping.payload, target_slot)
	if not validation.ok:
		return _failure("Nie można bezpiecznie odwzorować zapisu: %s" % validation.message)
	if FileAccess.get_sha256(source_path) != read_result.sha256:
		return _failure("Źródłowy zapis zmienił się podczas odczytu. Import został przerwany.")

	var save_result := _save_service.save_session(validation.session)
	if not save_result.ok:
		return _failure("Nie udało się utworzyć kopii Godota: %s" % save_result.message)
	var round_trip := _save_service.load_session(target_slot)
	if not round_trip.ok:
		_remove_created_copy(destination_path)
		return _failure("Kopia nie przeszła weryfikacji odczytu: %s" % round_trip.message)
	if FileAccess.get_sha256(source_path) != read_result.sha256:
		_remove_created_copy(destination_path)
		return _failure("Źródłowy zapis zmienił się podczas importu. Kopia została wycofana.")

	var report := {
		"report_version": REPORT_VERSION,
		"status": "completed",
		"created_at_unix": int(Time.get_unix_time_from_system()),
		"source":
		{
			"path": source_absolute,
			"format": "echoes_of_pythonia_terminal",
			"game_version": TerminalSaveV15MapperClass.TERMINAL_GAME_VERSION,
			"schema_version": TerminalSaveV15MapperClass.TERMINAL_SCHEMA_VERSION,
			"sha256_before": read_result.sha256,
			"sha256_after": FileAccess.get_sha256(source_path),
			"size_bytes": read_result.size_bytes,
			"modified": false,
		},
		"destination":
		{
			"path": destination_absolute,
			"format_id": SaveGameServiceClass.FORMAT_ID,
			"game_version": SaveGameServiceClass.GAME_VERSION,
			"schema_version": SaveGameServiceClass.SCHEMA_VERSION,
			"slot": target_slot,
			"sha256": FileAccess.get_sha256(destination_path),
		},
		"round_trip_verified": true,
		"audit": mapping.audit,
	}
	var report_result := _write_report(report_path, report)
	if not report_result.ok:
		_remove_created_copy(destination_path)
		return report_result
	if FileAccess.get_sha256(source_path) != read_result.sha256:
		_remove_created_copy(destination_path)
		DirAccess.remove_absolute(_absolute_path(report_path))
		return _failure("Źródłowy zapis zmienił się podczas zapisu raportu. Import wycofano.")
	return {
		"ok": true,
		"message":
		"Utworzono zweryfikowaną kopię w slocie %d. Oryginał pozostał bez zmian." % target_slot,
		"session": round_trip.session,
		"source_path": source_absolute,
		"destination_path": destination_absolute,
		"report_path": _absolute_path(report_path),
		"report": report,
	}


func _candidate_paths() -> Array[String]:
	if not _explicit_source_paths.is_empty():
		return _unique_paths(_explicit_source_paths)
	var directories: Array[String] = []
	var local_app_data := OS.get_environment("LOCALAPPDATA")
	if not local_app_data.is_empty():
		directories.append(local_app_data.path_join("EchoesOfPythonia").path_join("saves"))
	directories.append(ProjectSettings.globalize_path("res://../saves"))
	var paths: Array[String] = []
	for directory: String in directories:
		for slot in range(1, SaveGameServiceClass.SLOT_COUNT + 1):
			paths.append(directory.path_join("save_%d.json" % slot))
	return _unique_paths(paths)


func _read_source(source_path: String) -> Dictionary:
	if source_path.strip_edges().is_empty() or not FileAccess.file_exists(source_path):
		return _failure("Nie znaleziono terminalowego pliku zapisu.")
	var sha256_before := FileAccess.get_sha256(source_path)
	if sha256_before.is_empty():
		return _failure("Nie można obliczyć sumy kontrolnej terminalowego zapisu.")
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return _failure("Nie można otworzyć terminalowego zapisu wyłącznie do odczytu.")
	var size_bytes := file.get_length()
	if size_bytes <= 0 or size_bytes > MAX_SOURCE_BYTES:
		file.close()
		return _failure("Terminalowy zapis ma nieprawidłowy rozmiar.")
	var text := file.get_as_text()
	file.close()
	var sha256_after := FileAccess.get_sha256(source_path)
	if sha256_before != sha256_after:
		return _failure("Źródłowy zapis zmienił się podczas odczytu. Spróbuj ponownie.")
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK or not parser.data is Dictionary:
		return _failure("Terminalowy zapis jest uszkodzony albo nie jest plikiem JSON.")
	return {
		"ok": true,
		"payload": parser.data,
		"sha256": sha256_after,
		"size_bytes": size_bytes,
	}


func _write_report(report_path: String, report: Dictionary) -> Dictionary:
	var temporary_path := report_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _failure("Nie udało się utworzyć raportu migracji.")
	file.store_string(JSON.stringify(report, "\t", false))
	file.flush()
	file.close()
	var rename_error := DirAccess.rename_absolute(
		_absolute_path(temporary_path), _absolute_path(report_path)
	)
	if rename_error != OK:
		DirAccess.remove_absolute(_absolute_path(temporary_path))
		return _failure("Nie udało się zatwierdzić raportu migracji.")
	return {"ok": true}


func _remove_created_copy(destination_path: String) -> void:
	# This exact file did not exist when the operation began and was created by
	# this importer, so rollback cannot remove user-owned pre-existing data.
	if FileAccess.file_exists(destination_path):
		DirAccess.remove_absolute(_absolute_path(destination_path))


func _report_path(destination_path: String) -> String:
	return destination_path.trim_suffix(".json") + "_migration_report.json"


func _absolute_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path).simplify_path()
	return path.simplify_path()


func _slot_from_path(path: String) -> int:
	var file_name := path.get_file()
	for slot in range(1, SaveGameServiceClass.SLOT_COUNT + 1):
		if file_name == "save_%d.json" % slot:
			return slot
	return 0


func _unique_paths(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var known := {}
	for value: String in values:
		var normalized := _absolute_path(value).to_lower()
		if normalized.is_empty() or known.has(normalized):
			continue
		known[normalized] = true
		result.append(value)
	return result


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
