## scripts/ui/results_screen.gd
## Attach to the ResultsScreen root node (CanvasLayer) in results_screen.tscn.
## IMPORTANT: Set Process Mode to "Always" in the Inspector so it works
##            even when get_tree().paused = true.
class_name ResultsScreen
extends CanvasLayer

@onready var _time_label:    Label  = $Panel/VBox/TimeLabel
@onready var _mice_label:    Label  = $Panel/VBox/MiceLabel
@onready var _required_label:Label  = $Panel/VBox/RequiredLabel
@onready var _caught_label:  Label  = $Panel/VBox/CaughtLabel
@onready var _bonus_label:   Label  = $Panel/VBox/BonusLabel
@onready var _score_label:   Label  = $Panel/VBox/ScoreLabel
@onready var _restart_btn:   Button = $Panel/VBox/RestartButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS   # works even when tree is paused
	_restart_btn.pressed.connect(_on_restart)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("restart_level"):
		_on_restart()

func show_results(
	elapsed_time: float,
	mice_caught: int,
	total_mice: int,
	required_mice: int,
	times_caught: int,
	time_bonus: int,
	final_score: int
) -> void:
	var total_s: int = int(elapsed_time)
	var mins: int    = total_s / 60
	var secs: int    = total_s % 60
	var cents: int   = int((elapsed_time - float(total_s)) * 100.0)

	_time_label.text     = "Time: %02d:%02d.%02d" % [mins, secs, cents]
	_mice_label.text     = "Mice Caught: %d / %d" % [mice_caught, total_mice]
	_required_label.text = "Required Mice: %d" % required_mice
	_caught_label.text   = "Times Caught: %d" % times_caught
	_bonus_label.text    = "Time Bonus: %d" % time_bonus
	_score_label.text    = "Final Score: %d" % final_score
	visible = true

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
