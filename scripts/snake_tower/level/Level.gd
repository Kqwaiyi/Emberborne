extends Node2D

var _is_transitioning: bool = false
var time_label: Label = null

func _enter_tree():
	LevelManager.reset()

func _ready():
	# Start the timer whenever a level is loaded (handles direct editor runs)
	get_tree().call_group("minigame_time_trackers", "start_time")
	
	LevelManager.level_won.connect(_on_level_won)
	LevelManager.level_lost.connect(_on_level_lost)
	
	if scene_file_path != "res://scenes/snake_tower/level/Level1.tscn" and scene_file_path != "res://scenes/snake_tower/level/LevelLast.tscn":
		var ui_layer = get_node_or_null("UILayer")
		if ui_layer:
			time_label = Label.new()
			ui_layer.add_child(time_label)
			time_label.position = Vector2(12.3076935, 50.0)
			time_label.scale = Vector2(0.25, 0.25)
			time_label.add_theme_font_size_override("font_size", 64)

func _process(_delta):
	if time_label != null:
		var total_seconds = Globals.total_time_elapsed
		var minutes = int(total_seconds) / 60
		var seconds = int(total_seconds) % 60
		var milliseconds = int((total_seconds - int(total_seconds)) * 100)
		time_label.text = "Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds]

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
		var custom_rect: ColorRect = null
		if vp.get_parent() and vp.get_parent().get_parent():
			custom_rect = vp.get_parent().get_parent().get_node_or_null("TransitionRect")
		SceneManager.change_scene_in_viewport(target_scene, vp, custom_rect, 0.5)
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
		var custom_rect: ColorRect = null
		if vp.get_parent() and vp.get_parent().get_parent():
			custom_rect = vp.get_parent().get_parent().get_node_or_null("TransitionRect")
		SceneManager.change_scene_in_viewport(scene_file_path, vp, custom_rect, 0.5)
	else:
		get_tree().reload_current_scene()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_level()
