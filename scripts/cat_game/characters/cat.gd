## scripts/characters/cat.gd
## Attach to the Cat (CharacterBody2D) root node of cat.tscn.
## Handles input, acceleration-based movement, hiding state,
## catch invulnerability, and speed boost.
class_name Cat
extends CharacterBody2D

# ── Exported movement values ──────────────────────────────────────────────────
@export var maximum_speed: float = 220.0
@export var acceleration_time: float = 0.2   # seconds to reach full speed
@export var deceleration_time: float = 0.2   # seconds to stop from full speed

# ── Exported catch-penalty response values ────────────────────────────────────
@export var caught_speed_multiplier: float = 1.5
@export var caught_speed_duration: float   = 1.5
@export var caught_invulnerability_duration: float = 1.5

# ── Signals ───────────────────────────────────────────────────────────────────
signal mouse_caught(mouse_points: int)
signal player_caught()
signal hidden_state_changed(is_hidden: bool)

# ── Runtime state ─────────────────────────────────────────────────────────────
var is_hidden: bool = false
var is_invulnerable: bool = false
var hide_zone_count: int = 0          # how many hide zones currently overlap
var is_boosted: bool = false

var _input_enabled: bool = true
var _boost_timer: float = 0.0
var _invuln_timer: float = 0.0
var _accel: float = 0.0
var _decel: float = 0.0

# ── Node references (assigned in _ready) ─────────────────────────────────────
@onready var _visual: Node2D = $Visual
@onready var _catch_area: Area2D = $MouseCatchArea
@onready var _caught_sound: AudioStreamPlayer2D = $CaughtSound
@onready var _cat_noise_audio: AudioStreamPlayer = $CatNoiseAudio
@onready var _step_audio:        AudioStreamPlayer = $StepAudio
@onready var _mouse_catch_audio: AudioStreamPlayer = $MouseCatchAudio

var _cat_noise_timer: float = 10.0
var _step_timer:      float = 0.0

func _ready() -> void:
	add_to_group("player")
	# Calculate acceleration/deceleration forces from time constants.
	# accel = max_speed / time  (pixels/s per second)
	_accel = maximum_speed / acceleration_time
	_decel = maximum_speed / deceleration_time

	_catch_area.body_entered.connect(_on_catch_area_body_entered)

func _process(delta: float) -> void:
	if not _input_enabled:
		return
	_cat_noise_timer -= delta
	if _cat_noise_timer <= 0.0:
		_cat_noise_timer = 10.0
		_cat_noise_audio.play()

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if _input_enabled:
		_apply_movement(delta)
	else:
		# Slide to a stop when input is disabled (level complete)
		velocity = velocity.move_toward(Vector2.ZERO, _decel * delta)
	move_and_slide()
	_tick_steps(delta)

# ── Movement ──────────────────────────────────────────────────────────────────
func _apply_movement(delta: float) -> void:
	var raw: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Normalise so diagonal is not faster, but preserve partial-axis magnitudes
	# from analogue sticks via clamping rather than hard normalize.
	if raw.length_squared() > 1.0:
		raw = raw.normalized()

	var effective_speed: float = maximum_speed
	if is_boosted:
		effective_speed *= caught_speed_multiplier

	var target_velocity: Vector2 = raw * effective_speed

	if raw.length_squared() > 0.001:
		velocity = velocity.move_toward(target_velocity, _accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, _decel * delta)

	# Tell the visual which direction we're moving.
	# cat_visual.gd handles rotation (placeholder) or animation (sprite mode).
	if _visual.has_method("update_direction"):
		_visual.call("update_direction", velocity)

# ── Step sound ────────────────────────────────────────────────────────────────
func _tick_steps(delta: float) -> void:
	if velocity.length() > 20.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_audio.play()
			_step_timer = 0.35
	else:
		_step_timer = 0.0

# ── Timer ticks ───────────────────────────────────────────────────────────────
func _tick_timers(delta: float) -> void:
	if _boost_timer > 0.0:
		_boost_timer -= delta
		if _boost_timer <= 0.0:
			is_boosted = false
			_update_outline(false)
			if _visual.has_method("set_force_run"):
				_visual.call("set_force_run", false)

	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false

# ── Called by hiding_spot.gd when entering a hide zone ───────────────────────
func enter_hide_zone() -> void:
	hide_zone_count += 1
	if hide_zone_count == 1:
		is_hidden = true
		_visual.modulate.a = 0.35
		hidden_state_changed.emit(true)

# ── Called by hiding_spot.gd when leaving a hide zone ────────────────────────
func leave_hide_zone() -> void:
	hide_zone_count = max(0, hide_zone_count - 1)
	if hide_zone_count == 0:
		is_hidden = false
		_visual.modulate.a = 1.0
		hidden_state_changed.emit(false)

# ── Called by the level when an enemy catch area overlaps the cat ─────────────
func trigger_caught() -> void:
	if is_invulnerable:
		return
	is_invulnerable = true
	is_boosted = true
	_invuln_timer = caught_invulnerability_duration
	_boost_timer = caught_speed_duration
	_update_outline(true)
	if _visual.has_method("set_force_run"):
		_visual.call("set_force_run", true)
	if _caught_sound.stream != null:
		_caught_sound.play()
	player_caught.emit()

# ── Mouse catch area ──────────────────────────────────────────────────────────
func _on_catch_area_body_entered(body: Node) -> void:
	if body.is_in_group("mouse"):
		var mouse_node := body as Mouse
		if mouse_node != null and mouse_node.can_be_caught:
			var pts: int = mouse_node.catch()
			_mouse_catch_audio.play()
			mouse_caught.emit(pts)

# ── Outline drawing (placeholder — replace with shader later) ─────────────────
func _update_outline(show_outline: bool) -> void:
	# cat_visual.gd exposes set_outline(); swap for a shader call later.
	if _visual.has_method("set_outline"):
		_visual.call("set_outline", show_outline)

# ── Called by level_01.gd to stop all cat input at level end ─────────────────
func disable_input() -> void:
	_input_enabled = false
