extends Node

var total_score: int = 0

func add_score(amount: int) -> void:
	total_score += amount

func reset() -> void:
	total_score = 0
