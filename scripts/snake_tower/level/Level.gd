extends Node2D

func _enter_tree():
	LevelManager.reset()

func _ready():
	# Start the timer whenever a level is loaded (handles direct editor runs)
	get_tree().call_group("minigame_time_trackers", "start_time")
	
	LevelManager.level_won.connect(_on_level_won)
	LevelManager.level_lost.connect(_on_level_lost)

func _on_level_won():
	print("Level Won!")
	_reload_level()

func _on_level_lost():
	print("Level Lost! Restarting...")
	_reload_level()

func reset_level():
	print("Manual Reset!")
	_reload_level()

func _reload_level():
	var vp = get_viewport()
	if vp is SubViewport:
		SceneManager.change_scene_in_viewport(scene_file_path, vp, 0.5)
	else:
		get_tree().reload_current_scene()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_level()
