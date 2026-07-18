extends RefCounted
## Phase 3 Loan Dialogue 2
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "You",
			"text": "Three months…",
			"portrait": "res://icons/you.png"
		}
	]
