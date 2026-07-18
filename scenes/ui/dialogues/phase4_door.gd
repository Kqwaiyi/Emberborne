extends RefCounted
## Phase 4 Door Dialogue
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "You",
			"text": "cant believe its been >3 months<",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "hooh, lets get this over with",
			"portrait": "res://icons/you.png"
		}
	]
