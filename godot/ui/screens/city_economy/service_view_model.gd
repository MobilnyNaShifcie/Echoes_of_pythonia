class_name CityEconomyServiceViewModel
extends RefCounted


static func mode_labels(mode: String) -> Dictionary:
	var labels := {
		"catalogue": "Ulepszenia",
		"transaction": "Zamówienie",
		"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ZATWIERDZIĆ",
	}
	if mode == "merchant_buy":
		labels = {
			"catalogue": "Towary Orena",
			"transaction": "Zakup",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY KUPIĆ",
		}
	elif mode.begins_with("merchant_sell"):
		labels = {
			"catalogue": "Twój plecak",
			"transaction": "Sprzedaż",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY SPRZEDAĆ",
		}
	elif mode == "blacksmith":
		labels = {
			"catalogue": "Wyposażenie do ulepszenia",
			"transaction": "Stół kowalski",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ULEPSZYĆ",
		}
	elif mode.begins_with("workshop"):
		labels = {
			"catalogue": "Receptury regionu",
			"transaction": "Stół rzemieślniczy",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY WYTWORZYĆ",
		}
	elif mode.begins_with("storage_deposit"):
		labels = {
			"catalogue": "Twój plecak",
			"transaction": "Skrytka w karczmie",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ODŁOŻYĆ",
		}
	elif mode.begins_with("storage_withdraw"):
		labels = {
			"catalogue": "Skrytka w karczmie",
			"transaction": "Twój plecak",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ODEBRAĆ",
		}
	elif mode == "inn_rest":
		labels = {
			"catalogue": "Usługi karczmy",
			"transaction": "Pokój gościnny",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ODPOCZĄĆ",
		}
	elif mode == "carry_upgrade":
		labels = {
			"catalogue": "Rozwój udźwigu",
			"transaction": "Pakowanie wyprawy",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ULEPSZYĆ",
		}
	return labels
