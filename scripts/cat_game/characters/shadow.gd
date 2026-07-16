extends Node2D

@export var radius_x: float = 12.0
@export var radius_y: float = 5.0
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)

func _draw() -> void:
	const SEGMENTS: int = 24
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var a := TAU * i / SEGMENTS
		pts.append(Vector2(cos(a) * radius_x, sin(a) * radius_y))
	draw_colored_polygon(pts, shadow_color)
