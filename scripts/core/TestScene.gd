extends Node2D

func _ready():
	print("Test Scene Ready!")
	print("Press '1' to test global SceneManager transition to Level 1.")
	print("Press '2' to test LaptopUI minigame transition.")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			print("Testing Global SceneManager...")
			SceneManager.change_scene_to_file("res://scenes/snake_tower/level/Level1.tscn")
		elif event.keycode == KEY_2:
			print("Testing LaptopUI...")
			# Since LaptopUI is not an autoload, we instantiate it here for testing if it's not in the tree
			var laptop_node = get_node_or_null("LaptopUI")
			if laptop_node:
				laptop_node.open_laptop(Globals.get_resume_level("res://scenes/snake_tower/level/Level1.tscn"))
			else:
				print("LaptopUI node not found in TestScene!")
