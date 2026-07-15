extends Node

const TILE_SIZE: int = 16

var total_time_elapsed: float = 0.0
var _is_time_running: bool = false

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
		_is_time_running = true
	else:
		_is_time_running = false

func pause_time() -> void:
	_is_time_running = false

func start_time() -> void:
	_is_time_running = true
