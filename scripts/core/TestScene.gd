extends Node2D

func _ready():
	print("Test Scene Ready!")
	print("Press '1' to test global transition (0.5s fade).")
	print("Press '2' to test global transition (0.0s fade).")
	print("Press '3' to test LaptopUI transition (0.5s fade).")
	print("Press '4' to test LaptopUI transition (0.0s fade).")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			print("Testing Global SceneManager (0.5s fade)...")
			SceneManager.change_scene_to_file("res://scenes/snake_tower/level/Level1.tscn", 0.5)
			DialogueManager.start_dialogue("res://scenes/ui/dialogues/test_dialogue.gd")
		elif event.keycode == KEY_2:
			print("Testing Global SceneManager (0.0s fade)...")
			SceneManager.change_scene_to_file("res://scenes/snake_tower/level/Level1.tscn", 0.0)
		elif event.keycode == KEY_3:
			print("Testing LaptopUI (0.5s fade)...")
			# Since LaptopUI is not an autoload, we instantiate it here for testing if it's not in the tree
			var laptop_node = get_node_or_null("LaptopUI")
			if laptop_node:
				laptop_node.open_laptop(GlobalSnaketower.get_resume_level("res://scenes/snake_tower/level/Level1.tscn"), 0.5)
			else:
				print("LaptopUI node not found in TestScene!")
		elif event.keycode == KEY_4:
			print("Testing LaptopUI (0.0s fade)...")
			var laptop_node = get_node_or_null("LaptopUI")
			if laptop_node:
				laptop_node.open_laptop(GlobalSnaketower.get_resume_level("res://scenes/snake_tower/level/Level1.tscn"), 0.0)
			else:
				print("LaptopUI node not found in TestScene!")
			DialogueManager.start_dialogue("res://scenes/ui/dialogues/test_dialogue.gd")
		elif event.keycode == KEY_5:
			print("Testing LaptopUI Desktop Screen...")
			var laptop_node = get_node_or_null("LaptopUI")
			if laptop_node:
				laptop_node.open_laptop()
			else:
				print("LaptopUI node not found in TestScene!")
