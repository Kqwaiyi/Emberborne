extends CharacterBody2D

const ANIMS: Array[String] = ["run", "idle", "celebration", "sleep"]
const MOVE_SPEED := 80.0

@export var bounds_min: Vector2 = Vector2(-80, -50)
@export var bounds_max: Vector2 = Vector2(80, 50)
@export var state_duration_min: float = 2.0
@export var state_duration_max: float = 5.0

@onready var _visual: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _initial_pos: Vector2
var _target: Vector2
var _moving := false
var _timer  := 0.0

func _ready() -> void:
	_initial_pos = position
	_target = position
	_next_state()

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_next_state()

	if _moving:
		var diff := _target - position
		if diff.length() < 4.0:
			position = _target
			velocity = Vector2.ZERO
			_moving = false
			_next_state()
		else:
			velocity = diff.normalized() * MOVE_SPEED
			if _visual:
				_visual.flip_h = diff.x < 0.0
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _next_state() -> void:
	var anim: String = ANIMS[randi() % ANIMS.size()]
	_timer = randf_range(state_duration_min, state_duration_max)
	if _visual and _visual.sprite_frames and _visual.sprite_frames.has_animation(anim):
		_visual.play(anim)
	if anim == "run":
		_moving = true
		_target = _initial_pos + Vector2(
			randf_range(bounds_min.x, bounds_max.x),
			randf_range(bounds_min.y, bounds_max.y)
		)
	else:
		_moving = false
