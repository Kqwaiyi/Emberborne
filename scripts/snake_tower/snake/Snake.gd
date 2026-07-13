extends Node2D
class_name Snake

var segments: Array[Vector2i] = []
var visual_nodes: Array[Sprite2D] = []

var is_falling: bool = false
var fall_timer: float = 0.0
var fall_interval: float = 0.15

func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.queue_free()
		
	# If placed manually in editor, initialize at current grid position
	if segments.is_empty():
		var grid_pos = Vector2i((position / float(Globals.TILE_SIZE)).round())
		# Reset our own position to 0,0 since we manually position our child segments
		position = Vector2.ZERO 
		# Wait until all other nodes (like terrain) have registered in the grid
		call_deferred("_deferred_init", grid_pos)

func _deferred_init(grid_pos: Vector2i):
	var arr: Array[Vector2i] = [grid_pos]
	init_snake(arr)

func init_snake(start_positions: Array[Vector2i]):
	for pos in start_positions:
		add_segment(pos)
	update_grid_registration()
	check_gravity()

func add_segment(pos: Vector2i):
	segments.append(pos)
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.centered = false
	sprite.scale = Vector2(Globals.TILE_SIZE / 128.0, Globals.TILE_SIZE / 128.0)
	if segments.size() == 1:
		sprite.modulate = Color(0.1, 0.4, 0.8) # Head
	else:
		sprite.modulate = Color(0.2, 0.6, 1.0) # Body
	add_child(sprite)
	visual_nodes.append(sprite)
	update_visuals()

func update_visuals():
	for i in range(segments.size()):
		visual_nodes[i].position = Vector2(segments[i]) * Globals.TILE_SIZE

func update_grid_registration():
	# Only unregister cells that are currently registered to THIS snake
	for i in range(segments.size()):
		var cell = LevelManager.get_cell(segments[i])
		if cell == LevelManager.CellType.SNAKE_HEAD or cell == LevelManager.CellType.SNAKE_BODY:
			LevelManager.unregister_cell(segments[i])
	
	for i in range(segments.size()):
		if i == 0:
			LevelManager.register_cell(segments[i], LevelManager.CellType.SNAKE_HEAD, self)
		else:
			LevelManager.register_cell(segments[i], LevelManager.CellType.SNAKE_BODY, self)

func _process(delta):
	if is_falling:
		fall_timer += delta
		if fall_timer >= fall_interval:
			fall_timer = 0.0
			do_fall_step()
	else:
		handle_input()

func handle_input():
	var dir = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("ui_down"):
		dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_right"):
		dir = Vector2i(1, 0)
	
	if dir != Vector2i.ZERO:
		try_move(dir)

func try_move(dir: Vector2i):
	var head = segments[0]
	var target = head + dir
	
	if segments.size() > 1 and target == segments[1]:
		return
	
	var cell = LevelManager.get_cell(target)
	
	if cell == LevelManager.CellType.TERRAIN:
		return
	elif cell == LevelManager.CellType.APPLE:
		move_segments(target, true)
		LevelManager.consume_apple(target)
	elif cell == LevelManager.CellType.SPIKE:
		move_segments(target, false) # visually move into it
		LevelManager.trigger_loss()
		return
	elif cell == LevelManager.CellType.GOAL:
		move_segments(target, false)
		LevelManager.trigger_win()
		return
	elif cell == LevelManager.CellType.SNAKE_BODY or cell == LevelManager.CellType.SNAKE_HEAD:
		return
	else:
		move_segments(target, false)
	
	update_grid_registration()
	update_visuals()
	check_gravity()

func move_segments(target: Vector2i, grow: bool):
	for i in range(segments.size()):
		var cell = LevelManager.get_cell(segments[i])
		if cell == LevelManager.CellType.SNAKE_HEAD or cell == LevelManager.CellType.SNAKE_BODY:
			LevelManager.unregister_cell(segments[i])
			
	var new_segments: Array[Vector2i] = []
	new_segments.append(target)
	for i in range(segments.size()):
		if i == segments.size() - 1 and not grow:
			continue
		new_segments.append(segments[i])
	
	segments = new_segments
	
	if grow:
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://icon.svg")
		sprite.centered = false
		sprite.scale = Vector2(Globals.TILE_SIZE / 128.0, Globals.TILE_SIZE / 128.0)
		sprite.modulate = Color(0.2, 0.6, 1.0)
		add_child(sprite)
		visual_nodes.append(sprite)

func check_gravity():
	if LevelManager.check_support(segments):
		is_falling = false
	else:
		is_falling = true
		fall_timer = 0.0

func do_fall_step():
	var landing_on_spike = LevelManager.check_gravity_death(segments)
	
	for i in range(segments.size()):
		var cell = LevelManager.get_cell(segments[i])
		if cell == LevelManager.CellType.SNAKE_HEAD or cell == LevelManager.CellType.SNAKE_BODY:
			LevelManager.unregister_cell(segments[i])
			
	for i in range(segments.size()):
		segments[i] += Vector2i(0, 1)
		
	update_grid_registration()
	update_visuals()
	
	if landing_on_spike:
		LevelManager.trigger_loss()
		return
		
	check_gravity()
