extends Button

const HOLO_CYAN := Color(0.0, 0.9, 1.0, 0.8)
const HOLO_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const HOLO_RED := Color(1.0, 0.2, 0.2, 1.0)
const HOLO_CYAN_DIM := Color(0.0, 0.9, 1.0, 0.3)

signal press_state_changed(is_pressed: bool)

var _hover_progress: float = 0.0
var _press_intensity: float = 0.0
var _pulse_time: float = 0.0

var _hover_tween: Tween = null
var _press_tween: Tween = null



var _is_locked: bool = false
var _hover_audio: AudioStreamPlayer = null
var _down_audio: AudioStreamPlayer = null
var _close_audio: AudioStreamPlayer = null

func lock() -> void:
	_is_locked = true

func reset() -> void:
	_is_locked = false
	_hover_progress = 0.0
	_press_intensity = 0.0
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()

func _ready() -> void:
	# Setup audio players
	_hover_audio = AudioStreamPlayer.new()
	var hover_stream = load("res://assets/sounds/futuristic_ui/Hover.mp3")
	if hover_stream:
		_hover_audio.stream = hover_stream
	add_child(_hover_audio)
	
	_down_audio = AudioStreamPlayer.new()
	var down_stream = load("res://assets/sounds/futuristic_ui/Click.mp3")
	if down_stream:
		_down_audio.stream = down_stream
	add_child(_down_audio)
	
	_close_audio = AudioStreamPlayer.new()
	var close_stream = load("res://assets/sounds/laptop_ui/laptop_ui_close.mp3")
	if close_stream:
		_close_audio.stream = close_stream
	add_child(_close_audio)
	
	# Connect to input signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)
	
	# Keep drawing updated for the pulse effect
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_pulse_time += delta * 2.0
	queue_redraw()

func _on_mouse_entered() -> void:
	if _hover_audio and _hover_audio.stream and not _is_locked:
		_hover_audio.play()
		
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "_hover_progress", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_mouse_exited() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "_hover_progress", 0.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	# Ensure press is reset if mouse leaves while held down
	if _press_intensity > 0.0:
		_on_button_up()

func _on_button_down() -> void:
	if _is_locked: return
	
	if _down_audio and _down_audio.stream:
		_down_audio.play()
		
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, "_press_intensity", 1.0, 0.1)
	press_state_changed.emit(true)

func _on_pressed() -> void:
	if _close_audio and _close_audio.stream:
		_close_audio.play()

func _on_button_up() -> void:
	if _is_locked: return
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, "_press_intensity", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	press_state_changed.emit(false)

func _draw() -> void:
	var center = size / 2.0
	var extents = min(size.x, size.y) * 0.35
	
	# Pulse effect on idle
	var pulse = sin(_pulse_time) * 0.5 + 0.5
	var base_alpha = lerp(0.6, 1.0, pulse)
	
	# Determine colors based on state
	var current_color = HOLO_CYAN
	current_color.a = base_alpha
	if _hover_progress > 0.0:
		current_color = HOLO_CYAN.lerp(HOLO_WHITE, _hover_progress * 0.5)
	if _press_intensity > 0.0:
		current_color = current_color.lerp(HOLO_RED, _press_intensity)
		extents *= lerp(1.0, 0.8, _press_intensity) # Shrink the X slightly on press
		
	# Draw the "X"
	var line_width = lerp(1.5, 2.5, _press_intensity)
	draw_line(center - Vector2(extents, extents), center + Vector2(extents, extents), current_color, line_width, true)
	draw_line(center - Vector2(-extents, extents), center + Vector2(-extents, extents), current_color, line_width, true)
	
	# Draw hover brackets
	if _hover_progress > 0.0:
		var bracket_color = HOLO_CYAN_DIM.lerp(HOLO_RED, _press_intensity)
		var bracket_size = 6.0
		var bracket_dist_x = size.x * 0.5
		var bracket_dist_y = size.y * 0.5
		
		# Outward start position to inward snap
		var offset_x = lerp(bracket_dist_x + 10.0, bracket_dist_x, _hover_progress)
		var offset_y = lerp(bracket_dist_y + 10.0, bracket_dist_y, _hover_progress)
		
		# Compress further on press
		offset_x = lerp(offset_x, offset_x - 3.0, _press_intensity)
		offset_y = lerp(offset_y, offset_y - 3.0, _press_intensity)
		
		var b_width = 1.0
		
		# Top-Left
		draw_line(center + Vector2(-offset_x, -offset_y), center + Vector2(-offset_x + bracket_size, -offset_y), bracket_color, b_width)
		draw_line(center + Vector2(-offset_x, -offset_y), center + Vector2(-offset_x, -offset_y + bracket_size), bracket_color, b_width)
		
		# Top-Right
		draw_line(center + Vector2(offset_x, -offset_y), center + Vector2(offset_x - bracket_size, -offset_y), bracket_color, b_width)
		draw_line(center + Vector2(offset_x, -offset_y), center + Vector2(offset_x, -offset_y + bracket_size), bracket_color, b_width)
		
		# Bottom-Left
		draw_line(center + Vector2(-offset_x, offset_y), center + Vector2(-offset_x + bracket_size, offset_y), bracket_color, b_width)
		draw_line(center + Vector2(-offset_x, offset_y), center + Vector2(-offset_x, offset_y - bracket_size), bracket_color, b_width)
		
		# Bottom-Right
		draw_line(center + Vector2(offset_x, offset_y), center + Vector2(offset_x - bracket_size, offset_y), bracket_color, b_width)
		draw_line(center + Vector2(offset_x, offset_y), center + Vector2(offset_x, offset_y - bracket_size), bracket_color, b_width)
