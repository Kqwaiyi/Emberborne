extends Node2D

func _ready() -> void:
	if GameState.current_level_scene.is_empty():
		return
	call_deferred("_swap_to_saved_level")

func _swap_to_saved_level() -> void:
	var old := get_node_or_null("Level01")
	if old:
		old.free()
	var packed: PackedScene = load(GameState.current_level_scene)
	if packed:
		add_child(packed.instantiate())
