extends Area2D

@export var next_scene_path: String = "res://scenes/core/TestScene.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		get_tree().change_scene_to_file(next_scene_path)
