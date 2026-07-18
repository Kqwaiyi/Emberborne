extends Node

## Emitted when a task notification begins.
signal task_started
## Emitted when the task notification is acknowledged and closed.
signal task_acknowledged

var _is_active: bool = false
var _overlay: Node = null
var _blocked_viewport_containers: Array = []

const OVERLAY_SCENE_PATH = "res://scenes/ui/TaskOverlay.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Uses _input() to intercept events before they reach game nodes.
func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event.is_action_pressed("dialogue_advance"):
		if _overlay.is_typewriter_playing():
			_overlay.complete_typewriter()
		else:
			close_task()

	# Block ALL input from reaching anything else (game, SubViewport, etc.)
	get_viewport().set_input_as_handled()

## Force-releases all non-dialogue input actions every frame while active.
func _process(_delta: float) -> void:
	if not _is_active:
		return
	for action in InputMap.get_actions():
		if action == "dialogue_advance":
			continue
		if Input.is_action_pressed(action):
			Input.action_release(action)

## Displays a task notification popup.
func show_task(title: String, description: String) -> void:
	if _is_active:
		push_warning("TaskManager: Attempted to show a task while another is active.")
		return

	_is_active = true

	_block_subviewport_input()
	_ensure_overlay()
	_overlay.show_box()
	_overlay.display_task(title, description)
	task_started.emit()

## Returns true if a task popup is currently visible.
func is_active() -> bool:
	return _is_active

## Force-closes any active task notification immediately.
func close_task() -> void:
	if not _is_active:
		return

	_is_active = false
	_unblock_subviewport_input()

	if _overlay:
		_overlay.hide_box()

	task_acknowledged.emit()

func _ensure_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		return

	var overlay_scene = load(OVERLAY_SCENE_PATH)
	if overlay_scene:
		_overlay = overlay_scene.instantiate()
		get_tree().root.add_child(_overlay)
	else:
		push_error("TaskManager: Failed to load overlay scene: " + OVERLAY_SCENE_PATH)

## Disables input forwarding on all SubViewportContainers.
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
