extends RefCounted
## Test Dialogue - A sample dialogue sequence for testing the DialogueManager.
##
## To create a new dialogue, copy this file and modify get_lines().
## Then call: DialogueManager.start_dialogue("res://scenes/ui/dialogues/your_file.gd")

static func get_lines() -> Array:
	return [
		{
			"speaker": "You",
			"text": "[i]Finally…[/i]",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "Twelve hours reviewing rejected claims, and somehow [b]I’m[/b] the one getting blamed because the system [i]missed its quota[/i].",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[sz=14][i]Like I make any of the decisions…[/i][/sz]",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[b]Mom?[/b]",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "Her shoes are gone…",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "No message. No missed calls",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "What could have happened? I mean Maybe her brainchip lost connection Or her shift ran late. That happens.",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[i]mom…[/i]",
			"portrait": "res://icons/you.png"
		},
		{
			"speaker": "You",
			"text": "[sh]Something’s wrong.[/sh]",
			"portrait": "res://icons/you.png"
		}
	]
