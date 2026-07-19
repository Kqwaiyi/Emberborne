class_name HoverButton
extends Button

const HOVER_SOUND = preload("res://assets/sounds/other_ui/other_ui_hover.mp3")
const CLICK_SOUND = preload("res://assets/sounds/other_ui/other_ui_click.mp3")

@export var scale_on_hover: bool = true

var _tween: Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)

func _on_mouse_entered() -> void:
	_play_transient_sound(HOVER_SOUND)
	if not scale_on_hover:
		return
	pivot_offset = size / 2.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	if not scale_on_hover:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_down() -> void:
	_play_transient_sound(CLICK_SOUND)

func _play_transient_sound(stream: AudioStream) -> void:
	if not stream:
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root = get_tree().root
	if root:
		root.add_child(player)
		player.play()
		player.finished.connect(player.queue_free)
