## scripts/ui/hud.gd
## Attach to the HUD root node (CanvasLayer) in hud.tscn.
## Only displays information. No game logic lives here.
class_name HUD
extends CanvasLayer

@onready var _mice_label:   Label       = $TopLeft/MiceLabel
@onready var _time_label:   Label       = $TopLeft/TimeLabel
@onready var _score_label:  Label       = $TopLeft/ScoreLabel
@onready var _caught_label: Label       = $TopLeft/CaughtLabel
@onready var _anger_bar:    ProgressBar = $TopRight/AngerBar
@onready var _message_label: Label      = $MessageLabel
@onready var _message_timer: Timer      = $MessageTimer

func _ready() -> void:
	_message_label.visible = false
	_message_timer.one_shot = true
	_message_timer.timeout.connect(_on_message_timeout)

# ── Public update functions called by level_01.gd ────────────────────────────

func update_mouse_count(caught: int, required: int) -> void:
	_mice_label.text = "Mice: %d / %d" % [caught, required]

func update_time(elapsed_time: float) -> void:
	var total_s: int = int(elapsed_time)
	var mins: int    = total_s / 60
	var secs: int    = total_s % 60
	var cents: int   = int((elapsed_time - float(total_s)) * 100.0)
	_time_label.text = "Time: %02d:%02d.%02d" % [mins, secs, cents]

func update_score(score: int) -> void:
	_score_label.text = "Score: %d" % score

func update_caught_count(count: int) -> void:
	_caught_label.text = "Caught: %d" % count

func update_anger(value: float) -> void:
	_anger_bar.value = value

func show_message(text: String) -> void:
	_message_label.text    = text
	_message_label.visible = true
	_message_label.modulate.a = 1.0
	# Reset timer so new messages always show for the full duration.
	_message_timer.stop()
	_message_timer.start(2.0)

func _on_message_timeout() -> void:
	_message_label.visible = false
