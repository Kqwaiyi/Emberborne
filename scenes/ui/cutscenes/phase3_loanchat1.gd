extends RefCounted
## Phase 3 Loan Chat 1

## Returns metadata about the contact displayed in the header bar.
static func get_sender() -> Dictionary:
	return {
		"name": "LOAN BOT",
		"profile_picture": "res://icons/robot.png"
	}

## Returns the ordered array of message lines for this cutscene.
## "sender": "them" = left-aligned incoming bubble, "me" = right-aligned outgoing bubble.
static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "Your Companion Circuit payment of 5,000 UC is still pending.",
		},
		{
			"sender": "them",
			"text": "An instant loan is available at 5% monthly interest.",
		},
		{
			"sender": "them",
			"text": "Funds will be transferred immediately upon acceptance.",
		}
	]
