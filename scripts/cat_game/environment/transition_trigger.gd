extends Node2D

@export var destination: NodePath = NodePath("")

var _cooldown := false

func _ready() -> void:
	print("[Transition] _ready on: ", name, " | destination=", destination)
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var tex = get("texture")
	if tex:
		shape.size = tex.get_size()
		print("[Transition] texture size: ", tex.get_size())
	else:
		shape.size = Vector2(16, 20)
		print("[Transition] no texture, using fallback size")
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask  = 2
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	print("[Transition] Area2D ready, shape size: ", shape.size)

func _on_body_entered(body: Node) -> void:
	print("[Transition] body_entered: ", body.name, " is_player=", body.is_in_group("player"))
	if _cooldown or not body.is_in_group("player"):
		return
	print("[Transition] destination string: '", str(destination), "'")
	var dest: Node = get_node_or_null(destination)
	print("[Transition] dest resolved: ", dest)
	if dest == null:
		push_error("[Transition] destination null! path=" + str(destination))
		return
	_cooldown = true
	_do_transition(body, dest.global_position)

func _do_transition(player: Node, target_pos: Vector2) -> void:
	var canvas  := CanvasLayer.new()
	canvas.layer = 100
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.size  = get_viewport().get_visible_rect().size
	canvas.add_child(overlay)
	get_tree().root.add_child(canvas)

	var tween := create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.25)
	await tween.finished

	player.global_position = target_pos

	tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.25)
	await tween.finished
	canvas.queue_free()

	await get_tree().create_timer(0.3).timeout
	_cooldown = false
