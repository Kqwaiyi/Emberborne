@tool
extends Node2D

func _ready():
	# Register the y-coordinate (in grid space) to LevelManager
	if not Engine.is_editor_hint():
		LevelManager.death_y = int((position.y / GlobalSnaketower.TILE_SIZE))

func _draw():
	if Engine.is_editor_hint():
		# Draw a red line across the screen to indicate the death floor in the editor
		draw_line(Vector2(-10000, 0), Vector2(10000, 0), Color.RED, 2.0)
