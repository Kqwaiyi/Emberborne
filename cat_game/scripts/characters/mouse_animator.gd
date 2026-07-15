## scripts/characters/mouse_animator.gd
## Attach to the Visual (AnimatedSprite2D) node in mouse.tscn.
## Flips the sprite horizontally based on movement direction.
##
## Expected animation name: walk
extends AnimatedSprite2D

func _ready() -> void:
	play("walk")

## Called every physics frame by mouse.gd.
func update_direction(vel: Vector2) -> void:
	if vel.length_squared() < 10.0:
		stop()
		return
	if abs(vel.x) > 5.0:
		flip_h = vel.x < 0.0
	if not is_playing():
		play("walk")
