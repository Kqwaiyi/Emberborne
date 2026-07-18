## scripts/characters/enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

# ── Movement ──────────────────────────────────────────────────────────────────
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 55.0
@export var cat_max_speed: float = 220.0

# ── Vision ────────────────────────────────────────────────────────────────────
@export var vision_range: float = 180.0   # reduced — fairer on small maps
@export var vision_angle: float = 55.0

# ── Patrol ────────────────────────────────────────────────────────────────────
@export var patrol_route: NodePath
@export var patrol_ping_pong: bool = true

# ── Timing ────────────────────────────────────────────────────────────────────
@export var lost_sight_delay: float  = 2
@export var alert_duration: float    = 0.3   # pause before chasing (smooth transition)
@export var bark_duration: float     = 1.0   # stop + bark after tagging cat

# ── Signals ───────────────────────────────────────────────────────────────────
signal detection_started()

# ── State machine ─────────────────────────────────────────────────────────────
enum State { PATROL, ALERT, CHASE, RETURN }
var _state: State = State.PATROL

# ── Runtime ───────────────────────────────────────────────────────────────────
var _player: Cat       = null
var _anger_getter: Callable

var facing: Vector2 = Vector2.RIGHT

var _patrol_points: Array[Vector2] = []
var _patrol_index: int = 0
var _patrol_dir: int   = 1
var _lost_timer: float = 0.0
var _return_target: Vector2
var _alert_timer: float = 0.0
var _bark_timer: float  = 0.0
var _catch_area: Area2D = null

func _ready() -> void:
	add_to_group("enemy")
	if patrol_route != NodePath(""):
		var route: Node = get_node_or_null(patrol_route)
		if route != null:
			for child in route.get_children():
				if child is Marker2D:
					_patrol_points.append(child.global_position)
	if _patrol_points.is_empty():
		push_warning(name + ": no patrol points found — enemy will stand still.")

	_catch_area = get_node_or_null("CatchArea") as Area2D
	if _catch_area != null:
		_catch_area.body_entered.connect(_on_self_catch_entered)

func setup(player: Cat, anger_getter: Callable) -> void:
	_player       = player
	_anger_getter = anger_getter

func _physics_process(delta: float) -> void:
	if _player == null:
		return

	# Bark overrides everything — dog stops and plays bark animation
	if _bark_timer > 0.0:
		_bark_timer -= delta
		velocity = Vector2.ZERO
		if _bark_timer <= 0.0:
			_end_bark()
		move_and_slide()
		return

	match _state:
		State.PATROL: _tick_patrol(delta)
		State.ALERT:  _tick_alert(delta)
		State.CHASE:  _tick_chase(delta)
		State.RETURN: _tick_return(delta)
	move_and_slide()
	_sync_run_animation()

# ── Anger helpers ─────────────────────────────────────────────────────────────

func _anger_norm() -> float:
	if not _anger_getter.is_valid():
		return 0.0
	return clamp(_anger_getter.call() / 100.0, 0.0, 1.0)

func _patrol_speed_mult() -> float:
	return lerp(1.0, 1.3, _anger_norm())

func _get_chase_speed() -> float:
	var t: float = _anger_norm()
	if t <= 0.6:
		return lerp(chase_speed, cat_max_speed, t / 0.6)
	else:
		return lerp(cat_max_speed, cat_max_speed * 1.25, (t - 0.6) / 0.4)

# ── PATROL ────────────────────────────────────────────────────────────────────

func _tick_patrol(_delta: float) -> void:
	if _patrol_points.size() < 2:
		velocity = Vector2.ZERO
		return

	var target: Vector2    = _patrol_points[_patrol_index]
	var to_target: Vector2 = target - global_position

	if to_target.length() < 8.0:
		_advance_patrol_index()
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * (patrol_speed * _patrol_speed_mult())
		_update_facing(velocity)

	if _can_see_player():
		_enter_alert()

func _advance_patrol_index() -> void:
	if patrol_ping_pong:
		if _patrol_index >= _patrol_points.size() - 1:
			_patrol_dir = -1
		elif _patrol_index <= 0:
			_patrol_dir = 1
		_patrol_index = clamp(_patrol_index + _patrol_dir, 0, _patrol_points.size() - 1)
	else:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()

# ── ALERT (smooth transition — dog spots cat and pauses before chasing) ───────

func _tick_alert(delta: float) -> void:
	velocity = Vector2.ZERO
	_alert_timer -= delta

	# Keep facing the cat while alerting
	if _player != null:
		var to_player: Vector2 = _player.global_position - global_position
		if to_player.length_squared() > 1.0:
			_update_facing(to_player)

	if _alert_timer <= 0.0:
		_enter_chase()
	elif not _can_see_player():
		# Cat hid during alert window — stand down
		_state = State.PATROL
		_set_visual_chasing(false)
		_set_alert_icon(false)

# ── CHASE ─────────────────────────────────────────────────────────────────────

func _tick_chase(delta: float) -> void:
	var to_player: Vector2 = _player.global_position - global_position

	if to_player.length() > 6.0:
		velocity = to_player.normalized() * _get_chase_speed()
		_update_facing(velocity)
	else:
		velocity = Vector2.ZERO

	# Hiding spot = instant concealment; don't wait out the lost_sight_delay timer
	if _player.is_hidden:
		_enter_return()
		return

	# Poll catch area every frame — body_entered won't re-fire if cat never left
	_poll_catch_area()

	if not _can_see_player():
		_lost_timer += delta
		if _lost_timer >= lost_sight_delay:
			_enter_return()
	else:
		_lost_timer = 0.0

func _poll_catch_area() -> void:
	if _catch_area == null or _player == null:
		return
	if _player.is_hidden or _player.is_invulnerable:
		return
	for body in _catch_area.get_overlapping_bodies():
		if body == _player:
			_player.trigger_caught()
			_start_bark()
			break

func _start_bark() -> void:
	_bark_timer = bark_duration
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_barking"):
		vis.call("set_barking", true)

# ── RETURN ────────────────────────────────────────────────────────────────────

func _tick_return(_delta: float) -> void:
	var to_target: Vector2 = _return_target - global_position

	if to_target.length() < 16.0:
		_state        = State.PATROL
		_patrol_index = _nearest_patrol_index()
		velocity      = Vector2.ZERO
	else:
		velocity = to_target.normalized() * (patrol_speed * _patrol_speed_mult())
		_update_facing(velocity)

	if _can_see_player():
		_enter_alert()

# ── State transitions ─────────────────────────────────────────────────────────

func _enter_alert() -> void:
	if _state == State.ALERT or _state == State.CHASE:
		return
	_state       = State.ALERT
	_alert_timer = alert_duration
	detection_started.emit()
	_set_visual_chasing(true)
	_set_alert_icon(true)
	var det := get_node_or_null("DetectionAudio")
	if det:
		det.play()

func _enter_chase() -> void:
	_set_alert_icon(false)
	_state      = State.CHASE
	_lost_timer = 0.0

func _enter_return() -> void:
	_state         = State.RETURN
	_lost_timer    = 0.0
	_return_target = _patrol_points[_nearest_patrol_index()] \
		if not _patrol_points.is_empty() else global_position
	_set_visual_chasing(false)

# ── Bark ──────────────────────────────────────────────────────────────────────

func _on_self_catch_entered(body: Node) -> void:
	if body.is_in_group("player") and not _player.is_hidden:
		_start_bark()

func _end_bark() -> void:
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_barking"):
		vis.call("set_barking", false)

# ── Vision detection ──────────────────────────────────────────────────────────

func _can_see_player() -> bool:
	if _player == null or _player.is_hidden:
		return false

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float        = to_player.length()
	if dist > vision_range:
		return false

	var angle_diff: float = rad_to_deg(facing.angle_to(to_player.normalized()))
	if abs(angle_diff) > vision_angle * 0.5:
		return false

	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		_player.global_position,
		(1 << 6) | (1 << 0)   # VisionBlocker (64) + WorldSolid (1) — walls block vision
	)
	query.exclude = [get_rid()]
	return space.intersect_ray(query).is_empty()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() > 10.0:
		facing = vel.normalized()
		var vis := get_node_or_null("Visual")
		if vis != null and vis.has_method("update_direction"):
			vis.call("update_direction", vel)

func _sync_run_animation() -> void:
	if _state == State.ALERT:
		return   # alert uses Walk_chase via set_chasing(true); don't override
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_force_run"):
		vis.call("set_force_run", _anger_norm() >= 0.6)

func _set_visual_chasing(chasing: bool) -> void:
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_chasing"):
		vis.call("set_chasing", chasing)

func _set_alert_icon(show: bool) -> void:
	var icon := get_node_or_null("AlertIcon")
	if icon != null:
		icon.visible = show

func _nearest_patrol_index() -> int:
	var best_idx: int    = 0
	var best_dist: float = INF
	for i in _patrol_points.size():
		var d: float = global_position.distance_to(_patrol_points[i])
		if d < best_dist:
			best_dist = d
			best_idx  = i
	return best_idx

func disable() -> void:
	set_physics_process(false)
	velocity = Vector2.ZERO
