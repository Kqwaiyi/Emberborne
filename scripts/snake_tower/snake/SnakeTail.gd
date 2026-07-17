extends Node2D
class_name SnakeTail

var grid_position: Vector2i

func _ready():
	if not is_in_group("snake_tail"):
		add_to_group("snake_tail")
		
	# Initial position to grid, read by Snake.gd for editor-placed tails
	grid_position = Vector2i((global_position / float(Globals.TILE_SIZE)).round())
