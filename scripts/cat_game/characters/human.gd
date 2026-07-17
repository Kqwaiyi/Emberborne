## scripts/characters/human.gd
## Attach to Human root node (CharacterBody2D) in human.tscn.
## Extends EnemyBase; overrides defaults to human values.
## The scene already contains a VisionCone child using vision_cone.gd.
class_name Human
extends EnemyBase

func _ready() -> void:
	patrol_speed = 95.0    # same as dog
	vision_range = 240.0   # slightly further than dog (180)
	vision_angle = 55.0    # same cone width as dog
	super._ready()

func _sync_run_animation() -> void:
	pass  # humans always walk — speed increases but animation stays walk
