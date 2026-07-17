extends Node

enum CellType {
	EMPTY,
	TERRAIN,
	APPLE,
	SPIKE,
	GOAL,
	SNAKE_BODY,
	SNAKE_HEAD,
	BOX
}

var grid: Dictionary = {}
var apple_nodes: Dictionary = {}
var spike_nodes: Dictionary = {}
var box_nodes: Dictionary = {}
var goal_node: Node = null
var death_y: int = 100
var camera_limit_y: int = -1
signal level_won
signal level_lost
signal apple_eaten(pos)

func _enter_tree():
	reset()

func reset():
	grid.clear()
	apple_nodes.clear()
	spike_nodes.clear()
	box_nodes.clear()
	goal_node = null
	death_y = 100
	camera_limit_y = -1

func register_cell(pos: Vector2i, type: int, node: Node = null):
	grid[pos] = type
	if type == CellType.APPLE and node:
		apple_nodes[pos] = node
	elif type == CellType.SPIKE and node:
		spike_nodes[pos] = node
	elif type == CellType.GOAL and node:
		goal_node = node
	elif type == CellType.BOX and node:
		box_nodes[pos] = node

func unregister_cell(pos: Vector2i, type: int = -1):
	var actual_type = get_cell(pos)
	if type != -1 and actual_type != type:
		return
		
	grid.erase(pos)
	if actual_type == CellType.APPLE:
		apple_nodes.erase(pos)
	elif actual_type == CellType.SPIKE:
		spike_nodes.erase(pos)
	elif actual_type == CellType.BOX:
		box_nodes.erase(pos)

func get_cell(pos: Vector2i) -> int:
	if grid.has(pos):
		return grid[pos]
	return CellType.EMPTY

func get_box(pos: Vector2i) -> Node:
	if box_nodes.has(pos):
		return box_nodes[pos]
	return null

# Apples act as solid blocks until eaten by the head.
func is_solid(pos: Vector2i) -> bool:
	var cell = get_cell(pos)
	return cell == CellType.TERRAIN or cell == CellType.APPLE or cell == CellType.SPIKE or cell == CellType.SNAKE_BODY or cell == CellType.SNAKE_HEAD or cell == CellType.BOX

func check_support(segments: Array[Vector2i]) -> bool:
	# A snake is supported if ANY segment is resting on a harmless solid block (TERRAIN, APPLE, BOX)
	# Spikes DO NOT act as harmless support.
	for segment in segments:
		var below = segment + Vector2i(0, 1)
		var cell = get_cell(below)
		if cell == CellType.TERRAIN or cell == CellType.APPLE or cell == CellType.BOX:
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

# Check if snake will win due to gravity landing
func check_gravity_win(segments: Array[Vector2i]) -> bool:
	for segment in segments:
		var below = segment + Vector2i(0, 1)
		var cell = get_cell(below)
		if cell == CellType.GOAL:
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
		unregister_cell(pos, CellType.APPLE)
		apple_eaten.emit()

func trigger_win():
	level_won.emit()

func trigger_loss():
	level_lost.emit()
