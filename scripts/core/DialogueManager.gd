extends Node

## Emitted when a dialogue sequence begins.
signal dialogue_started
## Emitted each time a new line is displayed.
signal dialogue_line_displayed
## Emitted when the entire dialogue sequence ends. Passes the file path (or "" if started from an array).
signal dialogue_finished(file_path: String)

var _is_active: bool = false
var _lines: Array = []
var _current_index: int = 0
var _overlay: Node = null
var _blocked_viewport_containers: Array = []
var _current_dialogue_path: String = ""

const OVERLAY_SCENE_PATH = "res://scenes/ui/DialogueOverlay.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Uses _input() (not _unhandled_input) so events are intercepted BEFORE they
## reach any game node or SubViewportContainer in the tree.
func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	# Handle Skip Button click manually because we block all input
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _overlay and _overlay.has_method("is_skip_button_hovered") and _overlay.is_skip_button_hovered():
			close_dialogue()
			get_viewport().set_input_as_handled()
			return

	# Handle the dialogue advance action
	if event.is_action_pressed("dialogue_advance"):
		if _overlay.is_typewriter_playing():
			_overlay.complete_typewriter()
		else:
			advance()

	# Block ALL input from reaching anything else (game, SubViewport, etc.)
	get_viewport().set_input_as_handled()

## Force-releases all non-dialogue input actions every frame while active.
## This prevents scripts that poll Input.is_action_pressed() in their _process()
## from receiving input while dialogue is on screen.
func _process(_delta: float) -> void:
	if not _is_active:
		return
	for action in InputMap.get_actions():
		if action == "dialogue_advance":
			continue
		if Input.is_action_pressed(action):
			Input.action_release(action)

## Starts a dialogue sequence from a data file path.
## The file must have a static get_lines() -> Array method.
## Example: DialogueManager.start_dialogue("res://scenes/ui/dialogues/test_dialogue.gd")
func start_dialogue(dialogue_path: String) -> void:
	if _is_active:
		return

	var script = load(dialogue_path)
	if script == null:
		push_error("DialogueManager: Failed to load dialogue script: " + dialogue_path)
		return

	_current_dialogue_path = dialogue_path
	var lines = script.get_lines()
	start_dialogue_from_array(lines)

## Starts a dialogue sequence from a raw array of line dictionaries.
## Each dictionary should have: "speaker" (String), "text" (String), "portrait" (String, optional).
func start_dialogue_from_array(lines: Array) -> void:
	if _is_active:
		return
	if lines.is_empty():
		push_warning("DialogueManager: Attempted to start dialogue with empty lines array.")
		return

	_lines = lines
	_current_index = 0
	_is_active = true

	_block_subviewport_input()
	_ensure_overlay()
	_overlay.show_box()
	_display_current_line()
	dialogue_started.emit()

## Advances to the next line of dialogue.
## If the current line is the last one, closes the dialogue.
func advance() -> void:
	if not _is_active:
		return

	_current_index += 1
	if _current_index < _lines.size():
		_display_current_line()
	else:
		close_dialogue()

## Returns true if a dialogue sequence is currently active.
func is_active() -> bool:
	return _is_active

## Force-closes any active dialogue sequence immediately.
func close_dialogue() -> void:
	if not _is_active:
		return

	_is_active = false
	_lines = []
	_current_index = 0

	_unblock_subviewport_input()

	if _overlay:
		_overlay.hide_box()

	var path = _current_dialogue_path
	_current_dialogue_path = ""
	dialogue_finished.emit(path)

func _display_current_line() -> void:
	var line = _lines[_current_index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")
	var portrait_path: String = line.get("portrait", "")

	_overlay.display_line(speaker, text, portrait_path)
	dialogue_line_displayed.emit()

func _ensure_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		return

	var overlay_scene = load(OVERLAY_SCENE_PATH)
	if overlay_scene:
		_overlay = overlay_scene.instantiate()
		# Add to root so it renders above everything via its CanvasLayer
		get_tree().root.add_child(_overlay)
	else:
		push_error("DialogueManager: Failed to load overlay scene: " + OVERLAY_SCENE_PATH)

## Disables input forwarding on all SubViewportContainers in the scene tree.
## Stores their original state so it can be restored when dialogue ends.
func _block_subviewport_input() -> void:
	_blocked_viewport_containers.clear()
	_find_and_block_containers(get_tree().root)

func _find_and_block_containers(node: Node) -> void:
	if node is SubViewportContainer:
		_blocked_viewport_containers.append({
			"node": node,
			"input": node.is_processing_input(),
			"unhandled_input": node.is_processing_unhandled_input(),
		})
		node.set_process_input(false)
		node.set_process_unhandled_input(false)
	for child in node.get_children():
		_find_and_block_containers(child)

## Restores input forwarding on previously blocked SubViewportContainers.
func _unblock_subviewport_input() -> void:
	for entry in _blocked_viewport_containers:
		var n = entry["node"]
		if is_instance_valid(n):
			n.set_process_input(entry["input"])
			n.set_process_unhandled_input(entry["unhandled_input"])
	_blocked_viewport_containers.clear()
