## scripts/characters/enemy_base.gd
## Base class for all enemies.
## Uses direct point-to-point movement — no baked nav mesh required.
## NavigationAgent2D is kept in the scene tree for a future upgrade
## but is NOT used for movement in this prototype.
class_name EnemyBase
extends CharacterBody2D

# ── Movement ──────────────────────────────────────────────────────────────────
@export var patrol_speed: float = 80.0

## Chase speed when anger = 0 %.
## Defaults to 25 % of cat_max_speed (very slow, player has a clear head start).
## Adjust per enemy type if you want different low-anger personalities.
@export var chase_speed: float = 55.0

## Set this to match Cat.maximum_speed (default 220).
## The entire chase-speed curve is defined relative to this value.
@export var cat_max_speed: float = 220.0

# ── Vision ────────────────────────────────────────────────────────────────────
@export var vision_range: float = 360.0
@export var vision_angle: float = 40.0    # total cone width in degrees

# ── Patrol ────────────────────────────────────────────────────────────────────
## HOW TO SET PATROL POINTS
## ─────────────────────────
## 1. In the level scene, find the PatrolRoutes node.
## 2. Select the route that belongs to this enemy (e.g. Human01Route).
## 3. Move the Marker2D children (P1, P2, …) to wherever you want this
##    enemy to walk.  Add more Marker2D children for more stops.
## 4. In the Inspector for THIS enemy node, drag that PatrolRoute node
##    into the "Patrol Route" slot below.
##
## Ping-pong = true (default):  enemy walks A → B → A → B …
## Ping-pong = false:           enemy walks A → B → C → A … (loop)
@export var patrol_route: NodePath
@export var patrol_ping_pong: bool = true

# ── Timing ────────────────────────────────────────────────────────────────────
@export var lost_sight_delay: float = 0.6

# ── Signals ───────────────────────────────────────────────────────────────────
signal detection_started()

# ── State machine ─────────────────────────────────────────────────────────────
enum State { PATROL, CHASE, RETURN }
var _state: State = State.PATROL

# ── Runtime (assigned by level_01.gd via setup()) ────────────────────────────
var _player: Cat       = null
var _anger_getter: Callable

# ── Facing direction (unit vector, read by vision_cone.gd) ───────────────────
var facing: Vector2 = Vector2.RIGHT

var _patrol_points: Array[Vector2] = []
var _patrol_index: int = 0
var _patrol_dir: int   = 1   # +1 = forward, -1 = backward (ping-pong only)
var _lost_timer: float = 0.0
var _return_target: Vector2

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

func setup(player: Cat, anger_getter: Callable) -> void:
	_player       = player
	_anger_getter = anger_getter

func _physics_process(delta: float) -> void:
	if _player == null:
		return
	match _state:
		State.PATROL: _tick_patrol(delta)
		State.CHASE:  _tick_chase(delta)
		State.RETURN: _tick_return(delta)
	move_and_slide()

# ── Anger helpers ─────────────────────────────────────────────────────────────

func _anger_norm() -> float:
	if not _anger_getter.is_valid():
		return 0.0
	return clamp(_anger_getter.call() / 100.0, 0.0, 1.0)

## Patrol and return get a mild boost — still readable and predictable for the player.
func _patrol_speed_mult() -> float:
	return lerp(1.0, 1.3, _anger_norm())

## Chase speed curve — two linear segments with exact crossover points:
##
##   anger  0 %  →  chase_speed             (default 55 = 25 % of cat)
##   anger 20 %  →  cat_max_speed × 0.50    (110)  equal = 50 % cat
##   anger 60 %  →  cat_max_speed × 1.00    (220)  equal to cat speed
##   anger 100 % →  cat_max_speed × 1.25    (275)  25 % faster than cat
##
## Segment 1 (0 % → 60 %):  lerp( chase_speed, cat_max_speed )
## Segment 2 (60 % → 100 %): lerp( cat_max_speed, cat_max_speed × 1.25 )
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
		velocity = Vector2.ZERO   # brief pause before next leg
	else:
		velocity = to_target.normalized() * (patrol_speed * _patrol_speed_mult())
		_update_facing(velocity)

	if _can_see_player():
		_enter_chase()

## Steps to the next patrol point.
## Ping-pong: reverses direction at each end of the array.
## Loop:      wraps back to index 0 after the last point.
func _advance_patrol_index() -> void:
	if patrol_ping_pong:
		# Flip direction when we hit either end.
		if _patrol_index >= _patrol_points.size() - 1:
			_patrol_dir = -1
		elif _patrol_index <= 0:
			_patrol_dir = 1
		_patrol_index = clamp(_patrol_index + _patrol_dir, 0, _patrol_points.size() - 1)
	else:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()

# ── CHASE ─────────────────────────────────────────────────────────────────────

func _tick_chase(delta: float) -> void:
	var to_player: Vector2 = _player.global_position - global_position

	if to_player.length() > 6.0:
		velocity = to_player.normalized() * _get_chase_speed()
		_update_facing(velocity)
	else:
		velocity = Vector2.ZERO

	if not _can_see_player():
		_lost_timer += delta
		if _lost_timer >= lost_sight_delay:
			_enter_return()
	else:
		_lost_timer = 0.0

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
		_enter_chase()

# ── State transitions ─────────────────────────────────────────────────────────

func _enter_chase() -> void:
	if _state != State.CHASE:
		_state      = State.CHASE
		_lost_timer = 0.0
		detection_started.emit()

func _enter_return() -> void:
	_state         = State.RETURN
	_lost_timer    = 0.0
	_return_target = _patrol_points[_nearest_patrol_index()] \
		if not _patrol_points.is_empty() else global_position

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
		1 << 6   # VisionBlocker layer
	)
	query.exclude = [get_rid()]
	return space.intersect_ray(query).is_empty()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() > 10.0:
		facing = vel.normalized()
		# Do NOT rotate the root node — that would rotate the VisionCone and
		# CatchArea along with it in unexpected ways for pixel art sprites.
		# Instead, forward the velocity to the Visual child so it can flip or
		# switch animations without affecting gameplay nodes.
		var vis := get_node_or_null("Visual")
		if vis != null and vis.has_method("update_direction"):
			vis.call("update_direction", vel)

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
