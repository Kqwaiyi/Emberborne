## scripts/levels/level_01.gd
## Attach to the Level01 root node in level_01.tscn.
## Owns the timer, score, anger, mouse count, and HUD updates.
## Coordinates all signals from cat, mice, enemies, and exit door.
extends Node2D

# ── Exported balance values ───────────────────────────────────────────────────
@export var required_mice: int          = 3
@export var starting_score: int         = 1000
@export var points_per_mouse: int       = 500
@export var caught_penalty: int         = 300
@export var maximum_time_bonus: int     = 3000
@export var time_penalty_per_second: float = 20.0
@export var anger_per_detection: float  = 20.0
@export var total_mice: int             = 5

# ── Runtime state ─────────────────────────────────────────────────────────────
var _elapsed_time: float  = 0.0
var _current_score: int   = 0
var _mice_caught: int     = 0
var _times_caught: int    = 0
var _anger: float         = 0.0
var _level_active: bool   = true

# ── Node references ───────────────────────────────────────────────────────────
@onready var _hud:            HUD         = $HUD
@onready var _results:        ResultsScreen = $ResultsScreen
@onready var _cat:            Cat         = $Characters/Cat
@onready var _exit_door:      ExitDoor    = $ExitDoor

func _ready() -> void:
	_current_score = starting_score
	_update_hud_all()

	# Connect cat signals
	_cat.mouse_caught.connect(_on_mouse_caught)
	_cat.player_caught.connect(_on_player_caught)

	# Connect exit door
	_exit_door.exit_attempted.connect(_on_exit_attempted)
	_exit_door.level_completed.connect(_on_level_completed)

	# Give all enemies a reference to the cat and an anger getter
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("setup"):
			enemy.setup(_cat, func() -> float: return _anger)
		# Connect detection signal
		if enemy.has_signal("detection_started"):
			enemy.detection_started.connect(_on_detection_started)
		# Connect enemy catch area to cat
		var catch_area := enemy.get_node_or_null("CatchArea")
		if catch_area is Area2D:
			catch_area.body_entered.connect(_on_catch_area_body_entered)

func _process(delta: float) -> void:
	if not _level_active:
		return
	_elapsed_time += delta
	_hud.update_time(_elapsed_time)

	# Also update score display live as time bonus decays (optional)
	_hud.update_score(_current_score)

# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_mouse_caught(points: int) -> void:
	_mice_caught  += 1
	_current_score = max(0, _current_score + points)
	_hud.update_mouse_count(_mice_caught, required_mice)
	_hud.update_score(_current_score)

	if _mice_caught >= required_mice:
		_exit_door.activate()
		_hud.show_message("Satisfied! Return to the front door")

func _on_player_caught() -> void:
	_times_caught  += 1
	_current_score  = max(0, _current_score - caught_penalty)
	_hud.update_caught_count(_times_caught)
	_hud.update_score(_current_score)
	_hud.show_message("Caught! -%d points" % caught_penalty)

func _on_detection_started() -> void:
	_anger = min(100.0, _anger + anger_per_detection)
	_hud.update_anger(_anger)

func _on_exit_attempted() -> void:
	_hud.show_message("The cat is not satisfied yet")

func _on_level_completed() -> void:
	if not _level_active:
		return
	_level_active = false

	# Stop cat input; freeze enemies
	_cat.disable_input()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("disable"):
			enemy.disable()

	# Calculate final score
	var time_bonus: int = max(0, maximum_time_bonus - int(_elapsed_time * time_penalty_per_second))
	_current_score = max(0, _current_score + time_bonus)

	_results.show_results(
		_elapsed_time,
		_mice_caught,
		total_mice,
		required_mice,
		_times_caught,
		time_bonus,
		_current_score
	)

func _on_catch_area_body_entered(_body: Node) -> void:
	# Hidden cats cannot be caught — the hiding spot protects them.
	if _level_active and not _cat.is_hidden:
		_cat.trigger_caught()

# ── Public getter for anger (used by Callable in setup()) ─────────────────────
func get_anger() -> float:
	return _anger

# ── Convenience ───────────────────────────────────────────────────────────────
func _update_hud_all() -> void:
	_hud.update_mouse_count(_mice_caught, required_mice)
	_hud.update_time(_elapsed_time)
	_hud.update_score(_current_score)
	_hud.update_caught_count(_times_caught)
	_hud.update_anger(_anger)
