extends CharacterBody2D

const SPEED := 150.0

@onready var _visual = get_node_or_null("Visual")

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	velocity = dir * SPEED
	if _visual and _visual.has_method("update_direction"):
		_visual.update_direction(velocity)
	move_and_slide()
