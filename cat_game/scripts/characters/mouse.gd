## scripts/characters/mouse.gd
## Attach to the Mouse root node (CharacterBody2D) in mouse.tscn.
## Wanders within wander_radius of its spawn position.
## Emits mouse_caught signal when caught; returns point value.
class_name Mouse
extends CharacterBody2D

@export var wander_speed: float           = 45.0
@export var wander_radius: float          = 90.0
@export var minimum_direction_time: float = 0.8
@export var maximum_direction_time: float = 2.0
@export var point_value: int              = 500

signal mouse_caught_signal(points: int)

var can_be_caught: bool  = true
var _spawn_position: Vector2
var _wander_direction: Vector2 = Vector2.ZERO
var _direction_timer: float    = 0.0

@onready var _visual: Node2D = $Visual

func _ready() -> void:
	add_to_group("mouse")
	_spawn_position = global_position
	_pick_new_direction()

func _physics_process(delta: float) -> void:
	if not can_be_caught:
		return

	_direction_timer -= delta
	if _direction_timer <= 0.0:
		_pick_new_direction()

	# Pull back toward spawn if outside radius
	var offset: Vector2 = global_position - _spawn_position
	if offset.length() > wander_radius:
		# Turn back toward spawn
		_wander_direction = -offset.normalized()
		_direction_timer = randf_range(minimum_direction_time, maximum_direction_time)

	velocity = _wander_direction * wander_speed
	move_and_slide()

	# Tell the visual which direction to face.
	if velocity.length_squared() > 10.0 and is_instance_valid(_visual):
		if _visual.has_method("update_direction"):
			_visual.call("update_direction", velocity)
		else:
			_visual.rotation = velocity.angle()

func _pick_new_direction() -> void:
	var angle: float = randf() * TAU
	_wander_direction = Vector2(cos(angle), sin(angle))
	_direction_timer  = randf_range(minimum_direction_time, maximum_direction_time)

## Called by cat.gd when the cat's MouseCatchArea overlaps this body.
## Returns the point value so the caller can emit it.
func catch() -> int:
	if not can_be_caught:
		return 0
	can_be_caught = false
	mouse_caught_signal.emit(point_value)
	# Hide visually before freeing to avoid flicker
	visible = false
	call_deferred("queue_free")
	return point_value
