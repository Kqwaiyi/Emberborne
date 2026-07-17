## scripts/environment/hiding_spot.gd
## Attach to the HidingSpot root node (StaticBody2D) in hiding_spot.tscn.
## When the cat's body enters HideArea, call cat.enter_hide_zone().
## When it leaves, call cat.leave_hide_zone().
## The counter inside Cat prevents flicker when zones overlap.
extends Node2D

## Opacity hint when no one is hiding (signals the player this is a hiding spot).
@export var alpha_hint: float   = 0.6
## Opacity while the cat is underneath (lets the player see the cat).
@export var alpha_hidden: float = 0.4
## Set true when this node IS the furniture piece (e.g. each ChairHide is its own chair).
## False (default) fades get_parent(), which is correct when this node is embedded inside a table/sofa.
@export var fade_self_only: bool = false

@onready var _hide_area: Area2D = $HideArea

func _ready() -> void:
	_hide_area.body_entered.connect(_on_body_entered)
	_hide_area.body_exited.connect(_on_body_exited)
	_set_furniture_alpha(alpha_hint)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_hide_zone"):
		body.enter_hide_zone()
		_set_furniture_alpha(alpha_hidden)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("leave_hide_zone"):
		body.leave_hide_zone()
		_set_furniture_alpha(alpha_hint)

func _set_furniture_alpha(alpha: float) -> void:
	var target: Node2D = self if fade_self_only else get_parent() as Node2D
	if target:
		target.modulate.a = alpha
