extends Node2D

const DURATION := 1.6
const _FONT := preload("res://assets/fonts/Noto_Color_Emoji/NotoColorEmoji-Regular.ttf")

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	position.y -= delta * 34.0
	modulate.a = clampf(1.0 - (_t / DURATION), 0.0, 1.0)
	queue_redraw()
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	draw_string(_FONT, Vector2(-7, 10), "♥",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.95, 0.28, 0.38))
