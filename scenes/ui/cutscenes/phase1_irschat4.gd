extends RefCounted
## Phase 1 IRS Chat 4

static func get_sender() -> Dictionary:
	return {
		"name": "Mom",
		"profile_picture": "res://icons/mom.jpg"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "me",
			"text": "How long can you keep her alive?",
		},
		{
			"sender": "them",
			"text": "Her biometric account contains 30,000 UC... Estimated life-support coverage: 119 days.",
		}
	]
