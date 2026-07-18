extends RefCounted

static func get_sender() -> Dictionary:
	return {
		"name": "Agent Voss",
		"profile_picture": "res://assets/sprites/messenger/pfp_placeholder.png"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "Are you at the rendezvous point?",
		},
		{
			"sender": "me",
			"text": "Affirmative. I'm in position. Waiting for the target.",
		},
		{
			"sender": "them",
			"text": "Target is approaching from the north. Armed and dangerous.",
		},
		{
			"sender": "them",
			"text": "Do not engage unless fired upon. We need them alive for questioning.",
		},
		{
			"sender": "me",
			"text": "Understood. I have visual.",
		}
	]
