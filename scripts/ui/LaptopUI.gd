extends CanvasLayer

## Emitted when the laptop UI has fully opened (after boot animation).
signal opened
## Emitted when the laptop UI has fully closed (after shutdown animation and cleanup).
signal closed
## Emitted when a viewport scene transition begins.
signal transition_started
## Emitted after a new scene is instantiated in the SubViewport.
signal scene_loaded
## Emitted when the viewport scene transition fade-in completes.
signal transition_finished

@onready var background_tint: ColorRect = $BackgroundTint
@onready var display_panel: Panel = $CenterContainer/DisplayPanel
@onready var sub_viewport_container: SubViewportContainer = $CenterContainer/DisplayPanel/SubViewportContainer
@onready var viewport: SubViewport = $CenterContainer/DisplayPanel/SubViewportContainer/SubViewport
@onready var transition_rect: ColorRect = $CenterContainer/DisplayPanel/TransitionRect
@onready var scan_lines: ColorRect = $CenterContainer/DisplayPanel/ScanLines
@onready var glitch_overlay: ColorRect = $CenterContainer/DisplayPanel/GlitchOverlay
@onready var header_bar: HBoxContainer = $CenterContainer/DisplayPanel/HeaderBar
@onready var status_label: Label = $CenterContainer/DisplayPanel/HeaderBar/StatusLabel
@onready var close_button: Button = $CenterContainer/DisplayPanel/HeaderBar/CloseButton
@onready var corner_decorations: Control = $CenterContainer/DisplayPanel/CornerDecorations

# ─── Viewport transition state ───────────────────────────────────────
var _next_scene_path: String = ""
var _current_fade_duration: float = 0.5
var _transition_tween: Tween = null

# ─── Animation state ─────────────────────────────────────────────────
var _is_animating: bool = false
var _anim_tween: Tween = null
var _corners: Array = []

# ─── Holographic constants ───────────────────────────────────────────
const HOLO_CYAN := Color(0.0, 0.9, 1.0, 1.0)
const HOLO_CYAN_DIM := Color(0.0, 0.9, 1.0, 0.6)
const CORNER_LENGTH := 20.0
const CORNER_WIDTH := 2.0

func _ready():
	# Ensure the UI can process even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Register in group so minigames can discover the host laptop
	add_to_group("laptop_ui")

	# Connect the close button
	close_button.pressed.connect(close_laptop)

	# Cache the pivot for scale animations (center of panel)
	display_panel.pivot_offset = display_panel.custom_minimum_size / 2.0

	# Build the decorative corner brackets programmatically
	_create_corner_decorations()

	# Disable _process polling until a scene load needs it
	set_process(false)

	# Start hidden
	hide()

# ═══════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════

## Opens the laptop UI with a holographic boot animation.
## Optionally loads a minigame scene after the animation completes.
const DESKTOP_SCENE := "res://scenes/ui/DesktopScreen.tscn"

func open_laptop(minigame_scene_path: String = "", fade_duration: float = 0.5) -> void:
	if _is_animating:
		return
	_is_animating = true

	show()
	get_tree().paused = true
	_set_hidden_state()

	await _play_open_animation()
	_is_animating = false

	# Load the minigame if a path is provided, otherwise default to Desktop
	var scene_to_load = minigame_scene_path if minigame_scene_path != "" else DESKTOP_SCENE
	change_scene(scene_to_load, fade_duration)

	opened.emit()

## Closes the laptop UI with a holographic shutdown animation.
## Clears the SubViewport, unpauses the main game, and notifies time trackers.
func close_laptop() -> void:
	if _is_animating:
		return
	_is_animating = true

	# Cancel any pending scene transition
	_cancel_transition()

	await _play_close_animation()

	hide()
	get_tree().paused = false
	clear_minigame()

	# Notify all minigame time trackers to pause their timers when laptop closes
	get_tree().call_group("minigame_time_trackers", "pause_time")

	_is_animating = false
	closed.emit()

## Loads a new scene into the laptop's SubViewport with a fade transition.
## This is the primary method for minigames to advance levels while running
## inside the laptop. Callers should discover this node via the "laptop_ui"
## group: get_tree().get_nodes_in_group("laptop_ui")[0].change_scene(path)
func change_scene(path: String, fade_duration: float = 0.5) -> void:
	if _next_scene_path != "":
		return
	_start_viewport_transition(path, fade_duration)

## Destroys all children of the SubViewport to free memory.
func clear_minigame() -> void:
	for child in viewport.get_children():
		child.queue_free()

# ═══════════════════════════════════════════════════════════════════════
# VIEWPORT TRANSITION SYSTEM
# ═══════════════════════════════════════════════════════════════════════

func _start_viewport_transition(path: String, fade_duration: float) -> void:
	_next_scene_path = path
	_current_fade_duration = fade_duration
	transition_started.emit()

	# Start loading the scene in the background
	ResourceLoader.load_threaded_request(path)

	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_rect.show()

	if fade_duration > 0.0:
		_transition_tween = create_tween()
		_transition_tween.tween_property(transition_rect, "modulate:a", 1.0, fade_duration)
		_transition_tween.finished.connect(_on_fade_out_finished)
	else:
		transition_rect.modulate.a = 0.0
		_on_fade_out_finished()

func _on_fade_out_finished() -> void:
	var load_status = ResourceLoader.load_threaded_get_status(_next_scene_path)

	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		_switch_viewport_scene()
	elif load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Need to wait for load to complete
		set_process(true)
	else:
		push_error("LaptopUI: Failed to load scene: " + _next_scene_path)
		_reset_transition()

func _process(_delta):
	if _next_scene_path != "":
		var load_status = ResourceLoader.load_threaded_get_status(_next_scene_path)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			_switch_viewport_scene()
		elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			push_error("LaptopUI: Failed to load scene: " + _next_scene_path)
			_reset_transition()

func _switch_viewport_scene() -> void:
	var packed_scene = ResourceLoader.load_threaded_get(_next_scene_path)
	if packed_scene:
		# Notify time trackers BEFORE adding the child so they know what scene
		# is being loaded when the new scene's _ready() fires start_time()
		get_tree().call_group("minigame_time_trackers", "_on_laptop_scene_loaded", _next_scene_path)

		for child in viewport.get_children():
			child.queue_free()
		var instance = packed_scene.instantiate()
		viewport.add_child(instance)

		scene_loaded.emit()
	else:
		push_error("LaptopUI: Loaded scene is null: " + _next_scene_path)
		_reset_transition()
		return

	# Wait one frame for the tree to update
	await get_tree().process_frame

	# Start fade in
	if _current_fade_duration > 0.0:
		_transition_tween = create_tween()
		_transition_tween.tween_property(transition_rect, "modulate:a", 0.0, _current_fade_duration)
		_transition_tween.finished.connect(_on_fade_in_finished)
	else:
		transition_rect.modulate.a = 0.0
		_on_fade_in_finished()

func _on_fade_in_finished() -> void:
	_reset_transition()
	transition_finished.emit()

func _reset_transition() -> void:
	_next_scene_path = ""
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.modulate.a = 0.0
	_transition_tween = null

func _cancel_transition() -> void:
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
	set_process(false)
	_next_scene_path = ""
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.modulate.a = 0.0

# ═══════════════════════════════════════════════════════════════════════
# HOLOGRAPHIC ANIMATIONS
# ═══════════════════════════════════════════════════════════════════════

func _set_hidden_state() -> void:
	background_tint.modulate.a = 0.0
	display_panel.scale = Vector2(1.0, 0.003)
	display_panel.modulate.a = 0.0
	scan_lines.modulate.a = 0.0
	header_bar.modulate.a = 0.0
	close_button.modulate.a = 0.0
	status_label.text = ""
	_set_glitch_intensity(0.0)
	for corner in _corners:
		corner.h.modulate.a = 0.0
		corner.v.modulate.a = 0.0

## Holographic boot sequence (~0.6s):
## 1. Background tint fades in
## 2. A thin horizontal cyan line appears (panel at near-zero Y scale)
## 3. The line expands vertically with an overshoot ease, glitch bands flicker
## 4. Scan lines activate, header types out "◆ SYSTEM ONLINE"
## 5. Corner brackets slide in from outside the panel edges
## 6. Close button fades in last
func _play_open_animation() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween().set_parallel(true)

	# Background tint fades in (0.0 – 0.15s)
	_anim_tween.tween_property(background_tint, "modulate:a", 1.0, 0.15)

	# Display panel: thin line appears (0.08 – 0.13s)
	_anim_tween.tween_property(display_panel, "modulate:a", 1.0, 0.05).set_delay(0.08)

	# Display panel: line expands vertically (0.13 – 0.4s)
	_anim_tween.tween_property(display_panel, "scale", Vector2(1.0, 1.0), 0.27)\
		.set_delay(0.13).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Glitch effect during expansion (0.1 – 0.4s)
	_anim_tween.tween_method(_set_glitch_intensity, 0.7, 0.0, 0.3).set_delay(0.1)




	# Header bar fades in (0.4 – 0.55s)
	_anim_tween.tween_property(header_bar, "modulate:a", 1.0, 0.15).set_delay(0.4)

	# Close button fades in (0.5 – 0.6s)
	_anim_tween.tween_property(close_button, "modulate:a", 1.0, 0.1).set_delay(0.5)

	# Corner decorations slide in (starting at 0.35s)
	_anim_tween.tween_callback(_animate_corners_in).set_delay(0.35)

	# Status label typewriter effect (starting at 0.42s)
	_anim_tween.tween_callback(_typewrite_status.bind("\u25C6 SYSTEM ONLINE")).set_delay(0.42)

	await _anim_tween.finished

## Holographic shutdown sequence (~0.4s, snappier than open):
## 1. Close button and header vanish, glitch intensity spikes
## 2. Corner brackets fade out, scan lines disappear
## 3. Display compresses back to a thin line
## 4. Line and background tint fade out
func _play_close_animation() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween().set_parallel(true)

	# Close button: instant hide
	_anim_tween.tween_property(close_button, "modulate:a", 0.0, 0.05)

	# Header: fade out (0.0 – 0.08s)
	_anim_tween.tween_property(header_bar, "modulate:a", 0.0, 0.08)

	# Glitch spike (0.0 – 0.08s)
	_anim_tween.tween_method(_set_glitch_intensity, 0.0, 0.8, 0.08)

	# Corner decorations: fade out
	_anim_tween.tween_callback(_animate_corners_out)

	# Scan lines: fade out (0.05 – 0.15s)
	_anim_tween.tween_property(scan_lines, "modulate:a", 0.0, 0.1).set_delay(0.05)

	# Display panel: compress vertically (0.1 – 0.3s)
	_anim_tween.tween_property(display_panel, "scale", Vector2(1.0, 0.003), 0.2)\
		.set_delay(0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)

	# Display panel: fade out (0.3 – 0.35s)
	_anim_tween.tween_property(display_panel, "modulate:a", 0.0, 0.05).set_delay(0.3)

	# Glitch: fade out (0.1 – 0.25s)
	_anim_tween.tween_method(_set_glitch_intensity, 0.8, 0.0, 0.15).set_delay(0.1)

	# Background: fade out (0.25 – 0.4s)
	_anim_tween.tween_property(background_tint, "modulate:a", 0.0, 0.15).set_delay(0.25)

	await _anim_tween.finished

func _set_glitch_intensity(value: float) -> void:
	var material = glitch_overlay.material as ShaderMaterial
	if material:
		material.set_shader_parameter("intensity", value)

func _typewrite_status(text: String) -> void:
	status_label.text = ""
	var tween = create_tween()
	for i in text.length():
		var target_text = text.substr(0, i + 1)
		tween.tween_callback(func(): status_label.text = target_text)
		tween.tween_interval(0.02)

# ═══════════════════════════════════════════════════════════════════════
# CORNER DECORATIONS
# ═══════════════════════════════════════════════════════════════════════

func _create_corner_decorations() -> void:
	for i in 4:
		var h_rect = ColorRect.new()
		var v_rect = ColorRect.new()
		h_rect.color = HOLO_CYAN_DIM
		v_rect.color = HOLO_CYAN_DIM
		h_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h_rect.size = Vector2(CORNER_LENGTH, CORNER_WIDTH)
		v_rect.size = Vector2(CORNER_WIDTH, CORNER_LENGTH)
		corner_decorations.add_child(h_rect)
		corner_decorations.add_child(v_rect)
		_corners.append({"h": h_rect, "v": v_rect})

	_position_corners_at_rest()

func _get_rest_positions() -> Array:
	var s = display_panel.custom_minimum_size
	return [
		{"h": Vector2(0, 0), "v": Vector2(0, 0)},
		{"h": Vector2(s.x - CORNER_LENGTH, 0), "v": Vector2(s.x - CORNER_WIDTH, 0)},
		{"h": Vector2(0, s.y - CORNER_WIDTH), "v": Vector2(0, s.y - CORNER_LENGTH)},
		{"h": Vector2(s.x - CORNER_LENGTH, s.y - CORNER_WIDTH), "v": Vector2(s.x - CORNER_WIDTH, s.y - CORNER_LENGTH)},
	]

func _position_corners_at_rest() -> void:
	var positions = _get_rest_positions()
	for i in 4:
		_corners[i].h.position = positions[i].h
		_corners[i].v.position = positions[i].v

func _animate_corners_in() -> void:
	var corner_offset = 30.0
	var positions = _get_rest_positions()

	# Set initial positions (offset outward from each corner)
	_corners[0].h.position = positions[0].h + Vector2(-corner_offset, -corner_offset)
	_corners[0].v.position = positions[0].v + Vector2(-corner_offset, -corner_offset)
	_corners[1].h.position = positions[1].h + Vector2(corner_offset, -corner_offset)
	_corners[1].v.position = positions[1].v + Vector2(corner_offset, -corner_offset)
	_corners[2].h.position = positions[2].h + Vector2(-corner_offset, corner_offset)
	_corners[2].v.position = positions[2].v + Vector2(-corner_offset, corner_offset)
	_corners[3].h.position = positions[3].h + Vector2(corner_offset, corner_offset)
	_corners[3].v.position = positions[3].v + Vector2(corner_offset, corner_offset)

	# Make visible and animate to rest positions
	var tween = create_tween().set_parallel(true)
	for i in 4:
		_corners[i].h.modulate.a = 1.0
		_corners[i].v.modulate.a = 1.0
		tween.tween_property(_corners[i].h, "position", positions[i].h, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_corners[i].v, "position", positions[i].v, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _animate_corners_out() -> void:
	var tween = create_tween().set_parallel(true)
	for corner in _corners:
		tween.tween_property(corner.h, "modulate:a", 0.0, 0.15)
		tween.tween_property(corner.v, "modulate:a", 0.0, 0.15)
