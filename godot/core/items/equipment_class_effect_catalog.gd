class_name EquipmentClassEffectCatalog
extends RefCounted

# Descriptions intentionally preserve the terminal version's complete prose.
# gdlint: disable=max-line-length
const EFFECTS := {
	"warrior_retribution":
	{
		"display_name": "Odwet",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description":
		"Po użyciu Obrony następny podstawowy atak otrzymuje dodatkową siłę równą 50% twojego DEF.",
	},
	"hunter_predatory_instinct":
	{
		"display_name": "Drapieżny Odruch",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description":
		"Po udanym uniku następny podstawowy atak zadaje +20% obrażeń i otrzymuje +10 p.p. szansy na trafienie krytyczne.",
	},
	"mage_mana_tide":
	{
		"display_name": "Przypływ Many",
		"class_code": "mage",
		"class_name": "Mag",
		"description":
		"Za każde 20 Many wydane na umiejętności odzyskujesz 5 Many. Postęp liczy się w obrębie jednej walki.",
	},
	"rift_bastion_memory":
	{
		"display_name": "Pamięć Bastionu",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description":
		"Udany Blok zwiększa siłę następnego podstawowego ataku o dodatkowe 25% DEF.",
	},
	"last_guard":
	{
		"display_name": "Ostatnia Straż",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description":
		"Poniżej 35% HP Wojownik otrzymuje +20% efektywnego DEF przeciw zwykłym atakom.",
	},
	"oathbreaker_bleed":
	{
		"display_name": "Złamana Przysięga",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description": "Krwawy Zamach wydłuża swoje krwawienie o 1 turę.",
	},
	"warden_afterguard":
	{
		"display_name": "Po Straży",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description":
		"Po użyciu Obrony następny otrzymany zwykły cios jest dodatkowo osłabiony o 15%.",
	},
	"third_echo":
	{
		"display_name": "Trzecie Echo",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description": "Trzecia technika kończąca sekwencję Salwy zadaje +15% obrażeń.",
	},
	"riftglass_echo":
	{
		"display_name": "Szkło Echa",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description": "Widmowe Echo wraca z 20% większą mocą.",
	},
	"silent_volley":
	{
		"display_name": "Bezgłośna Salwa",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description":
		"Po ukończeniu sekwencji trzech różnych technik Łowca zyskuje +15 p.p. Uniku na następny atak.",
	},
	"afterimage_mana":
	{
		"display_name": "Powidok",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description": "Widmowe dodatkowe trafienia mają 30% szansy zwrócić 2 Many.",
	},
	"split_weave":
	{
		"display_name": "Rozszczepiony Splot",
		"class_code": "mage",
		"class_name": "Mag",
		"description": "Drugie zaklęcie Podwójnego Splotu działa z dodatkową mocą +10 p.p.",
	},
	"twin_star":
	{
		"display_name": "Dwie Gwiazdy",
		"class_code": "mage",
		"class_name": "Mag",
		"description":
		"Dwa różne żywioły użyte w Podwójnym Splocie wzmacniają drugie zaklęcie o 15%.",
	},
	"empty_mana_power":
	{
		"display_name": "Ostatnia Iskra",
		"class_code": "mage",
		"class_name": "Mag",
		"description": "Poniżej 25% maksymalnej Many zaklęcia ofensywne zadają +12% obrażeń.",
	},
	"storm_archive_refund":
	{
		"display_name": "Margines Archiwum",
		"class_code": "mage",
		"class_name": "Mag",
		"description": "Każde zaklęcie ma 20% szansy zwrócić 3 Many po rozpatrzeniu.",
	},
	"two_lies":
	{
		"display_name": "Dwa Kłamstwa",
		"class_code": "pierrot",
		"class_name": "Pierrot",
		"description": "Każdy dublet Kości Losu zapewnia +1 dodatkowy Żeton Losu.",
	},
	"ace_less_deck":
	{
		"display_name": "Bez Asa",
		"class_code": "pierrot",
		"class_name": "Pierrot",
		"description":
		"Katastrofalne wyniki 3k6 są łagodniejsze, ale Jackpot zadaje 10% mniej obrażeń.",
	},
	"seven_chances":
	{
		"display_name": "Siedem Przypadków",
		"class_code": "pierrot",
		"class_name": "Pierrot",
		"description": "Podstawowy atak Pierrota losuje jeden z siedmiu dodatkowych efektów broni.",
	},
	"crooked_smile":
	{
		"display_name": "Krzywy Uśmiech",
		"class_code": "pierrot",
		"class_name": "Pierrot",
		"description": "Po udanym odbiciu Krzywym Zwierciadłem Pierrot odzyskuje 1 Żeton Losu.",
	},
}
# gdlint: enable=max-line-length


static func get_definition(effect_id: String) -> Dictionary:
	return EFFECTS.get(effect_id, {})


static func is_active(player, effect_id: String) -> bool:
	var effect := get_definition(effect_id)
	if effect.is_empty() or player == null or player.character_class_code != effect.class_code:
		return false
	for item in player.equipment.slots.values():
		if item != null and item.definition.class_effect_id == effect_id:
			return true
	return false
