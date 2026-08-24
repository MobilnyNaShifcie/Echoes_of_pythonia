class_name TwilightPlains
extends RefCounted

const LOCATION_ID := "twilight_plains"
const DISPLAY_NAME := "Zmierzchowe Równiny"
const DESCRIPTION := (
	"Rozległe pola za granicą bezpiecznych szlaków. Za dnia krążą tu dzikie "
	+ "zwierzęta i rabusie. Po zmroku między wysoką trawą zaczynają poruszać "
	+ "się rzeczy, które nie powinny już żyć."
)
const ENCOUNTER_CHANCE := 0.8
const DAY_ENCOUNTERS := {
	"wild_dog": 25,
	"slime": 20,
	"wolf": 20,
	"boar": 15,
	"bandit": 10,
	"cursed_scarecrow": 10,
}
const NIGHT_ENCOUNTERS := {
	"plains_spirit": 25,
	"night_guard": 25,
	"hunter": 20,
	"wolf": 10,
	"boar": 10,
	"bandit": 5,
	"nature_guardian": 5,
}
const QUIET_EVENTS := [
	"Wiatr ugina wysoką trawę. Tym razem nic cię nie atakuje.",
	"Znajdujesz stare ślady butów, ale prowadzą donikąd.",
	"W oddali słyszysz wycie. Dźwięk szybko milknie.",
	"Przez chwilę masz wrażenie, że ktoś obserwuje cię z pola.",
]


static func encounters_for(period_code: String) -> Dictionary:
	return DAY_ENCOUNTERS if period_code == "day" else NIGHT_ENCOUNTERS
