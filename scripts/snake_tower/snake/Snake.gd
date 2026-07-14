extends Node2D
class_name Snake

@export var tail_scene: PackedScene

var segments: Array[Vector2i] = []
var visual_nodes: Array[Node2D] = []

var is_falling: bool = false
var fall_timer: float = 0.0
var fall_interval: float = 0.15

func _ready():
	# If placed manually in editor, initialize at current grid position
	if segments.is_empty():
		var grid_pos = Vector2i((position / float(Globals.TILE_SIZE)).round())
		# Reset our own position to 0,0 since we manually position our child segments
		position = Vector2.ZERO 
		# Wait until all other nodes (like terrain) have registered in the grid
		call_deferred("_deferred_init", grid_pos)

func _deferred_init(grid_pos: Vector2i):
	var head_pos = grid_pos
	var current_pos = head_pos
	var arr: Array[Vector2i] = [head_pos]
	
	var tail_nodes = get_tree().get_nodes_in_group("snake_tail")
	var tail_dict = {}
	for t in tail_nodes:
		tail_dict[t.grid_position] = t
		
	var prev_pos = head_pos
	while true:
		var found_next = false
		var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir in directions:
			var next_pos = current_pos + dir
			if next_pos != prev_pos and tail_dict.has(next_pos):
				arr.append(next_pos)
				prev_pos = current_pos
				current_pos = next_pos
				found_next = true
				
				var tail_node = tail_dict[next_pos]
				tail_node.queue_free()
				break
		if not found_next:
			break
			
	init_snake(arr)

func init_snake(start_positions: Array[Vector2i]):
	for pos in start_positions:
		add_segment(pos)
	update_grid_registration()
	check_gravity()
	if has_node("Camera2D"):
		$Camera2D.reset_smoothing()

func add_segment(pos: Vector2i):
	segments.append(pos)
	var node: Node2D
	var needs_add_child = true
	if segments.size() == 1:
		if has_node("Sprite2D"):
			node = $Sprite2D
			needs_add_child = false
		else:
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://icon.svg")
			sprite.centered = false
			sprite.scale = Vector2(Globals.TILE_SIZE / 128.0, Globals.TILE_SIZE / 128.0)
			sprite.modulate = Color(0.1, 0.4, 0.8) # Head
			node = sprite
	else:
		if tail_scene:
			node = tail_scene.instantiate()
		else:
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://icon.svg")
			sprite.centered = false
			sprite.scale = Vector2(Globals.TILE_SIZE / 128.0, Globals.TILE_SIZE / 128.0)
			sprite.modulate = Color(0.2, 0.6, 1.0) # Body fallback
			node = sprite
			
	if needs_add_child:
		add_child(node)
	visual_nodes.append(node)
	update_visuals()

func update_visuals():
	for i in range(segments.size()):
		visual_nodes[i].position = Vector2(segments[i]) * Globals.TILE_SIZE
	if has_node("Camera2D") and not segments.is_empty():
		$Camera2D.position = Vector2(segments[0]) * Globals.TILE_SIZE + Vector2(Globals.TILE_SIZE / 2.0, Globals.TILE_SIZE / 2.0)

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
	if Input.is_action_just_pressed("snake_up"):
		dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("snake_down"):
		dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("snake_left"):
		dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("snake_right"):
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
	elif cell == LevelManager.CellType.BOX:
		var box = LevelManager.get_box(target)
		if box and box.try_push(dir):
			move_segments(target, false)
		else:
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
		var node: Node2D
		if tail_scene:
			node = tail_scene.instantiate()
		else:
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://icon.svg")
			sprite.centered = false
			sprite.scale = Vector2(Globals.TILE_SIZE / 128.0, Globals.TILE_SIZE / 128.0)
			sprite.modulate = Color(0.2, 0.6, 1.0)
			node = sprite
		add_child(node)
		visual_nodes.append(node)

func check_gravity():
	if LevelManager.check_support(segments):
		is_falling = false
	else:
		is_falling = true
		fall_timer = 0.0

func do_fall_step():
	var landing_on_spike = LevelManager.check_gravity_death(segments)
	var landing_on_goal = LevelManager.check_gravity_win(segments)
	
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
		
	if landing_on_goal:
		LevelManager.trigger_win()
		return
		
	check_gravity()
