## scripts/characters/human.gd
## Attach to Human root node (CharacterBody2D) in human.tscn.
## Extends EnemyBase; overrides defaults to human values.
## The scene already contains a VisionCone child using vision_cone.gd.
class_name Human
extends EnemyBase

func _ready() -> void:
	patrol_speed = 80.0
	vision_range = 360.0
	vision_angle = 40.0
	# chase_speed and cat_max_speed use the base class defaults (55 and 220).
	super._ready()
