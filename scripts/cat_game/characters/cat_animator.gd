## scripts/characters/cat_animator.gd
## Attach to the Visual (AnimatedSprite2D) node in cat.tscn.
## Adds update_direction(), set_outline(), set_force_run() so cat.gd drives animations.
##
## Expected animation names in the SpriteFrames:
##   walk_left  walk_right  run_left  run_right  idle1  idle2
##
## Run plays ONLY when set_force_run(true) is called (i.e. while tagged).
## Walk plays at all other times regardless of movement speed.
extends AnimatedSprite2D

## Seconds of stillness before a random idle plays. Set to 0 to disable.
@export var idle_delay: float = 1.0

## Per-animation offset so the sprite stays centered over the hitbox.
## +x = right,  -x = left,  +y = down,  -y = up
const ANIM_OFFSETS := {
	"idle1":      Vector2(20, 0),
	"idle2":      Vector2(18, 0),
	"walk_left":  Vector2(17, 0),
	"walk_right": Vector2(0,  0),
	"run_left":   Vector2(10, 0),
	"run_right":  Vector2(4,  0),
}

var _force_run: bool      = false
var _current_anim: String = ""
var _last_h_dir: String   = "right"
var _stopped_time: float  = 0.0

func _ready() -> void:
	_play("walk_right")

func _process(delta: float) -> void:
	if idle_delay > 0.0 and (_current_anim == "" or _current_anim.begins_with("idle")):
		_stopped_time += delta
		if _stopped_time >= idle_delay and _current_anim == "":
			_pick_random_idle()

## Called every physics frame by cat.gd.
func update_direction(vel: Vector2) -> void:
	if vel.length_squared() < 100.0:
		if not (_current_anim == "" or _current_anim.begins_with("idle")):
			_current_anim = ""
			stop()
		return

	_stopped_time = 0.0

	if abs(vel.x) > 10.0:
		_last_h_dir = "right" if vel.x > 0.0 else "left"

	var prefix: String = "run_" if _force_run else "walk_"
	var anim: String   = prefix + _last_h_dir

	if anim != _current_anim:
		_play(anim)

## Called by cat.gd — red tint during invulnerability, white after.
## Preserves current alpha so hiding transparency is not overridden.
func set_outline(is_active: bool) -> void:
	var a: float = modulate.a
	modulate = Color(1.0, 0.3, 0.3, a) if is_active else Color(1.0, 1.0, 1.0, a)

## Called by cat.gd on/off during the speed-boost window after being tagged.
func set_force_run(enabled: bool) -> void:
	if _force_run == enabled:
		return
	_force_run = enabled
	if not _current_anim.begins_with("idle"):
		var prefix: String = "run_" if _force_run else "walk_"
		var anim: String   = prefix + _last_h_dir
		if anim != _current_anim:
			_play(anim)

func _pick_random_idle() -> void:
	if sprite_frames == null:
		return
	var n: int       = randi_range(1, 2)
	var anim: String = "idle" + str(n)
	if not sprite_frames.has_animation(anim):
		return
	_play(anim)

## Central play function — always applies the offset before playing.
func _play(anim: String) -> void:
	_current_anim = anim
	offset = ANIM_OFFSETS.get(anim, Vector2.ZERO)
	play(anim)
