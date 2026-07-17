extends Control

@onready var clock_label: Label = $BottomBar/Clock
@onready var time_timer: Timer = $TimeTimer
@onready var tagline_label: Label = $HeaderSection/Tagline
@onready var app_grid: GridContainer = $AppGrid
@onready var background: TextureRect = $Background
@onready var mouse_glow: Sprite2D = $MouseGlow
@onready var header_section: VBoxContainer = $HeaderSection
@onready var bottom_bar: HBoxContainer = $BottomBar
@onready var status_label: Label = $BottomBar/StatusText
@onready var data_particles: CPUParticles2D = $DataParticles

var parallax_strength_bg := 15.0
var parallax_strength_grid := 20.0
var _bg_base_pos: Vector2
var _grid_base_pos: Vector2

var color_presets: Dictionary = {
	"default": {
		"tagline_color":		Color(0, 0.9, 1, 1),
		"clock_color":		  Color(0, 0.9, 1, 1),
		"status_color":		 Color(0, 0.9, 1, 0.4),
		"background_modulate":  Color(0.094, 0.155, 0.214, 0.502),
		"mouse_glow_color":	 Color(0, 0.9, 1, 0.15),
		"particle_color":	   Color(0, 0.9, 1, 0.4),
		"border_glow_color":	Color(0, 0.9, 1, 1),
		"button_bg_glow_color": Color(0, 0.9, 1, 1),
		"app_name_color":	   Color(1, 1, 1, 1),
	},
	"crimson": {
		"tagline_color":		Color(1.0, 0.3, 0.2, 1),
		"clock_color":		  Color(1.0, 0.4, 0.3, 1),
		"status_color":		 Color(1.0, 0.3, 0.2, 0.4),
		"background_modulate":  Color(0.214, 0.094, 0.094, 0.502),
		"mouse_glow_color":	 Color(1.0, 0.3, 0.2, 0.15),
		"particle_color":	   Color(1.0, 0.3, 0.2, 0.4),
		"border_glow_color":	Color(1.0, 0.3, 0.2, 1),
		"button_bg_glow_color": Color(1.0, 0.3, 0.2, 1),
		"app_name_color":	   Color(1.0, 0.662, 0.548, 1.0),
	},
	"emerald": {
		"tagline_color":		Color(0.2, 1.0, 0.5, 1),
		"clock_color":		  Color(0.3, 1.0, 0.6, 1),
		"status_color":		 Color(0.2, 1.0, 0.5, 0.4),
		"background_modulate":  Color(0.094, 0.214, 0.12, 0.502),
		"mouse_glow_color":	 Color(0.2, 1.0, 0.5, 0.15),
		"particle_color":	   Color(0.2, 1.0, 0.5, 0.4),
		"border_glow_color":	Color(0.2, 1.0, 0.5, 1),
		"button_bg_glow_color": Color(0.2, 1.0, 0.5, 1),
		"app_name_color":	   Color(0.484, 1.0, 0.704, 1.0),
	},
}

var _current_preset: String = "default"
var _theme_tween: Tween = null

func _ready():
	_update_clock()
	time_timer.timeout.connect(_update_clock)
	time_timer.start()
	
	for child in app_grid.get_children():
		if child.has_signal("app_hovered"):
			child.app_hovered.connect(_on_app_hovered)
			child.app_unhovered.connect(_on_app_unhovered)
			
	# Save base positions for parallax
	_bg_base_pos = background.position
	_grid_base_pos = app_grid.position
	
	_play_entrance_animation()

func _play_entrance_animation():
	background.modulate.a = 0.0
	header_section.modulate.a = 0.0
	header_section.position.y -= 20
	bottom_bar.modulate.a = 0.0
	bottom_bar.position.y += 20
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(background, "modulate:a", 1.0, 0.5)
	
	tween.tween_property(header_section, "modulate:a", 1.0, 0.4).set_delay(0.2)
	tween.tween_property(header_section, "position:y", header_section.position.y + 20, 0.4).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(bottom_bar, "modulate:a", 1.0, 0.4).set_delay(0.2)
	tween.tween_property(bottom_bar, "position:y", bottom_bar.position.y - 20, 0.4).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var delay = 0.3
	for child in app_grid.get_children():
		child.scale = Vector2.ZERO
		child.modulate.a = 0.0
		child.pivot_offset = child.custom_minimum_size / 2.0
		tween.tween_property(child, "modulate:a", 1.0, 0.2).set_delay(delay)
		tween.tween_property(child, "scale", Vector2(1.0, 1.0), 0.4).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		delay += 0.1

func _process(delta):
	var mouse_pos = get_local_mouse_position()
	mouse_glow.position = mouse_pos
	
	var center = size / 2.0
	var offset = (mouse_pos - center) / center
	
	var target_bg_pos = _bg_base_pos - offset * parallax_strength_bg
	var target_grid_pos = _grid_base_pos + offset * parallax_strength_grid
	
	background.position = background.position.lerp(target_bg_pos, 5.0 * delta)
	app_grid.position = app_grid.position.lerp(target_grid_pos, 8.0 * delta)

func _update_clock():
	var time_dict = Time.get_time_dict_from_system()
	var hour = time_dict.hour
	var minute = time_dict.minute
	clock_label.text = "%02d:%02d" % [hour, minute]

var _text_tween: Tween = null

func _animate_tagline(new_text: String, is_highlight: bool):
	if tagline_label.text == new_text:
		return
		
	tagline_label.text = new_text
	tagline_label.pivot_offset = Vector2(0, tagline_label.size.y / 2)
	
	if _text_tween and _text_tween.is_valid():
		_text_tween.kill()
		
	_text_tween = create_tween().set_parallel(true)
	
	if is_highlight:
		tagline_label.scale = Vector2(1.3, 1.3)
		tagline_label.modulate = Color(2.0, 2.0, 2.0, 1.5)
		_text_tween.tween_property(tagline_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_text_tween.tween_property(tagline_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)
	else:
		tagline_label.scale = Vector2(0.9, 0.9)
		tagline_label.modulate = Color(0.8, 0.8, 0.8, 0.8)
		_text_tween.tween_property(tagline_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_text_tween.tween_property(tagline_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT)

func apply_theme(preset: String, animation_time: float) -> void:
	if not color_presets.has(preset):
		print("Warning: Color preset '%s' not found!" % preset)
		return
		
	_current_preset = preset
	var target = color_presets[preset]
	
	if _theme_tween and _theme_tween.is_valid():
		_theme_tween.kill()
		
	_theme_tween = create_tween().set_parallel(true)
	
	var cur_tagline = tagline_label.get_theme_color("font_color") if tagline_label.has_theme_color_override("font_color") else Color(0, 0.9, 1, 0.6)
	_theme_tween.tween_method(_set_tagline_color, cur_tagline, target["tagline_color"], animation_time)
	
	var cur_clock = clock_label.get_theme_color("font_color") if clock_label.has_theme_color_override("font_color") else Color(0, 0.9, 1, 1)
	_theme_tween.tween_method(_set_clock_color, cur_clock, target["clock_color"], animation_time)
	
	var cur_status = status_label.get_theme_color("font_color") if status_label.has_theme_color_override("font_color") else Color(0, 0.9, 1, 0.4)
	_theme_tween.tween_method(_set_status_color, cur_status, target["status_color"], animation_time)
	
	_theme_tween.tween_property(background, "modulate", target["background_modulate"], animation_time)
	
	var grad = mouse_glow.texture.gradient
	var start_color = grad.get_color(0)
	_theme_tween.tween_method(_set_mouse_glow_color, start_color, target["mouse_glow_color"], animation_time)
	
	_theme_tween.tween_property(data_particles, "color", target["particle_color"], animation_time)
	
	for child in app_grid.get_children():
		if child.has_method("set_border_color"):
			var border_mat = child.border_glow.material as ShaderMaterial
			var start_border = border_mat.get_shader_parameter("border_color")
			_theme_tween.tween_method(child.set_border_color, start_border, target["border_glow_color"], animation_time)
			
			var start_bg = child.hover_glow.color
			_theme_tween.tween_method(child.set_bg_glow_color, start_bg, target["button_bg_glow_color"], animation_time)
			
			var start_text = child.app_label.get_theme_color("font_color") if child.app_label.has_theme_color_override("font_color") else Color(1, 1, 1, 1)
			_theme_tween.tween_method(child.set_app_name_color, start_text, target["app_name_color"], animation_time)

func _set_tagline_color(color: Color):
	tagline_label.add_theme_color_override("font_color", color)

func _set_clock_color(color: Color):
	clock_label.add_theme_color_override("font_color", color)
	
func _set_status_color(color: Color):
	status_label.add_theme_color_override("font_color", color)

func _set_mouse_glow_color(color: Color):
	mouse_glow.texture.gradient.set_color(0, color)

func _on_app_hovered(app_name: String, color_preset: String = "default"):
	_animate_tagline("◇ SELECTED: " + app_name, true)
	apply_theme(color_preset, 0.3)

func _on_app_unhovered():
	_animate_tagline("◇ SELECT MODULE", false)
	apply_theme("default", 0.2)
