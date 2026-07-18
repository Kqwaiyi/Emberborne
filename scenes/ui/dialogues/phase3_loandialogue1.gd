extends RefCounted
## Phase 3 Loan Dialogue 1
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "You",
			"text": "Five percent...",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[i]The registration expires tonight.[/i]",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "…",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[sh]I’ll find a way to repay it.[/sh]",
			"portrait": "res://icons/you.png"
		}
	]
