extends MarginContainer

@export var app_name: String = "MODULE":
	set(value):
		app_name = value
		if is_inside_tree():
			_update_ui()

@export var target_scene: String = ""
@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		if is_inside_tree():
			_update_ui()
			
@export var hover_sound_stream: AudioStream = null
@export var click_sound_stream: AudioStream = null
@export var color_preset: String = "default"

signal pressed
signal app_hovered(app_name: String, color_preset: String)
signal app_unhovered

@onready var panel: Panel = $ButtonPanel
@onready var hover_glow: ColorRect = $ButtonPanel/HoverGlow
@onready var icon_rect: TextureRect = $ButtonPanel/VBoxContainer/IconRect
@onready var app_label: Label = $ButtonPanel/VBoxContainer/AppLabel
@onready var click_button: Button = $ClickButton
@onready var hover_sound: AudioStreamPlayer = $HoverSound
@onready var click_sound: AudioStreamPlayer = $ClickSound

var _hover_tween: Tween = null
var _press_tween: Tween = null
@onready var border_glow: ColorRect = $ButtonPanel/BorderGlow

func _ready():
	if hover_sound_stream:
		hover_sound.stream = hover_sound_stream
	if click_sound_stream:
		click_sound.stream = click_sound_stream
		
	_update_ui()
	
	# Duplicate the stylebox so each button has a unique instance
	var style = panel.get_theme_stylebox("panel").duplicate()
	panel.add_theme_stylebox_override("panel", style)
	
	# Duplicate the shader material so each button has its own independent time/parameters
	var mat = border_glow.material.duplicate()
	border_glow.material = mat
	
	# Connect button signals
	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.button_down.connect(_on_button_down)
	click_button.button_up.connect(_on_button_up)
	click_button.pressed.connect(_on_pressed)
	
	# Set pivot for panel scaling
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	
	# Initialize visuals
	hover_glow.modulate.a = 0.0
	_set_hover_intensity(0.0)

func _update_ui():
	if app_label:
		app_label.text = app_name
	if icon_rect:
		if icon_texture:
			icon_rect.texture = icon_texture
		else:
			pass

func _on_mouse_entered():
	app_hovered.emit(app_name, color_preset)
	if hover_sound_stream:
		hover_sound.play()
	
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		
	_hover_tween = create_tween().set_parallel(true)
	
	_hover_tween.tween_property(hover_glow, "modulate:a", 0.12, 0.2).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_method(_set_hover_intensity, _get_hover_intensity(), 1.0, 0.2).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(panel, "scale", Vector2(1.04, 1.04), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_hover_tween.tween_property(icon_rect, "modulate", Color(0.5, 1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	app_unhovered.emit()
	
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		
	_hover_tween = create_tween().set_parallel(true)
	
	_hover_tween.tween_property(hover_glow, "modulate:a", 0.0, 0.15).set_ease(Tween.EASE_IN)
	_hover_tween.tween_method(_set_hover_intensity, _get_hover_intensity(), 0.0, 0.15).set_ease(Tween.EASE_IN)
	_hover_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
	_hover_tween.tween_property(icon_rect, "modulate", Color(1.0, 1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)

func _on_button_down():
	if click_sound_stream:
		click_sound.play()
		
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
		
	_press_tween = create_tween()
	_press_tween.tween_property(panel, "scale", Vector2(0.96, 0.96), 0.1).set_ease(Tween.EASE_OUT)

func _on_button_up():
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
		
	_press_tween = create_tween()
	var target_scale = Vector2(1.04, 1.04) if click_button.is_hovered() else Vector2(1.0, 1.0)
	_press_tween.tween_property(panel, "scale", target_scale, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_pressed():
	pressed.emit()
	
	if target_scene != "":
		var laptops = get_tree().get_nodes_in_group("laptop_ui")
		if laptops.size() > 0:
			laptops[0].change_scene(target_scene, 0.5)

func _set_hover_intensity(intensity: float):
	var mat = border_glow.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("hover_intensity", intensity)
		
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if intensity > 0.5:
			style.bg_color = Color(0, 0.15, 0.2, 0.95)
		else:
			style.bg_color = Color(0.01, 0.03, 0.06, 0.9)

func _get_hover_intensity() -> float:
	var mat = border_glow.material as ShaderMaterial
	if mat:
		return mat.get_shader_parameter("hover_intensity")
	return 0.0

func set_border_color(color: Color):
	var mat = border_glow.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("border_color", color)

func set_bg_glow_color(color: Color):
	hover_glow.color = color

func set_app_name_color(color: Color):
	app_label.add_theme_color_override("font_color", color)
