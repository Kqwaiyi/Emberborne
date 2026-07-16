extends Node2D

@export var required_mice: int              = 3
@export var starting_score: int             = 1000
@export var points_per_mouse: int           = 500
@export var caught_penalty: int             = 300
@export var maximum_time_bonus: int         = 3000
@export var time_penalty_per_second: float  = 20.0
@export var anger_per_detection: float      = 20.0
@export var total_mice: int                 = 5

var _elapsed_time: float = 0.0
var _current_score: int  = 0
var _mice_caught: int    = 0
var _times_caught: int   = 0
var _anger: float        = 0.0
var _level_active: bool  = true

@onready var _cat: Cat = $Cat

func _ready() -> void:
	_current_score = starting_score

	_cat.mouse_caught.connect(_on_mouse_caught)
	_cat.player_caught.connect(_on_player_caught)

	# Wire up exit door if one exists anywhere in the scene
	var door := _find_exit_door()
	if door != null:
		door.exit_attempted.connect(_on_exit_attempted)
		door.level_completed.connect(_on_level_completed)

	# Give every enemy a cat reference and anger getter, connect catch areas
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("setup"):
			enemy.setup(_cat, func() -> float: return _anger)
		if enemy.has_signal("detection_started"):
			enemy.detection_started.connect(_on_detection_started)
		var catch_area := enemy.get_node_or_null("CatchArea")
		if catch_area is Area2D:
			catch_area.body_entered.connect(_on_catch_area_body_entered)

func _process(delta: float) -> void:
	if not _level_active:
		return
	_elapsed_time += delta

func _on_mouse_caught(points: int) -> void:
	_mice_caught   += 1
	_current_score  = max(0, _current_score + points)
	var door := _find_exit_door()
	if _mice_caught >= required_mice and door != null:
		door.activate()

func _on_player_caught() -> void:
	_times_caught  += 1
	_current_score  = max(0, _current_score - caught_penalty)

func _on_detection_started() -> void:
	_anger = min(100.0, _anger + anger_per_detection)

func _on_exit_attempted() -> void:
	pass

func _on_level_completed() -> void:
	if not _level_active:
		return
	_level_active = false
	_cat.disable_input()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("disable"):
			enemy.disable()

func _on_catch_area_body_entered(_body: Node) -> void:
	if _level_active and not _cat.is_hidden:
		_cat.trigger_caught()

func _find_exit_door() -> ExitDoor:
	var doors := get_tree().get_nodes_in_group("exit_door")
	if not doors.is_empty():
		return doors[0] as ExitDoor
	return null
