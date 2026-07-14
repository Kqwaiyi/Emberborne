## scripts/environment/hiding_spot.gd
## Attach to the HidingSpot root node (StaticBody2D) in hiding_spot.tscn.
## When the cat's body enters HideArea, call cat.enter_hide_zone().
## When it leaves, call cat.leave_hide_zone().
## The counter inside Cat prevents flicker when zones overlap.
extends Node2D

@onready var _hide_area: Area2D = $HideArea

func _ready() -> void:
	_hide_area.body_entered.connect(_on_body_entered)
	_hide_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_hide_zone"):
		body.enter_hide_zone()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("leave_hide_zone"):
		body.leave_hide_zone()
