extends Node2D
class_name GoalFlag

func _ready():
	var grid_pos = Vector2i((position / float(GlobalSnaketower.TILE_SIZE)).round())
	LevelManager.register_cell(grid_pos, LevelManager.CellType.GOAL, self)
