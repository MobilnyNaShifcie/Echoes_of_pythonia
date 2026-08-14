class_name PrologueScreen
extends Control

signal tutorial_battle_requested
signal prologue_completed

const GameSessionClass := preload("res://core/game/game_session.gd")
const SCENES := [
	{
		"eyebrow": "PROLOG — DROGA DO VARENHOLD",
		"title": "Królestwo zamyka granice",
		"body":
		(
			"Królestwo od lat zamyka swoje granice coraz szczelniej.\n\n"
			+ "Na północy zamarzają porty. Na południu popiół zasypuje drogi. "
			+ "Z lasów znikają całe patrole, a stare ruiny znów pojawiają się w raportach Gildii.\n\n"
			+ "Mimo to do Varenhold każdego dnia przybywają nowi ludzie. Jedni szukają Golda. "
			+ "Inni sławy. Niektórzy po prostu nie mają już dokąd wrócić.\n\nTy jesteś jednym z nich."
		),
	},
	{
		"eyebrow": "DROGA DO VARENHOLD",
		"title": "Rozbity królewski wóz",
		"body":
		(
			"Pod wieczór karawana zatrzymuje się przy rozbitym królewskim wozie. "
			+ "Strażnicy nie żyją. Skrzynie z Goldem są nietknięte.\n\n"
			+ "Brakuje tylko jednej, niewielkiej skrzyni.\n\n"
			+ "Woźnica spogląda na ślady prowadzące w pole.\n"
			+ "— Jeśli zostawili złoto, to nie pieniędzy szukali.\n\n"
			+ "Kilkaset kroków dalej konie wpadają w panikę. Z ciemności wychodzi coś, "
			+ "co jeszcze rano mogło wyglądać jak zwykły strach na wróble."
		),
	},
	{
		"eyebrow": "PO WALCE",
		"title": "Nadpalony dokument",
		"body":
		(
			"W słomie znajdujesz nadpalony skrawek pergaminu. Na papierze pozostał fragment "
			+ "królewskiej pieczęci, ale większość tekstu spalono celowo. "
			+ "Zabierasz znalezisko jako dowód.\n\n"
			+ "Nie wygląda na przypadkową rzecz, którą wiatr przywiał na pole."
		),
	},
	{
		"eyebrow": "BRAMA VARENHOLD",
		"title": "Królewski zakaz",
		"body":
		(
			"Przed bramą strażnicy przeszukują karawanę. Jeden z podróżnych zostaje zatrzymany, "
			+ "gdy spod jego płaszcza wypada stara księga.\n\n— Handel wiedzą bojową jest zakazany "
			+ "na mocy królewskiego edyktu.\n— To tylko stary manuskrypt!\n"
			+ "— W takim razie nie będziesz miał nic przeciwko, jeśli go spalimy.\n\n"
			+ "Nikt w kolejce nie protestuje. Ty zapamiętujesz płomień."
		),
	},
	{
		"eyebrow": "VARENHOLD",
		"title": "F — Nowicjusz",
		"body": "",
	},
]

var _session: GameSessionClass

@onready var eyebrow_label: Label = %EyebrowLabel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var progress_label: Label = %ProgressLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_advance)
	_render()
	continue_button.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _advance() -> void:
	if _session == null:
		return
	if _session.prologue_stage == 1:
		tutorial_battle_requested.emit()
		return
	if _session.prologue_stage >= 4:
		_session.prologue_stage = 5
		_session.prologue_completed = true
		_session.last_activity = "Prolog ukończony. Otrzymano rangę Gildii F — Nowicjusz."
		prologue_completed.emit()
		return
	_session.prologue_stage += 1
	_render()


func _render() -> void:
	if _session == null:
		return
	var stage := mini(_session.prologue_stage, 4)
	var scene: Dictionary = SCENES[stage]
	eyebrow_label.text = scene.eyebrow
	title_label.text = scene.title
	body_label.text = scene.body
	if stage == 4:
		body_label.text = _city_scene_text()
	continue_button.text = "Rozpocznij pierwszą walkę" if stage == 1 else "Dalej"
	if stage == 4:
		continue_button.text = "Wejdź do Varenhold"
	progress_label.text = "SCENA %d / 5" % (stage + 1)


func _city_scene_text() -> String:
	return (
		"Miasto zbudowano bardziej z potrzeby niż z piękna. Kupcy przekrzykują najemników, "
		+ "kowalskie młoty słychać nawet po zmroku, a na tablicach Gildii wiszą zlecenia z miejsc, "
		+ "do których rozsądny człowiek nigdy by nie poszedł.\n\nDla większości ludzi to koniec drogi. "
		+ (
			"Dla Poszukiwaczy — dopiero początek.\n\nW Gildii urzędnik zapisuje imię: %s.\n"
			% _session.player.display_name
		)
		+ "— Doświadczenie?\nCisza wystarcza za odpowiedź. Urzędnik przesuwa po blacie drewniany znak "
		+ "z literą F.\n\n— W takim razie zaczynasz tam, gdzie wszyscy.\n\n"
		+ "OTRZYMANO RANGĘ GILDII: F — Nowicjusz\n"
		+ "Nowe zadanie czeka na tablicy Gildii: „Ci, którzy nie wrócili”."
	)
