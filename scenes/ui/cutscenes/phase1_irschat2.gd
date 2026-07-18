extends RefCounted
## Phase 1 IRS Chat 2

static func get_sender() -> Dictionary:
	return {
		"name": "Mom",
		"profile_picture": "res://icons/mom.jpg"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "She is alive, but unconscious.",
		}
	]
