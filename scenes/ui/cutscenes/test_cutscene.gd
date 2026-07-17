extends RefCounted
## Test Cutscene - A sample texting cutscene for testing the CutsceneMessenger.
##
## To create a new cutscene, copy this file and modify get_sender() and get_lines().
## Then add the path to CUTSCENE_PATHS in CutsceneMessenger.gd and call:
##     open_scene("your_key")

## Returns metadata about the contact displayed in the header bar.
static func get_sender() -> Dictionary:
	return {
		"name": "Agent Voss",
		"profile_picture": "res://assets/sprites/messenger/pfp_placeholder.png"
	}

## Returns the ordered array of message lines for this cutscene.
## "sender": "them" = left-aligned incoming bubble, "me" = right-aligned outgoing bubble.
static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "We've intercepted a signal from Sector 7. Are you in position?",
		},
		{
			"sender": "me",
			"text": "Copy. Moving to intercept now.",
		},
		{
			"sender": "them",
			"text": "Be careful out there. The last team we sent didn't make it back.",
		},
		{
			"sender": "me",
			"text": "Understood. I'll proceed with caution.",
		},
		{
			"sender": "them",
			"text": "Intel suggests heavy resistance near the perimeter. Watch for drones.",
		},
		{
			"sender": "them",
			"text": "We're routing encrypted coordinates to your device now.",
		},
		{
			"sender": "me",
			"text": "Coordinates received. ETA 5 minutes.",
		},
		{
			"sender": "them",
			"text": "Good luck, operative. Command out.",
		},
	]
