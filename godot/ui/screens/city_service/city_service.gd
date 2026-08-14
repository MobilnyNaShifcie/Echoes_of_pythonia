class_name CityServiceScreen
extends Control

signal back_requested
signal world_map_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const POTION_ID := "weak_healing_potion"
const POTION_PRICE := 25

const SERVICES := {
	"blacksmith":
	{
		"eyebrow": "DZIELNICA RZEMIEŚLNICZA",
		"title": "Kuźnia Garrana",
		"description":
		(
			"Żar paleniska odbija się w rzędach broni. Garran zajmuje się ulepszaniem "
			+ "ekwipunku i naprawą przedmiotów zdobytych podczas wypraw."
		),
		"offer":
		(
			"W tej wersji zachowujemy komplet danych broni, pancerzy i kamieni ulepszeń. "
			+ "Samo ulepszanie zostanie podłączone po migracji bazowej pętli walki."
		),
		"action": "",
	},
	"workshop":
	{
		"eyebrow": "DZIELNICA RZEMIEŚLNICZA",
		"title": "Warsztat Mireli",
		"description":
		(
			"Mirela skupuje materiały z potworów i tworzy z nich przedmioty użytkowe. "
			+ "Tutaj trafią receptury oraz system craftingu z wersji terminalowej."
		),
		"offer": "Zebrane skóry, kły, esencje i części wyposażenia są już przechowywane w plecaku.",
		"action": "",
	},
	"merchant":
	{
		"eyebrow": "RYNEK VARENHOLD",
		"title": "Kram Orena",
		"description": "Oren handluje podstawowym zaopatrzeniem dla nowych Poszukiwaczy.",
		"offer": "Słaba Mikstura Leczenia — przywraca 20 PŻ\nCena: 25 Gold",
		"action": "Kup miksturę",
	},
	"inn":
	{
		"eyebrow": "STARE MIASTO",
		"title": "Karczma Pod Pękniętym Dzwonem",
		"description":
		"Ciepłe łóżko pozwala odzyskać całe PŻ i Manę. Odpoczynek przesuwa czas o sześć godzin.",
		"offer": "Koszt noclegu zależy od poziomu bohatera.",
		"action": "Odpocznij",
	},
	"preparation":
	{
		"eyebrow": "PRZYGOTOWANIE WYPRAWY",
		"title": "Przed Bramą Zachodnią",
		"description":
		(
			"Sprawdź stan bohatera, aktywną misję i zapasy. Zmierzchowe Równiny są "
			+ "pierwszym dostępnym regionem."
		),
		"offer": "Region I  •  zalecany poziom 0–2  •  szansa spotkania 80%",
		"action": "Otwórz mapę wyprawy",
	},
}

var _session: GameSessionClass
var _service_id := "preparation"

@onready var eyebrow_label: Label = %EyebrowLabel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var offer_label: Label = %OfferLabel
@onready var wallet_label: Label = %WalletLabel
@onready var status_label: Label = %StatusLabel
@onready var action_button: Button = %ActionButton


static func display_name_for(service_id: String) -> String:
	return SERVICES.get(service_id, SERVICES.preparation).title


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	action_button.pressed.connect(_perform_action)
	_render()
	%BackButton.grab_focus()


func configure(session: GameSessionClass, service_id: String) -> void:
	_session = session
	_service_id = service_id if SERVICES.has(service_id) else "preparation"
	if is_node_ready():
		_render()


func _perform_action() -> void:
	match _service_id:
		"merchant":
			_buy_potion()
		"inn":
			_rest()
		"preparation":
			world_map_requested.emit()
	_render()


func _buy_potion() -> void:
	if _session.player.gold < POTION_PRICE:
		status_label.text = "Brakuje Golda. Potrzebujesz %d." % POTION_PRICE
		return
	_session.player.gold -= POTION_PRICE
	_session.player.inventory.add(POTION_ID)
	_session.last_activity = "Kupiono: Słaba Mikstura Leczenia."
	status_label.text = _session.last_activity


func _rest() -> void:
	var price := 25 + _session.player.level * 25
	if not _session.player.stats.needs_restoration():
		status_label.text = "Nie potrzebujesz teraz odpoczynku."
		return
	if _session.player.gold < price:
		status_label.text = "Nocleg kosztuje %d Gold — nie masz wystarczająco dużo." % price
		return
	_session.player.gold -= price
	_session.player.stats.restore_full()
	_session.advance_hours(6)
	_session.last_activity = "Odpoczynek zakończony. Odzyskano pełne PŻ i Manę."
	status_label.text = _session.last_activity


func _render() -> void:
	if _session == null:
		return
	var service: Dictionary = SERVICES[_service_id]
	eyebrow_label.text = service.eyebrow
	title_label.text = service.title
	description_label.text = service.description
	offer_label.text = service.offer
	wallet_label.text = (
		"%s  •  Poziom %d  •  PŻ %d/%d  •  Gold %d"
		% [
			_session.player.display_name,
			_session.player.level,
			_session.player.stats.current_hp,
			_session.player.stats.max_hp,
			_session.player.gold,
		]
	)
	action_button.visible = not service.action.is_empty()
	action_button.text = service.action
	if _service_id == "inn":
		action_button.text = "Odpocznij — %d Gold" % (25 + _session.player.level * 25)
