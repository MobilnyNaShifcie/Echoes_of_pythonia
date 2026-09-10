class_name CityServiceScreen
extends Control

signal back_requested
signal world_map_requested
signal state_changed

const GameSessionClass := preload("res://core/game/game_session.gd")
const InnServiceClass := preload("res://core/economy/inn_service.gd")

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
			"Garran ulepsza wyposażenie od +0 do +10. Wyższy Item Power wymaga "
			+ "materiałów z odpowiadającego mu regionu."
		),
		"action": "",
	},
	"workshop":
	{
		"eyebrow": "DZIELNICA RZEMIEŚLNICZA",
		"title": "Warsztat Mireli",
		"description":
		(
			"Mirela wykorzystuje materiały zdobyte w pięciu otwartych regionach. "
			+ "Receptury są podzielone według miejsca pochodzenia składników."
		),
		"offer": "Materiały, wyposażenie i wejściówki trafiają bezpośrednio do plecaka.",
		"action": "",
	},
	"merchant":
	{
		"eyebrow": "RYNEK VARENHOLD",
		"title": "Kram Orena",
		"description": "Oren handluje podstawowym zaopatrzeniem dla nowych Poszukiwaczy.",
		"offer": "Słaba Mikstura Leczenia — przywraca 20 PŻ\nCena: 25 złota",
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
		"inn":
			_rest()
		"preparation":
			world_map_requested.emit()
	_render()


func _rest() -> void:
	var result := InnServiceClass.rest(_session)
	status_label.text = result.message
	if result.ok:
		_session.last_activity = result.message
		state_changed.emit()


func _render() -> void:
	if _session == null:
		return
	var service: Dictionary = SERVICES[_service_id]
	eyebrow_label.text = service.eyebrow
	title_label.text = service.title
	description_label.text = service.description
	offer_label.text = service.offer
	wallet_label.text = (
		"%s  •  Poziom %d  •  PŻ %d/%d  •  Złoto %d"
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
		action_button.text = "Odpocznij — %d złota" % InnServiceClass.rest_cost(_session.player)
		if _session.black_market.unlocked:
			offer_label.text = (
				"Zapamiętana droga prowadzi do Czarnego Rynku. "
				+ "Nowa lokacja jest dostępna w planie miasta."
			)
