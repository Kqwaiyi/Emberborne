extends Node

@export var cat_game_place: int = 312
@export var snake_tower_place: int = 1

func _ready() -> void:
	print("--- RUNNING ENDING TEST ---")
	print("Cat Game Place: ", cat_game_place)
	print("Snake Tower Place: ", snake_tower_place)
	print("Total Sum: ", cat_game_place + snake_tower_place)
	
	# This will automatically trigger GameGlobal's FINAL state and spawn the UI!
	GameGlobal.set_minigame_finish_place("cat_game", cat_game_place)
	GameGlobal.set_minigame_finish_place("snake_tower", snake_tower_place)
	
	# We optionally change to the map scene to mimic returning from a minigame,
	# but the UI is global so it will show up regardless.
	var scene_mgr = get_node_or_null("/root/SceneManager")
	if scene_mgr and scene_mgr.has_method("change_scene_with_fade"):
		scene_mgr.change_scene_with_fade("res://scenes/scifi_home/the_home/map.tscn", 0.5)
	else:
		get_tree().change_scene_to_file("res://scenes/scifi_home/the_home/map.tscn")
