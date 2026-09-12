extends SceneTree
## Stateful UI integration: buttons/signals, real services, isolated saves.
const APP := preload("res://scenes/app/app.tscn")
const NEW_GAME := preload("res://core/game/new_game_service.gd")
const SAVES := preload("res://core/save/save_game_service.gd")
const EQUIPMENT := preload("res://ui/screens/equipment/equipment.gd")
var _output := ""
var _steps: Array[Dictionary] = []
var _ok := true
var _app: Node


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		quit(1)
		return
	var request: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not request is Dictionary or not str(request.get("output", "")).is_absolute_path():
		quit(1)
		return
	_output = request.output
	DirAccess.make_dir_recursive_absolute(_output)
	seed(741)
	_app = APP.instantiate()
	_app._save_service = SAVES.new(_output.path_join("fixture_saves"))
	root.add_child(_app)
	var session = NEW_GAME.new().create_session("Autopilot Journey", 1, null, "female")
	session.player.gold = 500
	session.player.level = 1
	session.prologue_completed = true
	_app._current_session = session
	var equipped: Dictionary = await _purchase_and_equip(session)
	if equipped.is_empty():
		await _finish()
		return
	var purchased_id: String = equipped.instance_id
	var slot: String = equipped.slot
	_app._show_combat("wolf", "expedition")
	await _settle()
	var combat = _app.screen_host.get_child(0)
	combat.set_reduced_motion(true)
	var old_round: int = combat._round_number
	combat.attack_button.pressed.emit()
	await _settle()
	if not _record(
		"combat", combat._round_number > old_round, "Przycisk ataku wykonał turę silnika walki"
	):
		await _finish()
		return
	var expected_gold: int = session.player.gold
	var expected_hp: int = session.player.stats.current_hp
	_app._show_main_menu()
	await _settle()
	_app._save_current_session()
	var saved: Dictionary = _app._save_service.load_session(1)
	if not _record("save", bool(saved.ok), "Zapis przez obsługę aplikacji do oddzielnego katalogu"):
		await _finish()
		return
	session.player.gold = 1
	_app._show_load_game()
	await _settle()
	var load_screen = _app.screen_host.get_child(0)
	load_screen.load_button.pressed.emit()
	await _settle()
	var loaded = _app._current_session
	_record(
		"reload",
		(
			loaded != session
			and loaded.player.gold == expected_gold
			and loaded.player.stats.current_hp == expected_hp
			and loaded.player.equipment.get_item(slot) != null
			and loaded.player.equipment.get_item(slot).instance_id == purchased_id
		),
		"Wczytanie przez przycisk odtworzyło złoto, PŻ i identyfikator wyposażenia"
	)
	await _finish()


func _purchase_and_equip(session) -> Dictionary:
	_app._show_city_service("merchant")
	await _settle()
	var merchant = _app.screen_host.get_child(0)
	merchant.open_service_button.pressed.emit()
	var index := -1
	for i in merchant._entries.size():
		if str(merchant._entries[i].get("item_id", "")) == "weak_leather":
			index = i
	if not _record("purchase", index >= 0, "Oferta Orena zawiera Słabą Skórę"):
		return {}
	# Replace the preliminary observation with the complete transaction proof.
	_steps.pop_back()
	merchant.item_list.select(index)
	merchant.item_list.item_selected.emit(index)
	merchant.merchant_quantity_box.value = 2
	merchant.merchant_action_button.pressed.emit()
	await _settle()
	if not _record(
		"purchase",
		session.player.gold == 440 and session.player.inventory.count("weak_leather") == 2,
		"Zakup przez przycisk: złoto 500 → 440, dwie skóry w plecaku"
	):
		return {}
	_app._show_city_service("workshop")
	await _settle()
	var workshop = _app.screen_host.get_child(0)
	workshop.open_service_button.pressed.emit()
	workshop.action_button.pressed.emit()
	await _settle()
	if session.player.inventory.equipment_items.size() != 1:
		_record("equip", false, "Warsztat nie wykonał kaptura z zakupionych materiałów")
		return {}
	var purchased_id: String = session.player.inventory.equipment_items[0].instance_id
	var slot: String = session.player.inventory.equipment_items[0].definition.slot
	_app._show_equipment()
	await _settle()
	var equipment = _find_script(_app.screen_host, EQUIPMENT)
	if equipment == null:
		_record("equip", false, "Ekran ekwipunku nie został otwarty")
		return {}
	equipment.inventory_list.select(0)
	equipment.inventory_list.item_selected.emit(0)
	equipment.equip_button.pressed.emit()
	await _settle()
	if not _record(
		"equip",
		(
			session.player.equipment.get_item(slot) != null
			and session.player.equipment.get_item(slot).instance_id == purchased_id
		),
		"Założenie kaptura przez ekran ekwipunku: " + equipment.feedback_label.text
	):
		return {}
	return {"instance_id": purchased_id, "slot": slot}


func _find_script(node: Node, script: Script) -> Node:
	if node.get_script() == script:
		return node
	for child in node.get_children():
		var found := _find_script(child, script)
		if found != null:
			return found
	return null


func _record(id: String, passed: bool, detail: String) -> bool:
	_steps.append({"id": id, "ok": passed, "detail": detail})
	_ok = _ok and passed
	print("JOURNEY ", id, ": ", "PASS" if passed else "FAIL", " — ", detail)
	return passed


func _settle() -> void:
	for frame in 20:
		await process_frame


func _finish() -> void:
	var expected := ["purchase", "equip", "combat", "save", "reload"]
	var verified: Array[String] = []
	for step in _steps:
		if step.ok:
			verified.append(step.id)
	_ok = _ok and verified == expected
	_app.queue_free()
	await _settle()
	var file := FileAccess.open(_output.path_join("journey.json"), FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"ok": _ok,
				"steps": _steps,
				"interaction": "UI signals and real application services",
				"save_root": _output.path_join("fixture_saves")
			},
			"\t"
		)
	)
	file.close()
	quit(0 if _ok else 1)
