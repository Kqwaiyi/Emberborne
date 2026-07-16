## scripts/characters/cat_visual.gd
## Attach to the Visual node (Node2D) inside cat.tscn.
##
## PLACEHOLDER MODE  (use_placeholder = true, default)
##   Draws the same blue square + yellow nose. No sprite needed.
##
## SPRITE MODE  (use_placeholder = false)
##   Add an AnimatedSprite2D child named "Sprite" to this node.
##   Give its SpriteFrames resource these animation names:
##     idle
##     walk_right  walk_left  walk_up  walk_down
##   Set use_placeholder = false in the Inspector to activate.
extends Node2D

## Flip this to false in the Inspector once your AnimatedSprite2D is ready.
@export var use_placeholder: bool = true

# Placeholder colours
const BODY_COLOR  := Color(0.18, 0.42, 0.90, 1.0)
const NOSE_COLOR  := Color(1.00, 0.75, 0.00, 1.0)
const OUTLINE_CLR := Color(1.00, 0.10, 0.10, 1.0)

var _sprite: AnimatedSprite2D = null
var _last_dir: String = "right"
var _show_outline: bool = false

func _ready() -> void:
	_sprite = get_node_or_null("Sprite") as AnimatedSprite2D

# ── Called by cat.gd every physics frame ─────────────────────────────────────

## Drive direction and animation from the cat's current velocity.
func update_direction(vel: Vector2) -> void:
	if use_placeholder or _sprite == null:
		# Placeholder: just rotate this node toward velocity.
		if vel.length_squared() > 100.0:
			rotation = vel.angle()
		queue_redraw()
		return

	if vel.length_squared() > 100.0:
		var dir: String = _vec_to_dir(vel)
		_last_dir = dir
		var anim: String = "walk_" + dir
		if _sprite.animation != anim:
			_sprite.play(anim)
	else:
		# Stopped — play idle if the animation exists, otherwise stop.
		if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("idle"):
			if _sprite.animation != "idle":
				_sprite.play("idle")
		else:
			_sprite.stop()

## Show or hide the red caught outline.
func set_outline(visible_flag: bool) -> void:
	_show_outline = visible_flag
	if _sprite != null and not use_placeholder:
		var a: float = _sprite.modulate.a
		_sprite.modulate = Color(1.0, 0.3, 0.3, a) if visible_flag else Color(1.0, 1.0, 1.0, a)
	else:
		queue_redraw()   # redraw the placeholder outline

# ── Placeholder drawing ───────────────────────────────────────────────────────

func _draw() -> void:
	if not use_placeholder:
		return
	# Blue body square
	draw_rect(Rect2(-12.0, -12.0, 24.0, 24.0), BODY_COLOR)
	# Yellow direction indicator (points +X, rotated by this node)
	draw_colored_polygon(
		PackedVector2Array([Vector2(16, 0), Vector2(8, -5), Vector2(8, 5)]),
		NOSE_COLOR
	)
	if _show_outline:
		draw_rect(Rect2(-14.0, -14.0, 28.0, 28.0), OUTLINE_CLR, false, 3.0)

# ── Shared utility ────────────────────────────────────────────────────────────

## Convert a velocity vector to one of four direction strings.
func _vec_to_dir(vel: Vector2) -> String:
	var a: float = vel.angle()   # radians; 0 = right, PI/2 = down
	if abs(a) <= PI * 0.25:
		return "right"
	elif a > PI * 0.25 and a < PI * 0.75:
		return "down"
	elif abs(a) >= PI * 0.75:
		return "left"
	else:
		return "up"
