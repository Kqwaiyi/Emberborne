extends Node2D

@export var next_scene_path: String = ""

@onready var _zone: Area2D = $Zone
@onready var _prompt: CanvasLayer = $Prompt

var _player_in_zone := false
var _pulse := 0.0

func _ready() -> void:
	_prompt.visible = false
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	queue_redraw()
	if _player_in_zone and Input.is_action_just_pressed("interact"):
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)

func _draw() -> void:
	var a  := 0.35 + 0.15 * sin(_pulse)
	var c  := Color(0.0, 0.85, 1.0, a)
	var cd := Color(0.0, 0.85, 1.0, a * 0.4)
	draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 64, c,  2.5)
	draw_arc(Vector2.ZERO, 33.0, 0.0, TAU, 48, cd, 1.5)
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, cd, 1.0)
	var ba := 0.07 + 0.04 * sin(_pulse + 1.0)
	draw_rect(Rect2(-4.0, -60.0, 8.0, 60.0), Color(0.0, 0.85, 1.0, ba))

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_zone = true
		_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_zone = false
		_prompt.visible = false
