extends Node

var minigame_finishes: Dictionary = {}
var snaketower_final_place: int = 0

func set_minigame_finish_place(minigame_name: String, place: int) -> void:
	minigame_finishes[minigame_name] = place

func get_minigame_finish_place(minigame_name: String) -> int:
	return minigame_finishes.get(minigame_name, 0)
