extends Node

var total_score: int = 0
var current_level_scene: String = ""

func add_score(amount: int) -> void:
	total_score += amount

func save_progress(next_scene: String) -> void:
	current_level_scene = next_scene

func reset() -> void:
	total_score = 0
	current_level_scene = ""
