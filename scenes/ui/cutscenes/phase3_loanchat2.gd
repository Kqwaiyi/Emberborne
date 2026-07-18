extends RefCounted
## Phase 3 Loan Chat 2

static func get_sender() -> Dictionary:
	return {
		"name": "LOAN BOT",
		"profile_picture": "res://icons/robot.png"
	}

static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "5,000 UC TRANSFERRED. TOURNAMENT ENTRY FEE PAID",
		}
	]
