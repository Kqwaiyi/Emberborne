class_name HUD
extends CanvasLayer

const _FACES: Array[Texture2D] = [
	preload("res://assets/ui/Loot/stage1.png"),
	preload("res://assets/ui/Loot/stage2.png"),
	preload("res://assets/ui/Loot/stage3.png"),
]
const _TOPS: Array[Texture2D] = [
	preload("res://assets/ui/Loot/stage1_top.png"),
	preload("res://assets/ui/Loot/stage2_top.png"),
	preload("res://assets/ui/Loot/stage3_top.png"),
]

@onready var _time_label:    Label       = $HUDPanel/HBox/InfoBox/TimeRow/TimeLabel
@onready var _mice_label:    Label       = $HUDPanel/HBox/InfoBox/MiceRow/MiceLabel
@onready var _anger_bar:     ProgressBar = $TopRightPanel/VBox/AngerHBox/BarBox/AngerBar
@onready var _anger_face:    TextureRect = $TopRightPanel/VBox/AngerHBox/FaceBox/FaceIcon
@onready var _anger_top:     TextureRect = $TopRightPanel/VBox/AngerHBox/FaceBox/TopIcon
@onready var _info_line:     Label       = $TopRightPanel/VBox/InfoLine
@onready var _message_label: Label       = $MessageLabel
@onready var _message_timer: Timer       = $MessageTimer

var _shake_tween:         Tween = null
var _msg_base_offset_left: float = 0.0

func _ready() -> void:
	_message_label.visible = false
	_message_timer.one_shot = true
	_message_timer.timeout.connect(_on_message_timeout)
	_set_anger_stage(0)
	_info_line.text = "Total Points: %d  |  Total Mice: 0" % GameState.total_score
	_msg_base_offset_left = _message_label.offset_left

func update_mouse_count(caught: int, required: int) -> void:
	_mice_label.text = "%d / %d" % [caught, required]

func update_time(elapsed: float) -> void:
	var s := int(elapsed)
	_time_label.text = "%02d:%02d" % [s / 60, s % 60]

func update_anger(value: float) -> void:
	_anger_bar.value = value
	var stage: int = 0 if value < 33.0 else (1 if value < 66.0 else 2)
	_set_anger_stage(stage)

func set_level_mice(count: int) -> void:
	_info_line.text = "Total Points: %d  |  Total Mice: %d" % [GameState.total_score, count]

func update_score(_v: int) -> void:        pass
func update_caught_count(_v: int) -> void: pass

func show_message(text: String, color: Color = Color(1, 1, 0.8, 1), size: int = 22, duration: float = 2.5, shake: float = 0.0) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.add_theme_font_size_override("font_size", size)
	_message_label.visible = true
	_message_timer.stop()
	_message_timer.start(duration)
	if shake > 0.0:
		_shake_label(shake)

func _shake_label(amplitude: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_message_label.offset_left = _msg_base_offset_left
	_shake_tween = create_tween()
	# Fast tight shake for large amplitude, slower gentle for small
	var step  := 0.03  if amplitude >= 14.0 else 0.045
	var count := 8     if amplitude >= 14.0 else 5
	for i in count:
		var dir := 1.0 if i % 2 == 0 else -1.0
		_shake_tween.tween_property(_message_label, "offset_left", _msg_base_offset_left + amplitude * dir, step)
	_shake_tween.tween_property(_message_label, "offset_left", _msg_base_offset_left, step * 0.5)

func _set_anger_stage(stage: int) -> void:
	_anger_face.texture = _FACES[stage]
	_anger_top.texture  = _TOPS[stage]

func _on_message_timeout() -> void:
	_message_label.visible = false
