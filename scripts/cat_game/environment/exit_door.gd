## scripts/environment/exit_door.gd
## Attach to the ExitDoor root node (Area2D) in exit_door.tscn.
## Emits exit_attempted or level_completed depending on mouse count.
## The level script decides which signal to act on.
class_name ExitDoor
extends Area2D

signal exit_attempted()
signal level_completed()

## Set by level_01.gd when the required count is reached.
var is_active: bool = false

## Prevent message spam when standing in door area.
var _cooldown: float = 0.0
const MESSAGE_COOLDOWN: float = 2.5

@onready var _visual: ColorRect = $Visual

func _ready() -> void:
	add_to_group("exit_door")
	body_entered.connect(_on_body_entered)
	_refresh_visual()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

func activate() -> void:
	is_active = true
	_refresh_visual()

func _refresh_visual() -> void:
	if _visual == null:
		return
	_visual.color = Color(0.0, 0.75, 0.2, 0.9) if is_active else Color(0.55, 0.05, 0.05, 0.9)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if is_active:
		level_completed.emit()
	else:
		if _cooldown <= 0.0:
			_cooldown = MESSAGE_COOLDOWN
			exit_attempted.emit()
