extends RefCounted
## Phase 1 IRS Chat 3

static func get_sender() -> Dictionary:
	return {
		"name": "Mom",
		"profile_picture": "res://icons/mom.jpg"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "She has severe cranial trauma and internal bleeding. Immediate surgery requires payment of 250,000 UC.",
		}
	]
