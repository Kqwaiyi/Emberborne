## scripts/characters/enemy_animator.gd
## Attach to the Visual node (Node2D) inside human.tscn and dog.tscn.
##
## PLACEHOLDER MODE  (use_placeholder = true, default)
##   Does nothing — the ColorRect body is already a child of Visual,
##   and enemy_base.gd still draws it via the placeholder ColorRect.
##
## SPRITE MODE  (use_placeholder = false)
##   1. Delete the ColorRect "Body" child from Visual.
##   2. Add an AnimatedSprite2D child named "Sprite" to Visual.
##   3. Give its SpriteFrames these animation names:
##        idle
##        walk_right  walk_left  walk_up  walk_down
##   4. Set use_placeholder = false in the Inspector.
extends Node2D

@export var use_placeholder: bool = true

var _sprite: AnimatedSprite2D = null
var _last_dir: String = "right"

func _ready() -> void:
	_sprite = get_node_or_null("Sprite") as AnimatedSprite2D

## Called by enemy_base.gd via _update_facing() each frame.
func update_direction(vel: Vector2) -> void:
	if use_placeholder or _sprite == null:
		return

	if vel.length_squared() > 100.0:
		var dir: String = _vec_to_dir(vel)
		_last_dir = dir
		var anim: String = "walk_" + dir
		if _sprite.animation != anim:
			_sprite.play(anim)
	else:
		if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("idle"):
			if _sprite.animation != "idle":
				_sprite.play("idle")
		else:
			_sprite.stop()

func _vec_to_dir(vel: Vector2) -> String:
	var a: float = vel.angle()
	if abs(a) <= PI * 0.25:
		return "right"
	elif a > PI * 0.25 and a < PI * 0.75:
		return "down"
	elif abs(a) >= PI * 0.75:
		return "left"
	else:
		return "up"
