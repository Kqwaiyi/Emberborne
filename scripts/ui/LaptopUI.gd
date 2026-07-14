extends CanvasLayer

signal opened
signal closed

@onready var viewport = $CenterContainer/Panel/SubViewportContainer/SubViewport
@onready var close_button = $CenterContainer/Panel/CloseButton

func _ready():
	# Ensure the UI can process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect the close button
	close_button.pressed.connect(close_laptop)
	
	# Start hidden
	hide()

func open_laptop(minigame_scene_path: String = ""):
	show()
	# Pause the main game
	get_tree().paused = true
	
	# Load the minigame if a path is provided
	if minigame_scene_path != "":
		load_minigame(minigame_scene_path)
		
	opened.emit()

func close_laptop():
	hide()
	# Unpause the main game
	get_tree().paused = false
	
	# Optional: Clear the viewport when closed to free memory and reset state
	clear_minigame()
	
	closed.emit()

func load_minigame(path: String):
	# Use the global SceneManager to fade out the screen, load the new minigame into the viewport, and fade in
	SceneManager.change_scene_in_viewport(path, viewport, 0.5)

func clear_minigame():
	for child in viewport.get_children():
		child.queue_free()

func load_next_level(next_level_path: String):
	# Helper function that the minigame can call to auto-increment levels
	# e.g., get_node("/root/LaptopUI").load_next_level("...")
	load_minigame(next_level_path)
