extends Node2D

func _enter_tree():
	LevelManager.reset()

func _ready():
	LevelManager.level_won.connect(_on_level_won)
	LevelManager.level_lost.connect(_on_level_lost)

func _on_level_won():
	print("Level Won!")
	get_tree().reload_current_scene()

func _on_level_lost():
	print("Level Lost! Restarting...")
	get_tree().reload_current_scene()
