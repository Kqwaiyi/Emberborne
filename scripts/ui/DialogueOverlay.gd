extends CanvasLayer

@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var portrait_container: PanelContainer = $DialogueBox/MarginContainer/HBoxContainer/PortraitContainer
@onready var portrait: TextureRect = $DialogueBox/MarginContainer/HBoxContainer/PortraitContainer/Portrait
@onready var speaker_label: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel
@onready var advance_indicator: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/AdvanceIndicator

var _typewriter_tween: Tween = null
var _indicator_tween: Tween = null
var _is_typewriter_playing: bool = false

## Seconds per character for the typewriter effect.
const TYPEWRITER_SPEED: float = 0.03

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_box.hide()
	advance_indicator.hide()

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

	# Set text with typewriter effect
	dialogue_label.text = text
	dialogue_label.visible_ratio = 0.0
	advance_indicator.hide()
	_stop_indicator_animation()

	_is_typewriter_playing = true

	# Kill any previous typewriter tween
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var duration = text.length() * TYPEWRITER_SPEED
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

## Instantly completes the typewriter animation, showing all text.
func complete_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	dialogue_label.visible_ratio = 1.0
	_is_typewriter_playing = false
	advance_indicator.show()
	_start_indicator_animation()

## Returns true if the typewriter animation is currently in progress.
func is_typewriter_playing() -> bool:
	return _is_typewriter_playing

## Fades in the dialogue box with a short animation.
func show_box() -> void:
	dialogue_box.modulate.a = 0.0
	dialogue_box.show()
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.2)

## Fades out and hides the dialogue box.
func hide_box() -> void:
	var tween = create_tween()
	tween.tween_property(dialogue_box, "modulate:a", 0.0, 0.15)
	tween.finished.connect(func(): dialogue_box.hide())

func _on_typewriter_finished() -> void:
	_is_typewriter_playing = false
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
