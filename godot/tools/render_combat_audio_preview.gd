extends SceneTree
## Offline Movie Maker mix using the production audio helper. No game/session saves.
const Audio := preload("res://ui/presentation/combat_audio_feedback.gd")
const CUES := ["hit", "critical", "block", "dodge", "victory", "muted"]
var _audio: Audio
var _label: Label
var _elapsed := 0.0
var _next := 0


func _init() -> void:
	call_deferred("_setup")


func _setup() -> void:
	root.content_scale_size = Vector2i(640, 360)
	var host := Control.new()
	root.add_child(host)
	var button := Button.new()
	button.name = "AudioToggleButton"
	host.add_child(button)
	button.owner = host
	button.unique_name_in_owner = true
	button.toggle_mode = true
	button.position = Vector2(230, 50)
	button.size = Vector2(180, 40)
	_label = Label.new()
	host.add_child(_label)
	_label.position = Vector2(0, 140)
	_label.size = Vector2(640, 120)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.text = "Próbki dźwięków walki\nPoziom głośności z gry"
	_audio = Audio.new()
	_audio.preferences_path = ""
	host.add_child(_audio)
	_audio.configure(host)


func _process(delta: float) -> bool:
	if _audio == null:
		return false
	_elapsed += delta
	if _next < CUES.size() and _elapsed >= 1.0 + _next * 3.0:
		var cue: String = CUES[_next]
		_audio.begin_turn()
		_label.text = cue + "\nCC0 · Kenney"
		match cue:
			"victory":
				_audio.play_result("victory")
			"muted":
				_audio.set_muted(true)
				_audio.play_event({"kind": "damage", "amount": 1, "critical": true})
			"block", "dodge":
				_audio.play_event({"kind": "feedback", "tone": cue})
			_:
				_audio.play_event({"kind": "damage", "amount": 1, "critical": cue == "critical"})
		print("COMBAT_AUDIO_SAMPLE ", cue, " ", _elapsed)
		_next += 1
	if _elapsed >= 19.0:
		print("COMBAT AUDIO PREVIEW COMPLETE — last three seconds must be silent")
		quit()
	return false
