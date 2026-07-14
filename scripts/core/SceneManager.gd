extends CanvasLayer

signal transition_started
signal scene_loaded
signal transition_finished

@onready var color_rect: ColorRect = $ColorRect

var _next_scene_path: String = ""
var _current_fade_duration: float = 0.5
var _target_viewport: Node = null

func _ready():
	color_rect.modulate.a = 0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.hide()
	set_process(false)

func change_scene_to_file(path: String, fade_duration: float = 0.5):
	_start_transition(path, fade_duration, null)

func change_scene_in_viewport(path: String, viewport: Node, fade_duration: float = 0.5):
	_start_transition(path, fade_duration, viewport)

func _start_transition(path: String, fade_duration: float, viewport: Node):
	if _next_scene_path != "":
		return # Already transitioning
		
	_next_scene_path = path
	_current_fade_duration = fade_duration
	_target_viewport = viewport
	transition_started.emit()
	
	# Start loading the scene in the background
	ResourceLoader.load_threaded_request(path)
	
	# Enable blocking interactions
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	color_rect.show()
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, fade_duration)
	tween.finished.connect(_on_fade_out_finished)

func _on_fade_out_finished():
	var load_status = ResourceLoader.load_threaded_get_status(_next_scene_path)
	
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		_switch_scene()
	elif load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Need to wait for load to complete
		set_process(true)
	else:
		push_error("Failed to load scene: " + _next_scene_path)
		_reset_transition()

func _process(_delta):
	if _next_scene_path != "":
		var load_status = ResourceLoader.load_threaded_get_status(_next_scene_path)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_switch_scene()
		elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			push_error("Failed to load scene: " + _next_scene_path)
			_reset_transition()

func _switch_scene():
	# Retrieve loaded scene
	var packed_scene = ResourceLoader.load_threaded_get(_next_scene_path)
	if packed_scene:
		if _target_viewport != null:
			for child in _target_viewport.get_children():
				child.queue_free()
			var instance = packed_scene.instantiate()
			_target_viewport.add_child(instance)
			scene_loaded.emit()
		else:
			get_tree().change_scene_to_packed(packed_scene)
			scene_loaded.emit()
	else:
		push_error("Loaded scene is null: " + _next_scene_path)
		_reset_transition()
		return
	
	# Wait one frame for the tree to update
	await get_tree().process_frame
	
	# Start fade in
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, _current_fade_duration)
	tween.finished.connect(_on_fade_in_finished)

func _on_fade_in_finished():
	_reset_transition()
	transition_finished.emit()

func _reset_transition():
	_next_scene_path = ""
	color_rect.modulate.a = 0
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
