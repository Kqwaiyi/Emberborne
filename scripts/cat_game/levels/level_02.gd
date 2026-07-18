extends Node2D

@export var required_mice: int              = 2
@export var starting_score: int             = 1000
@export var points_per_mouse: int           = 500
@export var caught_penalty: int             = 300
@export var maximum_time_bonus: int         = 3000
@export var optimal_time_seconds: float     = 60.0
@export var time_penalty_per_second: float  = 20.0
@export var anger_per_detection: float      = 20.0
@export var total_mice: int                 = 3

var _elapsed_time: float = 0.0
var _current_score: int  = 0
var _mice_caught: int    = 0
var _times_caught: int   = 0
var _anger: float        = 0.0
var _level_active: bool  = true

@onready var _cat: Cat = $Cat

var _hud: HUD = null
var _results: ResultsScreen = null

func _ready() -> void:
	MusicManager.play_music("cat_game")
	_hud     = get_node_or_null("HUD") as HUD
	_results = get_node_or_null("ResultsScreen") as ResultsScreen

	_current_score = starting_score
	_update_hud_all()
	if _hud:
		_hud.set_level_mice(total_mice)

	_cat.mouse_caught.connect(_on_mouse_caught)
	_cat.player_caught.connect(_on_player_caught)

	for door in _all_exit_doors():
		door.exit_attempted.connect(_on_exit_attempted)
		door.level_completed.connect(_on_level_completed)

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
	if _hud:
		_hud.update_time(_elapsed_time)
		_hud.update_score(_current_score)

func _on_mouse_caught(points: int) -> void:
	_mice_caught   += 1
	_current_score  = max(0, _current_score + points)
	if _hud:
		_hud.update_mouse_count(_mice_caught, required_mice)
		_hud.update_score(_current_score)
	if _mice_caught >= required_mice:
		for door in _all_exit_doors():
			door.activate()
		if _hud:
			match _mice_caught:
				total_mice:
					_hud.show_message("ALL MICE CAUGHT!  →  HEAD TO THE EXIT!", Color(0.18, 0.88, 0.28, 1), 26, 4.0)
				required_mice:
					_hud.show_message("SATISFIED", Color(1.0, 0.88, 0.2, 1), 30, 3.0)

func _on_player_caught() -> void:
	_times_caught  += 1
	_current_score  = max(0, _current_score - caught_penalty)
	if _hud:
		_hud.update_caught_count(_times_caught)
		_hud.update_score(_current_score)
		_hud.show_message("HURT!  -%d PTS" % caught_penalty, Color(1.0, 0.12, 0.08, 1), 32, 1.8, 18.0)

func _on_detection_started() -> void:
	_anger = min(100.0, _anger + anger_per_detection)
	if _hud:
		_hud.update_anger(_anger)

func _on_exit_attempted() -> void:
	if _level_active and _hud:
		_hud.show_message("NOT ENOUGH MICE!", Color(1.0, 0.7, 0.1, 1), 24, 2.0, 7.0)

func _on_level_completed() -> void:
	if not _level_active:
		return
	_level_active = false
	if _hud:
		_hud.play_finish_sound()
	_cat.disable_input()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("disable"):
			enemy.disable()

	var overtime: float = max(0.0, _elapsed_time - optimal_time_seconds)
	var time_bonus: int = max(0, maximum_time_bonus - int(overtime * time_penalty_per_second))
	_current_score = max(0, _current_score + time_bonus)

	var mouse_points: int      = _mice_caught * points_per_mouse
	var caught_deductions: int = _times_caught * caught_penalty
	var level_total: int       = time_bonus + mouse_points - caught_deductions
	var prev_total: int        = GameState.total_score

	if _results:
		_results.show_results(
			_elapsed_time,
			_mice_caught,
			total_mice,
			time_bonus,
			mouse_points,
			caught_deductions,
			level_total,
			prev_total,
			prev_total + level_total,
			GameState.get_next_level(scene_file_path)
		)

func _on_catch_area_body_entered(_body: Node) -> void:
	if _level_active and not _cat.is_hidden:
		_cat.trigger_caught()

func _all_exit_doors() -> Array:
	var result: Array = []
	for node in get_tree().get_nodes_in_group("exit_door"):
		var d := node as ExitDoor
		if d != null:
			result.append(d)
	return result

func _update_hud_all() -> void:
	if not _hud:
		return
	_hud.update_mouse_count(_mice_caught, required_mice)
	_hud.update_time(_elapsed_time)
	_hud.update_score(_current_score)
	_hud.update_caught_count(_times_caught)
	_hud.update_anger(_anger)
