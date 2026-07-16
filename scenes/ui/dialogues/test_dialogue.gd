extends RefCounted
## Test Dialogue - A sample dialogue sequence for testing the DialogueManager.
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "Elder",
			"text": "Welcome, brave adventurer, to the land of Emberborne.",
			"portrait": "res://assets/sprites/portraits/portrait_template.png"
		},
		{
			"speaker": "Elder",
			"text": "The ancient flames have begun to stir once more... darkness creeps from the north.",
			"portrait": "res://assets/sprites/portraits/portrait_template.png"
		},
		{
			"speaker": "???",
			"text": "You feel a strange warmth in your chest, as if something within you has awakened.",
			"portrait": ""
		},
		{
			"speaker": "Elder",
			"text": "Seek the Ember Shrine to the north. Your journey begins there.",
			"portrait": "res://assets/sprites/portraits/portrait_template.png"
		},
	]
