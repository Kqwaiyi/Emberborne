## scripts/characters/dog_animator.gd
## Attach to the Visual (AnimatedSprite2D) node in dog.tscn.
## Sprites are LEFT-facing by default — flip_h = true when moving right.
## enemy_base.gd calls update_direction(), set_chasing(), set_force_run(), set_barking().
##
## Expected animation names:
##   Walk         — patrolling
##   Walk_chase   — chasing at anger < 60 %
##   Run          — chasing at anger >= 60 %
##   Bark         — after tagging the cat (plays once, then returns to idle)
extends AnimatedSprite2D

var _is_chasing: bool     = false
var _force_run: bool      = false
var _is_barking: bool     = false
var _current_anim: String = ""

func _ready() -> void:
	_play("Walk")

## Called every physics frame by enemy_base.gd.
func update_direction(vel: Vector2) -> void:
	if vel.length_squared() < 10.0:
		return

	# Sprites face LEFT by default. Flip when moving right.
	if abs(vel.x) > 5.0:
		flip_h = vel.x > 0.0

	_refresh_anim()

## Called by enemy_base.gd on _enter_chase() / _enter_return() / back to patrol.
func set_chasing(chasing: bool) -> void:
	if _is_chasing == chasing:
		return
	_is_chasing = chasing
	_refresh_anim()

## Called by enemy_base.gd each frame when anger crosses 60 %.
func set_force_run(enabled: bool) -> void:
	if _force_run == enabled:
		return
	_force_run = enabled
	_refresh_anim()

## Called by enemy_base.gd when the dog tags the cat (true) and when bark ends (false).
func set_barking(barking: bool) -> void:
	_is_barking = barking
	if barking:
		_play("Bark")
	else:
		_refresh_anim()

func _refresh_anim() -> void:
	if _is_barking:
		return
	var anim: String
	if _is_chasing:
		anim = "Run" if _force_run else "Walk_chase"
	else:
		anim = "Walk"
	_play(anim)

func _play(anim: String) -> void:
	if anim == _current_anim:
		return
	_current_anim = anim
	play(anim)
