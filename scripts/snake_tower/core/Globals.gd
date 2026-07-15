extends Node

const TILE_SIZE: int = 16

var total_time_elapsed: float = 0.0
var _is_time_running: bool = false
var current_minigame_level: String = "res://scenes/snake_tower/level/Level1.tscn"

# Dictionary of scenes where time should be tracked
var tracked_scenes: Dictionary = {
	"res://scenes/snake_tower/level/Level1.tscn": true,
	"res://scenes/snake_tower/level/Level2.tscn": true,
	"res://scenes/snake_tower/level/Level3.tscn": true,
	"res://scenes/snake_tower/level/Level4.tscn": true,
	"res://scenes/snake_tower/level/Level5.tscn": true,
	"res://scenes/snake_tower/level/Level6.tscn": true,
	"res://scenes/snake_tower/level/Level7.tscn": true,
	"res://scenes/snake_tower/level/Level8.tscn": true,
	"res://scenes/snake_tower/level/Level9.tscn": true,
	"res://scenes/snake_tower/level/Level10.tscn": true,
	"res://scenes/snake_tower/level/LevelLast.tscn": true,
}

func _ready() -> void:
	# Add to group so LaptopUI can notify all minigames generically
	add_to_group("minigame_time_trackers")
	
	# Ensure the timer can process even when the main game is paused (e.g. by LaptopUI)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if SceneManager:
		SceneManager.scene_loaded.connect(_on_scene_loaded)

func _process(delta: float) -> void:
	if _is_time_running:
		total_time_elapsed += delta

func _on_scene_loaded() -> void:
	var loaded_scene: String = SceneManager._next_scene_path
	# Use dictionary matching or prefix matching for valid minigame scenes
	if tracked_scenes.has(loaded_scene) or loaded_scene.begins_with("res://scenes/snake_tower/level/"):
		if loaded_scene == "res://scenes/snake_tower/level/LevelLast.tscn":
			_is_time_running = false
		else:
			_is_time_running = true
	else:
		_is_time_running = false

func pause_time() -> void:
	_is_time_running = false

func start_time() -> void:
	# If we somehow start time explicitly but we are on LevelLast, don't start
	if SceneManager and SceneManager._next_scene_path == "res://scenes/snake_tower/level/LevelLast.tscn":
		_is_time_running = false
	else:
		_is_time_running = true

func get_next_level(current_scene: String) -> String:
	var levels = tracked_scenes.keys()
	var idx = levels.find(current_scene)
	if idx != -1 and idx + 1 < levels.size():
		return levels[idx + 1]
	return current_scene # Return itself if it's the last level

func update_minigame_level(new_level: String) -> void:
	var levels = tracked_scenes.keys()
	var current_idx = levels.find(current_minigame_level)
	var new_idx = levels.find(new_level)
	if new_idx > current_idx:
		current_minigame_level = new_level

func get_resume_level(requested_scene: String) -> String:
	# If no specific scene is requested, or if the requested scene is part of 
	# the snake tower minigame but older than the current unlocked level,
	# we force it to resume the furthest reached level.
	if requested_scene == "":
		return current_minigame_level
		
	if tracked_scenes.has(requested_scene):
		var levels = tracked_scenes.keys()
		if levels.find(requested_scene) < levels.find(current_minigame_level):
			return current_minigame_level
			
	return requested_scene
