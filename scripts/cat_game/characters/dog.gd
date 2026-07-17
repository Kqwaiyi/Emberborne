## scripts/characters/dog.gd
## Attach to Dog root node (CharacterBody2D) in dog.tscn.
## Extends EnemyBase; overrides defaults to dog values.
class_name Dog
extends EnemyBase

func _ready() -> void:
	patrol_speed = 95.0
	# vision_range and vision_angle use enemy_base.gd defaults (180 / 55)
	super._ready()
