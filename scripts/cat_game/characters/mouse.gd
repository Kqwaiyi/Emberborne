## scripts/characters/mouse.gd
## Attach to the Mouse root node (CharacterBody2D) in mouse.tscn.
## Follows a patrol route defined by a PatrolRoutes/Route/Marker2D hierarchy.
## Emits mouse_caught_signal when caught; returns point value.
class_name Mouse
extends CharacterBody2D

@export var patrol_speed: float   = 45.0
@export var patrol_route: NodePath
@export var patrol_ping_pong: bool = true
@export var point_value: int       = 500

signal mouse_caught_signal(points: int)

var can_be_caught: bool = true

var _patrol_points: Array[Vector2] = []
var _patrol_index: int = 0
var _patrol_dir: int   = 1

@onready var _visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("mouse")
	if patrol_route != NodePath(""):
		var route: Node = get_node_or_null(patrol_route)
		if route != null:
			for child in route.get_children():
				if child is Marker2D:
					_patrol_points.append(child.global_position)
	if _patrol_points.is_empty():
		push_warning(name + ": no patrol points found — rat will stand still.")

func _physics_process(_delta: float) -> void:
	if not can_be_caught:
		return
	if _patrol_points.size() < 2:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2    = _patrol_points[_patrol_index]
	var to_target: Vector2 = target - global_position

	if to_target.length() < 8.0:
		_advance_index()
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * patrol_speed

	move_and_slide()

	if velocity.length_squared() > 10.0 and is_instance_valid(_visual):
		if _visual.has_method("update_direction"):
			_visual.call("update_direction", velocity)
		else:
			_visual.rotation = velocity.angle()

func _advance_index() -> void:
	if patrol_ping_pong:
		if _patrol_index >= _patrol_points.size() - 1:
			_patrol_dir = -1
		elif _patrol_index <= 0:
			_patrol_dir = 1
		_patrol_index = clamp(_patrol_index + _patrol_dir, 0, _patrol_points.size() - 1)
	else:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()

## Called by cat.gd when the cat's MouseCatchArea overlaps this body.
func catch() -> int:
	if not can_be_caught:
		return 0
	can_be_caught = false
	mouse_caught_signal.emit(point_value)
	visible = false
	call_deferred("queue_free")
	return point_value
