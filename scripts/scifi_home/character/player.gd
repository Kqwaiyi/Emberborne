extends CharacterBody2D

const SPEED := 150.0

@onready var _visual:      Node              = get_node_or_null("Visual")
@onready var _step_audio:  AudioStreamPlayer = $StepAudio

var _step_timer: float = 0.1

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	velocity = dir * SPEED
	if _visual and _visual.has_method("update_direction"):
		_visual.update_direction(velocity)
	move_and_slide()
	_tick_steps(delta)

func _tick_steps(delta: float) -> void:
	if velocity.length() > 20.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_audio.play()
			_step_timer = 0.4
	else:
		_step_audio.stop()
		_step_timer = 0.1
