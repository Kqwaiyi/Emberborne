extends Node2D
class_name Spike

func _ready():
	var grid_pos = Vector2i((position / float(GlobalSnaketower.TILE_SIZE)).round())
	LevelManager.register_cell(grid_pos, LevelManager.CellType.SPIKE, self)
