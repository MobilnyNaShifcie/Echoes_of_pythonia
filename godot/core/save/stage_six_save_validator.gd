class_name StageSixSaveValidator
extends RefCounted


static func validate(session, current_day: int) -> String:
	if session == null or session.party == null or session.rifts == null:
		return "Brak kompletnego stanu Stage 6."
	var rift = session.rifts.active_rift
	var expedition = session.rifts.expedition
	if rift == null:
		return "" if expedition == null else "Ekspedycja nie ma aktywnej Szczeliny."
	if rift.discovered_day > current_day:
		return "Aktywna Szczelina została odkryta w przyszłości."
	if expedition == null:
		return ""
	if expedition.started_day < rift.discovered_day or expedition.started_day > current_day:
		return "Data rozpoczęcia ekspedycji nie pasuje do czasu świata."

	var known_bound_ids := {}
	for companion in session.party.companions:
		known_bound_ids[companion.companion_id] = true
	for fallen in session.party.fallen:
		known_bound_ids[fallen.companion_id] = true
	for companion_id: String in expedition.party_companion_ids:
		if not known_bound_ids.has(companion_id):
			return "Skład Szczeliny wskazuje kompana spoza rosteru i Tablicy Poległych."
	return ""
