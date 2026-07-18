extends RefCounted
## Phase 1 IRS Chat 1

static func get_sender() -> Dictionary:
	return {
		"name": "Mom",
		"profile_picture": "res://icons/mom.jpg"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "me",
			"text": "Mum? Where are you?",
		},
		{
			"sender": "them",
			"text": "[IMMEDIATE RESPONSE SYSTEM] This account is currently under emergency medical restriction.",
		},
		{
			"sender": "me",
			"text": "What? Where is she?",
		},
		{
			"sender": "them",
			"text": "At 18:42, your registered guardian was assaulted near Transit Station 14.",
		},
		{
			"sender": "me",
			"text": "Assaulted? By who?",
		},
		{
			"sender": "them",
			"text": "The attacker was suffering cybernetic psychosis after abusing an illegal neural stimulant.",
		},
		{
			"sender": "me",
			"text": "Is she alive?...",
		}
	]
