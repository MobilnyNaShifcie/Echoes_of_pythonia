class_name CompanionCatalog
extends RefCounted

const CompanionDefinitionClass := preload("res://core/companions/companion_definition.gd")

const ORDER := [
	"elyra",
	"kael",
	"nessa",
	"mira",
	"dorian",
	"sylvi",
	"orenna",
	"veyn",
	"talia",
	"cassian",
	"lumi",
	"brann",
]

static var _definitions := {
	"elyra":
	_definition(
		"elyra",
		"Elyra",
		"Akademia Arkanów w stolicy",
		"precyzyjna, spokojna, suchy humor",
		["mage"],
		["rational", "scholar", "reserved"],
		58,
		"D"
	),
	"kael":
	_definition(
		"kael",
		"Kael",
		"pograniczne garnizony",
		"bezpośredni, ironiczny, lojalny",
		["warrior"],
		["practical", "protective", "dry"],
		64,
		"E"
	),
	"nessa":
	_definition(
		"nessa",
		"Nessa",
		"Lodowe Wybrzeże",
		"cicha, złośliwa, obserwuje więcej niż mówi",
		["hunter"],
		["quiet", "observant", "competitive"],
		55,
		"D"
	),
	"mira":
	_definition(
		"mira",
		"Mira",
		"wędrowne trupy południa",
		"chaotyczna, pogodna, czasem nagle poważna",
		["pierrot"],
		["chaotic", "warm", "gambler"],
		52,
		"C"
	),
	"dorian":
	_definition(
		"dorian",
		"Dorian",
		"Varenhold",
		"uprzejmy, ambitny, lubi przesadzać",
		["warrior", "hunter"],
		["ambitious", "social", "dramatic"],
		61,
		"E"
	),
	"sylvi":
	_definition(
		"sylvi",
		"Sylvi",
		"mokradła Głuchej Wody",
		"cierpliwa, pragmatyczna, makabryczny humor",
		["mage", "hunter"],
		["practical", "morbid", "calm"],
		60,
		"D"
	),
	"orenna":
	_definition(
		"orenna",
		"Orenna",
		"górskie klasztory",
		"surowa, opanowana, zaskakująco opiekuńcza",
		["warrior", "mage"],
		["disciplined", "protective", "spiritual"],
		50,
		"C"
	),
	"veyn":
	_definition(
		"veyn",
		"Veyn",
		"Czarny Bór",
		"uprzejmy, chłodny, prowokuje pytaniami",
		["hunter", "pierrot"],
		["clever", "secretive", "provocative"],
		47,
		"C"
	),
	"talia":
	_definition(
		"talia",
		"Talia",
		"Popielne Pogranicze",
		"energiczna, szczera, źle znosi bezczynność",
		["warrior", "hunter"],
		["bold", "impatient", "loyal"],
		66,
		"E"
	),
	"cassian":
	_definition(
		"cassian",
		"Cassian",
		"stolica",
		"elegancki, sceptyczny, bardzo kompetentny",
		["mage"],
		["arrogant", "competent", "skeptical"],
		42,
		"B"
	),
	"lumi":
	_definition(
		"lumi",
		"Lumi",
		"nieznane",
		"łagodna, dziwaczna, mówi rzeczy zbyt trafne",
		["pierrot", "mage"],
		["mysterious", "gentle", "odd"],
		44,
		"B"
	),
	"brann":
	_definition(
		"brann",
		"Brann",
		"porty Czarnego Morza",
		"gadatliwy, pogodny, skrywa lęk za żartami",
		["warrior", "hunter"],
		["jovial", "fearful", "loyal"],
		68,
		"E"
	),
}


static func get_definition(template_id: String) -> CompanionDefinitionClass:
	return _definitions.get(template_id)


static func get_all() -> Array[CompanionDefinitionClass]:
	var definitions: Array[CompanionDefinitionClass] = []
	for template_id: String in ORDER:
		definitions.append(_definitions[template_id])
	return definitions


static func is_valid_class_for(template_id: String, class_code: String) -> bool:
	var definition := get_definition(template_id)
	return definition != null and definition.allows_class(class_code)


static func _definition(
	template_id: String,
	display_name: String,
	origin: String,
	voice: String,
	allowed_classes: Array[String],
	personality_tags: Array[String],
	base_willingness: int,
	minimum_guild_rank: String
) -> CompanionDefinitionClass:
	return (
		CompanionDefinitionClass
		. new(
			template_id,
			display_name,
			origin,
			voice,
			allowed_classes,
			personality_tags,
			base_willingness,
			minimum_guild_rank,
		)
	)
