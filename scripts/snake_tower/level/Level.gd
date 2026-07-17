extends Node2D

var _is_transitioning: bool = false
var time_label: Label = null
@export var home_scene_path: String = "res://scenes/snake_tower/level/Level1.tscn"

func _enter_tree():
	LevelManager.reset()

func _ready():
	MusicManager.play_music("minigame_bgm", true)
	# Start the timer whenever a level is loaded (handles direct editor runs)
	get_tree().call_group("minigame_time_trackers", "start_time")
	
	LevelManager.level_won.connect(_on_level_won)
	LevelManager.level_lost.connect(_on_level_lost)
	
	var ui_layer = get_node_or_null("UILayer")
	if ui_layer:
		if scene_file_path != "res://scenes/snake_tower/level/Level1.tscn" and scene_file_path != "res://scenes/snake_tower/level/LevelLast.tscn":
			time_label = Label.new()
			ui_layer.add_child(time_label)
			time_label.position = Vector2(12.3076935, 50.0)
			time_label.scale = Vector2(0.25, 0.25)
			time_label.add_theme_font_size_override("font_size", 64)

func _process(_delta):
	if time_label != null:
		var total_seconds = GlobalSnaketower.total_time_elapsed + GlobalSnaketower.current_level_time
		var minutes = int(total_seconds) / 60
		var seconds = int(total_seconds) % 60
		var milliseconds = int((total_seconds - int(total_seconds)) * 100)
		time_label.text = "Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds]

func _on_level_won():
	if _is_transitioning: return
	_is_transitioning = true
	print("Level Won!")
	GlobalSnaketower.commit_time()
	var next_level = GlobalSnaketower.get_next_level(scene_file_path)
	if next_level != "":
		GlobalSnaketower.update_minigame_level(next_level)
		_switch_level(next_level)
	else:
		print("You beat the game!")
		_reload_level()

func _get_laptop_ui() -> Node:
	var laptops = get_tree().get_nodes_in_group("laptop_ui")
	if laptops.size() > 0:
		return laptops[0]
	return null

func _switch_level(target_scene: String):
	var laptop = _get_laptop_ui()
	if laptop:
		laptop.change_scene(target_scene, 0.5)
	else:
		SceneManager.change_scene_to_file(target_scene)

func _on_level_lost():
	if _is_transitioning: return
	_is_transitioning = true
	print("Level Lost! Restarting...")
	_reload_level()

func reset_level():
	print("Manual Reset!")
	var snake = get_tree().get_first_node_in_group("snake")
	if snake and snake.has_node("DieAudio"):
		snake.get_node("DieAudio").play()
	_reload_level()

func _reload_level():
	var laptop = _get_laptop_ui()
	if laptop:
		laptop.change_scene(scene_file_path, 0.5)
	else:
		get_tree().reload_current_scene()

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_level()

func return_to_home():
	if _is_transitioning: return
	_is_transitioning = true
	GlobalSnaketower.reset_attempt_timer()
	MusicManager.play_music("pet_home", true)
	_switch_level(home_scene_path)
