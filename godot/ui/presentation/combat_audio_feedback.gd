extends Node
## Presentation-only audio. No timers, gameplay RNG, save-game data or domain callbacks.
signal cue_played(cue: String)

const Style := preload("res://ui/screens/combat/combat_visual_style.gd")
const STREAMS := {
	"hit": preload("res://assets/audio/combat/hit.ogg"),
	"critical": preload("res://assets/audio/combat/critical.ogg"),
	"block": preload("res://assets/audio/combat/block.ogg"),
	"dodge": preload("res://assets/audio/combat/dodge.ogg"),
	"victory": preload("res://assets/audio/combat/victory.ogg"),
}
const GAIN_DB := {"hit": -2.0, "critical": 0.0, "block": -3.0, "dodge": -4.0, "victory": -4.0}
const PRIORITY := {"": 0, "hit": 1, "dodge": 2, "block": 3, "critical": 4}
const BASE_DB := -12.0
const VOICE_LIMIT := 2
var preferences_path := "user://combat_audio.cfg"
var muted := false
var _button: Button
var _voices: Array[AudioStreamPlayer] = []
var _cursor := 0
var _result_played := false


func configure(screen: Control) -> void:
	_button = screen.get_node("%AudioToggleButton")
	Style.button(_button)
	_button.add_theme_font_size_override("font_size", 17)
	_button.toggled.connect(func(enabled: bool) -> void: set_muted(not enabled, true))
	for index in VOICE_LIMIT:
		var voice := AudioStreamPlayer.new()
		voice.name = "CombatVoice%d" % index
		voice.max_polyphony = 1
		add_child(voice)
		_voices.append(voice)
	load_preferences()


func load_preferences() -> void:
	var config := ConfigFile.new()
	var stored: Variant = false
	if not preferences_path.is_empty() and config.load(preferences_path) == OK:
		stored = config.get_value("combat", "muted", false)
	set_muted(stored if stored is bool else false)


func set_muted(value: bool, persist := false) -> void:
	muted = value
	if muted:
		stop()
	if is_instance_valid(_button):
		_button.set_pressed_no_signal(not muted)
		_button.text = "Dźwięk: wył." if muted else "Dźwięk: wł."
		_button.tooltip_text = "Włącz dźwięki walki." if muted else "Wycisz dźwięki walki."
	if persist and not preferences_path.is_empty():
		var config := ConfigFile.new()
		config.set_value("combat", "muted", muted)
		if config.save(preferences_path) != OK:
			push_warning("Nie udało się zapisać ustawienia dźwięku walki.")


func begin_turn() -> void:
	# Reduced motion can resolve another turn immediately; never accumulate its sounds.
	stop()
	_result_played = false


func play_event(event: Dictionary) -> void:
	_play(cue_for(event))


func play_summary(events: Array[Dictionary]) -> void:
	# Instant presentation gets one meaningful cue, not a burst of all turn events.
	var selected := ""
	for event: Dictionary in events:
		var candidate := cue_for(event)
		if int(PRIORITY.get(candidate, 0)) > int(PRIORITY[selected]):
			selected = candidate
	_play(selected)


func play_result(result_code: String) -> void:
	if _result_played:
		return
	_result_played = true
	stop()
	if result_code == "victory":
		_play("victory")


func stop() -> void:
	for voice: AudioStreamPlayer in _voices:
		voice.stop()


func _play(cue: String) -> void:
	if muted or not STREAMS.has(cue) or _voices.is_empty():
		return
	var voice := _voices[_cursor]
	_cursor = (_cursor + 1) % VOICE_LIMIT
	voice.stop()
	voice.stream = STREAMS[cue]
	voice.volume_db = BASE_DB + float(GAIN_DB[cue])
	voice.play()
	cue_played.emit(cue)


static func cue_for(event: Dictionary) -> String:
	if str(event.get("kind", "")) == "feedback":
		var tone := str(event.get("tone", ""))
		return tone if tone in ["dodge", "block"] else ""
	if str(event.get("kind", "")) != "damage":
		return ""
	if int(event.get("amount", 0)) <= 0 or not bool(event.get("direct_attack", true)):
		return ""
	return "critical" if bool(event.get("critical", false)) else "hit"
