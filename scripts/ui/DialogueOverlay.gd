extends CanvasLayer

@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var portrait_container: PanelContainer = $DialogueBox/MarginContainer/HBoxContainer/PortraitContainer
@onready var portrait: TextureRect = $DialogueBox/MarginContainer/HBoxContainer/PortraitContainer/Portrait
@onready var speaker_label: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/HeaderContainer/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel
@onready var advance_indicator: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/AdvanceIndicator
@onready var skip_button: Button = $DialogueBox/MarginContainer/SkipButton
@onready var typewriter_audio: AudioStreamPlayer = $TypewriterSoundPlayer

var _typewriter_tween: Tween = null
var _indicator_tween: Tween = null
var typewriter_audio_fade_tween: Tween = null
var _is_typewriter_playing: bool = false
var _regex_sz: RegEx = null
var _regex_sh: RegEx = null
var _last_speaker: String = ""

## Seconds per character for the typewriter effect.
const TYPEWRITER_SPEED: float = 0.03

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_box.hide()
	advance_indicator.hide()
	
	_regex_sz = RegEx.new()
	_regex_sz.compile("\\[sz=(.*?)\\](.*?)\\[\\/sz\\]")
	
	_regex_sh = RegEx.new()
	_regex_sh.compile("\\[sh(.*?)\\](.*?)\\[\\/sh\\]")

## Displays a single dialogue line with optional portrait.
## Sets the speaker label, loads the portrait texture (or hides the container),
## and starts the typewriter animation on the RichTextLabel.
func display_line(speaker: String, text: String, portrait_path: String = "") -> void:
	# Set speaker name
	speaker_label.text = speaker

	# Set portrait
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var tex = load(portrait_path)
		portrait.texture = tex
		portrait_container.show()
	else:
		portrait.texture = null
		portrait_container.hide()

	# Preprocess custom BBCode tags
	var processed_text = text
	if _regex_sz and _regex_sz.is_valid():
		processed_text = _regex_sz.sub(processed_text, "[font_size=$1]$2[/font_size]", true)
	if _regex_sh and _regex_sh.is_valid():
		processed_text = _regex_sh.sub(processed_text, "[shake$1]$2[/shake]", true)

	# Set text with typewriter effect
	dialogue_label.text = processed_text
	dialogue_label.visible_characters = 0
	advance_indicator.hide()
	_stop_indicator_animation()

	# Glitch/flicker effect before text, only if speaker changed
	if speaker != _last_speaker:
		var glitch_tween = create_tween()
		dialogue_box.modulate.a = 0.5
		glitch_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_BOUNCE)
		_last_speaker = speaker

	_is_typewriter_playing = true

	# Kill any previous typewriter tween
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var total_chars = dialogue_label.get_total_character_count()
	var duration = total_chars * TYPEWRITER_SPEED
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(dialogue_label, "visible_characters", total_chars, duration)
	_typewriter_tween.finished.connect(_on_typewriter_finished)
	
	_start_typewriter_sound()

## Instantly completes the typewriter animation, showing all text.
func complete_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	dialogue_label.visible_characters = -1
	_is_typewriter_playing = false
	_stop_typewriter_sound()
	advance_indicator.show()
	_start_indicator_animation()

## Returns true if the typewriter animation is currently in progress.
func is_typewriter_playing() -> bool:
	return _is_typewriter_playing

## Fades in the dialogue box with a holographic expansion animation.
func show_box() -> void:
	_last_speaker = ""
	dialogue_box.modulate.a = 0.0
	dialogue_box.pivot_offset = dialogue_box.size / 2.0
	dialogue_box.scale = Vector2(1.0, 0.0)
	dialogue_box.show()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dialogue_box, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Fades out and hides the dialogue box with a power-down animation.
func hide_box() -> void:
	_last_speaker = ""
	dialogue_box.pivot_offset = dialogue_box.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dialogue_box, "scale", Vector2(1.0, 0.0), 0.15).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func(): dialogue_box.hide())

## Returns true if the skip button is hovered by the mouse.
func is_skip_button_hovered() -> bool:
	if not skip_button.is_visible_in_tree():
		return false
	var rect = skip_button.get_global_rect()
	var mouse_pos = skip_button.get_global_mouse_position()
	return rect.has_point(mouse_pos)

func _on_typewriter_finished() -> void:
	_is_typewriter_playing = false
	_stop_typewriter_sound()
	advance_indicator.show()
	_start_indicator_animation()

func _start_indicator_animation() -> void:
	_stop_indicator_animation()
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(advance_indicator, "modulate:a", 0.3, 0.5)
	_indicator_tween.tween_property(advance_indicator, "modulate:a", 1.0, 0.5)

func _stop_indicator_animation() -> void:
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	advance_indicator.modulate.a = 1.0

func _start_typewriter_sound() -> void:
	if typewriter_audio_fade_tween and typewriter_audio_fade_tween.is_valid():
		typewriter_audio_fade_tween.kill()
	typewriter_audio.volume_db = 0.0
	if not typewriter_audio.playing:
		typewriter_audio.play()

func _stop_typewriter_sound() -> void:
	if typewriter_audio.playing:
		if typewriter_audio_fade_tween and typewriter_audio_fade_tween.is_valid():
			typewriter_audio_fade_tween.kill()
		typewriter_audio_fade_tween = create_tween()
		typewriter_audio_fade_tween.tween_property(typewriter_audio, "volume_db", -60.0, 0.15).set_trans(Tween.TRANS_SINE)
		typewriter_audio_fade_tween.tween_callback(typewriter_audio.stop)
