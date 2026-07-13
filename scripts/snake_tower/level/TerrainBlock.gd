extends Node2D
class_name TerrainBlock

func _ready():
	var grid_pos = Vector2i((position / float(Globals.TILE_SIZE)).round())
	LevelManager.register_cell(grid_pos, LevelManager.CellType.TERRAIN)
