extends Node2D

var _is_transitioning: bool = false

func _enter_tree():
	LevelManager.reset()

func _ready():
	# Start the timer whenever a level is loaded (handles direct editor runs)
	get_tree().call_group("minigame_time_trackers", "start_time")
	
	LevelManager.level_won.connect(_on_level_won)
	LevelManager.level_lost.connect(_on_level_lost)

func _on_level_won():
	if _is_transitioning: return
	_is_transitioning = true
	print("Level Won!")
	var next_level = Globals.get_next_level(scene_file_path)
	if next_level != "":
		Globals.update_minigame_level(next_level)
		_switch_level(next_level)
	else:
		print("You beat the game!")
		_reload_level()

func _switch_level(target_scene: String):
	var vp = get_viewport()
	if vp is SubViewport:
		SceneManager.change_scene_in_viewport(target_scene, vp, 0.5)
	else:
		SceneManager.change_scene_to_file(target_scene)

func _on_level_lost():
	if _is_transitioning: return
	_is_transitioning = true
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
