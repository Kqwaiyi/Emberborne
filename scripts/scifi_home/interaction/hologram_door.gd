extends Node2D

@export var next_scene_path: String = ""

@onready var _zone: Area2D = $Zone
@onready var _prompt: CanvasLayer = $Prompt
@onready var _prompt_container: Control = $Prompt/PromptRoot/PromptContainer
@onready var _prompt_label: Label = $Prompt/PromptRoot/PromptContainer/HBox/PromptLabel
@onready var _glitch_overlay: ColorRect = $Prompt/PromptRoot/PromptContainer/GlitchOverlay
@onready var _prompt_box: PanelContainer = $Prompt/PromptRoot/PromptContainer/PromptBox

var _player_in_zone := false
var _is_interacting := false
var _pulse := 0.0
var _base_prompt_y := 0.0
var _current_tween: Tween

var _radius_offset := 0.0
var _thickness_offset := 0.0

func _ready() -> void:
	_prompt.visible = false
	_prompt_container.scale.y = 0.0
	_base_prompt_y = _prompt_container.position.y
	
	var mat = _glitch_overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", 0.0)
		
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	queue_redraw()
	
	if _prompt.visible and not _is_interacting:
		_prompt_container.position.y = _base_prompt_y + sin(Time.get_ticks_msec() * 0.003) * 6.0
	
	if _player_in_zone and not _is_interacting and not GameGlobal.is_laptop_open and Input.is_action_just_pressed("interact"):
		_confirm_prompt()

func _draw() -> void:
	var a  := 0.35 + 0.15 * sin(_pulse)
	var c  := Color(0.0, 0.85, 1.0, a)
	var cd := Color(0.0, 0.85, 1.0, a * 0.4)
	
	var t1 = 4.5 + _thickness_offset
	var t2 = 3.0 + _thickness_offset * 0.6
	var t3 = 2.0 + _thickness_offset * 0.4
	
	var r1 = 44.0 + _radius_offset
	var r2 = 33.0 + _radius_offset * 0.75
	var r3 = 20.0 + _radius_offset * 0.45
	
	draw_arc(Vector2.ZERO, r1, 0.0, TAU, 64, c,  t1)
	draw_arc(Vector2.ZERO, r2, 0.0, TAU, 48, cd, t2)
	draw_arc(Vector2.ZERO, r3, 0.0, TAU, 32, cd, t3)
	
	var ba := 0.07 + 0.04 * sin(_pulse + 1.0)
	draw_rect(Rect2(-4.0, -60.0, 8.0, 60.0), Color(0.0, 0.85, 1.0, ba))

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_zone = true
		if not _is_interacting:
			_show_prompt()

func _on_body_exited(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_zone = false
		if not _is_interacting:
			_hide_prompt()

func _show_prompt() -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	_prompt.visible = true
	_prompt_label.text = "S62_HOLOGRAM"
	_prompt_label.visible_ratio = 0.0
	_prompt_container.modulate = Color(1, 1, 1, 1)
	
	var mat = _glitch_overlay.material as ShaderMaterial
	
	_current_tween = create_tween().set_parallel(true)
	
	_prompt_container.scale.y = 0.0
	_current_tween.tween_property(_prompt_container, "scale:y", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_current_tween.tween_property(self, "_radius_offset", 8.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_current_tween.tween_property(self, "_thickness_offset", 2.5, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if mat:
		mat.set_shader_parameter("intensity", 0.8)
		_current_tween.tween_method(func(v): mat.set_shader_parameter("intensity", v), 0.8, 0.05, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	_current_tween.tween_property(_prompt_label, "visible_ratio", 1.0, 0.25).set_delay(0.15)

func _hide_prompt() -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	var mat = _glitch_overlay.material as ShaderMaterial
	
	_current_tween = create_tween().set_parallel(true)
	_current_tween.tween_property(_prompt_container, "scale:y", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	_current_tween.tween_property(self, "_radius_offset", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_current_tween.tween_property(self, "_thickness_offset", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	if mat:
		_current_tween.tween_method(func(v): mat.set_shader_parameter("intensity", v), 0.05, 0.9, 0.15)
		
	_current_tween.chain().tween_callback(func(): _prompt.visible = false)

func _confirm_prompt() -> void:
	_is_interacting = true
	
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		
	_prompt_label.text = "  ACCESSING..."
	_prompt_label.visible_ratio = 1.0
	
	var mat = _glitch_overlay.material as ShaderMaterial
	
	_current_tween = create_tween()
	
	# Flash effect
	_current_tween.tween_property(_prompt_container, "modulate", Color(0.2, 1.5, 2.0, 1.0), 0.05)
	_current_tween.parallel().tween_property(self, "_radius_offset", 16.0, 0.05)
	_current_tween.parallel().tween_property(self, "_thickness_offset", 5.0, 0.05)
	if mat:
		_current_tween.parallel().tween_method(func(v): mat.set_shader_parameter("intensity", v), 0.05, 0.7, 0.05)
		
	# Hold briefly
	_current_tween.tween_interval(0.15)
	
	# Collapse
	_current_tween.tween_property(_prompt_container, "scale:y", 0.0, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_current_tween.parallel().tween_property(self, "_radius_offset", -44.0, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_current_tween.parallel().tween_property(self, "_thickness_offset", -4.5, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Open laptop
	_current_tween.tween_callback(func():
		_prompt.visible = false
		_is_interacting = false
		# Reset visuals in case it's used again
		_radius_offset = 0.0
		_thickness_offset = 0.0
		var laptops = get_tree().get_nodes_in_group("laptop_ui")
		if laptops.size() > 0:
			laptops[0].open_laptop(next_scene_path)
	)
