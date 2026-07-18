extends RefCounted
## Test Dialogue - A sample dialogue sequence for testing the DialogueManager.
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "You",
			"text": "[sz=14]Four months…[/sz]",
			"portrait": "res://icons/you.png"
		},
	]
