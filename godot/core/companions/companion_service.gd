class_name CompanionService
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")

const MAX_COMPANIONS := 4
const MAX_ACTIVE_COMPANIONS := 3


static func add_companion(
	party: PartyStateClass, companion: CompanionStateClass, current_day := 0
) -> Dictionary:
	if party == null or companion == null:
		return _failure("Nieprawidłowy stan drużyny albo kompana.")
	if party.companions.size() >= MAX_COMPANIONS:
		return _failure("Masz już maksymalną liczbę kompanów (%d)." % MAX_COMPANIONS)
	if companion.companion_id.is_empty() or party.companion_by_id(companion.companion_id) != null:
		return _failure("Kompan nie ma unikalnego identyfikatora.")
	if not CompanionCatalogClass.is_valid_class_for(companion.template_id, companion.class_code):
		return _failure("Klasa kompana nie pasuje do jego ręcznie napisanego szablonu.")
	if companion.active and party.active_companions(current_day).size() >= MAX_ACTIVE_COMPANIONS:
		return _failure(
			"Aktywna drużyna może mieć maksymalnie %d kompanów." % MAX_ACTIVE_COMPANIONS
		)
	if companion.active and not companion.can_join_party(current_day):
		return _failure("Ten kompan nie może teraz wyruszyć na wyprawę.")
	party.companions.append(companion)
	return {"ok": true, "message": "%s dołącza do drużyny." % companion.display_name}


static func set_active(
	party: PartyStateClass,
	companion_id: String,
	active: bool,
	current_day := 0,
	composition_locked := false
) -> Dictionary:
	if party == null:
		return _failure("Brak stanu drużyny.")
	if composition_locked:
		return _failure("Skład jest zablokowany na czas ekspedycji Szczeliny.")
	var companion := party.companion_by_id(companion_id)
	if companion == null:
		return _failure("Nie znaleziono kompana.")
	if companion.active == active:
		return {"ok": true, "message": "Skład nie wymaga zmiany."}
	if active:
		if not companion.can_join_party(current_day):
			return _failure("Ten kompan nie może teraz wyruszyć na wyprawę.")
		if party.active_companions(current_day).size() >= MAX_ACTIVE_COMPANIONS:
			return _failure(
				"Aktywna drużyna może mieć maksymalnie %d kompanów." % MAX_ACTIVE_COMPANIONS
			)
	companion.active = active
	return {
		"ok": true,
		"message":
		(
			("%s dołącza do aktywnego składu." if active else "%s pozostaje w Varenhold.")
			% companion.display_name
		),
	}


static func set_solo(party: PartyStateClass, composition_locked := false) -> Dictionary:
	if party == null:
		return _failure("Brak stanu drużyny.")
	if composition_locked:
		return _failure("Skład jest zablokowany na czas ekspedycji Szczeliny.")
	var changed := 0
	for companion: CompanionStateClass in party.companions:
		if companion.active:
			companion.active = false
			changed += 1
	return {
		"ok": true,
		"message": "Ustawiono wyprawę SOLO.",
		"changed": changed,
	}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
