extends Node

enum CellType {
	EMPTY,
	TERRAIN,
	APPLE,
	SPIKE,
	GOAL,
	SNAKE_BODY,
	SNAKE_HEAD
}

var grid: Dictionary = {}
var apple_nodes: Dictionary = {}
var spike_nodes: Dictionary = {}
var goal_node: Node = null

signal level_won
signal level_lost
signal apple_eaten(pos)

func reset():
	grid.clear()
	apple_nodes.clear()
	spike_nodes.clear()
	goal_node = null

func register_cell(pos: Vector2i, type: int, node: Node = null):
	grid[pos] = type
	if type == CellType.APPLE and node:
		apple_nodes[pos] = node
	elif type == CellType.SPIKE and node:
		spike_nodes[pos] = node
	elif type == CellType.GOAL and node:
		goal_node = node

func unregister_cell(pos: Vector2i):
	grid.erase(pos)
	apple_nodes.erase(pos)
	spike_nodes.erase(pos)

func get_cell(pos: Vector2i) -> int:
	if grid.has(pos):
		return grid[pos]
	return CellType.EMPTY

# Apples act as solid blocks until eaten by the head.
func is_solid(pos: Vector2i) -> bool:
	var cell = get_cell(pos)
	return cell == CellType.TERRAIN or cell == CellType.APPLE or cell == CellType.SPIKE or cell == CellType.SNAKE_BODY or cell == CellType.SNAKE_HEAD

func check_support(segments: Array[Vector2i]) -> bool:
	# A snake is supported if ANY segment is resting on a harmless solid block (TERRAIN, APPLE)
	# Spikes DO NOT act as harmless support.
	for segment in segments:
		var below = segment + Vector2i(0, 1)
		var cell = get_cell(below)
		if cell == CellType.TERRAIN or cell == CellType.APPLE:
			return true
	return false

# Check if snake will die due to gravity landing
func check_gravity_death(segments: Array[Vector2i]) -> bool:
	# If falling, does any segment land on a spike?
	for segment in segments:
		var below = segment + Vector2i(0, 1)
		var cell = get_cell(below)
		if cell == CellType.SPIKE:
			return true
	return false

# Is a specific position a spike? (Used for head collision)
func is_spike(pos: Vector2i) -> bool:
	return get_cell(pos) == CellType.SPIKE

func is_goal(pos: Vector2i) -> bool:
	return get_cell(pos) == CellType.GOAL

func consume_apple(pos: Vector2i):
	if apple_nodes.has(pos):
		var apple = apple_nodes[pos]
		apple.eat()
		unregister_cell(pos)
		apple_eaten.emit()

func trigger_win():
	level_won.emit()

func trigger_loss():
	level_lost.emit()
