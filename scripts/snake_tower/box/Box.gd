extends Node2D
class_name Box

var grid_pos: Vector2i
var is_falling: bool = false
var fall_timer: float = 0.0
var fall_interval: float = 0.07

func _ready():
	grid_pos = Vector2i((position / float(Globals.TILE_SIZE)).round())
	# Snap to precise grid position
	position = Vector2(grid_pos) * Globals.TILE_SIZE
	call_deferred("_deferred_init")

func _deferred_init():
	LevelManager.register_cell(grid_pos, LevelManager.CellType.BOX, self)

func try_push(dir: Vector2i) -> bool:
	var target = grid_pos + dir
	if LevelManager.get_cell(target) == LevelManager.CellType.EMPTY:
		LevelManager.unregister_cell(grid_pos, LevelManager.CellType.BOX)
		grid_pos = target
		position = Vector2(grid_pos) * Globals.TILE_SIZE
		LevelManager.register_cell(grid_pos, LevelManager.CellType.BOX, self)
		check_gravity()
		return true
	return false

func _process(delta):
	check_gravity()
	if is_falling:
		fall_timer += delta
		if fall_timer >= fall_interval:
			# Extra safety check before taking the physical step
			var below = grid_pos + Vector2i(0, 1)
			if LevelManager.get_cell(below) == LevelManager.CellType.EMPTY:
				fall_timer = 0.0
				do_fall_step()
			else:
				is_falling = false
				fall_timer = 0.0

func check_gravity():
	var below = grid_pos + Vector2i(0, 1)
	var cell = LevelManager.get_cell(below)
	
	# The box rests safely on EVERYTHING (Terrain, Apple, Spike, Goal, Snake, Box)
	# It only falls if the cell exactly below it is completely EMPTY.
	if cell == LevelManager.CellType.EMPTY:
		is_falling = true
		if fall_timer == 0.0:
			fall_timer = 0.0
	else:
		is_falling = false
		fall_timer = 0.0

func do_fall_step():
	LevelManager.unregister_cell(grid_pos, LevelManager.CellType.BOX)
	grid_pos += Vector2i(0, 1)
	position = Vector2(grid_pos) * Globals.TILE_SIZE
	LevelManager.register_cell(grid_pos, LevelManager.CellType.BOX, self)
	check_gravity()
