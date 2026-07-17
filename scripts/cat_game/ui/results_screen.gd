class_name ResultsScreen
extends CanvasLayer

const MESSAGES: Array[String] = [
	"Purr-fect!",
	"Sneaky little rascal!",
	"All mice are belong to us!",
	"Yippppeeee!",
	"Nice job!",
	"Skibidi rizzler ohio maxer",
	"The cat prevails!",
	"Mischief managed!",
	"Meow means yes!",
	"Big cat energy.",
]

const _RED   := Color(0.65, 0.12, 0.08, 1)
const _DARK  := Color(0.18, 0.12, 0.07, 1)
const _BROWN := Color(0.14, 0.09, 0.04, 1)

var _next_path: String = ""

@onready var _time_val:      Label  = $Panel/VBox/ContentHBox/StatsBox/TimeRow/Val
@onready var _mice_val:      Label  = $Panel/VBox/ContentHBox/StatsBox/MiceRow/Val
@onready var _bonus_val:     Label  = $Panel/VBox/ContentHBox/StatsBox/BonusRow/Val
@onready var _mouse_pts_val: Label  = $Panel/VBox/ContentHBox/StatsBox/MouseRow/Val
@onready var _hurt_val:      Label  = $Panel/VBox/ContentHBox/StatsBox/HurtRow/Val
@onready var _level_val:     Label  = $Panel/VBox/ContentHBox/StatsBox/LevelRow/Val
@onready var _prev_val:      Label  = $Panel/VBox/ContentHBox/StatsBox/PrevRow/Val
@onready var _new_val:       Label  = $Panel/VBox/ContentHBox/StatsBox/NewRow/Val
@onready var _message_label: Label  = $Panel/VBox/MessageLabel
@onready var _next_btn:      Button = $Panel/VBox/NextButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_next_btn.pressed.connect(_on_next_pressed)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_next_pressed()

func show_results(
	elapsed_time: float,
	mice_caught: int,
	total_mice: int,
	time_bonus: int,
	mouse_points: int,
	caught_deductions: int,
	level_total: int,
	prev_total: int,
	new_total: int,
	next_scene_path: String
) -> void:
	_next_path = next_scene_path

	var s := int(elapsed_time)
	_time_val.text      = "%02d:%02d" % [s / 60, s % 60]
	_mice_val.text      = "%d / %d" % [mice_caught, total_mice]
	_bonus_val.text     = "+%d" % time_bonus
	_mouse_pts_val.text = "+%d" % mouse_points
	_hurt_val.text      = "-%d" % caught_deductions if caught_deductions > 0 else "0"

	# Level total — allow negatives, tint red when negative
	if level_total >= 0:
		_level_val.text = "+%d" % level_total
		_level_val.add_theme_color_override("font_color", _DARK)
	else:
		_level_val.text = "%d" % level_total
		_level_val.add_theme_color_override("font_color", _RED)

	_prev_val.text = "%d" % prev_total

	_new_val.text = "%d" % new_total
	_new_val.add_theme_color_override("font_color", _RED if new_total < 0 else _BROWN)

	_message_label.text = MESSAGES[randi() % MESSAGES.size()]
	visible = true

func _on_next_pressed() -> void:
	get_tree().paused = false
	if _next_path.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(_next_path)
