class_name AdventureLog
extends RefCounted

const MAX_ENTRIES := 50
const DEFAULT_VISIBLE_ENTRIES := 30

var entries: Array[String] = []


func add(day: int, hour: int, message: String) -> void:
	var normalized := message.strip_edges()
	if normalized.is_empty():
		return
	entries.append("Dzień %d, %02d:00 — %s" % [maxi(1, day), clampi(hour, 0, 23), normalized])
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(entries.size() - MAX_ENTRIES)


func recent(limit := DEFAULT_VISIBLE_ENTRIES) -> Array[String]:
	if limit <= 0:
		return []
	var start := maxi(0, entries.size() - limit)
	return entries.slice(start)


func replace_entries(saved_entries: Array[String]) -> void:
	entries.assign(saved_entries.slice(maxi(0, saved_entries.size() - MAX_ENTRIES)))
