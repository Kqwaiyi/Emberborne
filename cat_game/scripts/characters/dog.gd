## scripts/characters/dog.gd
## Attach to Dog root node (CharacterBody2D) in dog.tscn.
## Extends EnemyBase; overrides defaults to dog values.
class_name Dog
extends EnemyBase

func _ready() -> void:
	patrol_speed = 95.0
	vision_range = 240.0
	vision_angle = 90.0
	# chase_speed uses the base class default (55).
	# The dog feels faster because patrol_speed is higher and vision_angle is wider.
	super._ready()
