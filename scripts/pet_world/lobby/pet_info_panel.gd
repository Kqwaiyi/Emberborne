extends CanvasLayer

class_name PetInfoPanel

signal pet_action_requested(pet_node: Node)

const PANEL_WIDTH  := 280.0
const PANEL_HEIGHT := 410.0
const SLIDE_TIME   := 0.26
const PET_COOLDOWN := 5.0

var _current_pet: Node = null
var _cooldown    := 0.0
var _portrait_sb : StyleBoxFlat

# ui node refs
var _card             : PanelContainer
var _portrait_bg      : PanelContainer
var _portrait_label   : Label
var _name_label       : Label
var _species_label    : Label
var _desc_label       : Label
var _level_label      : Label
var _happiness_bar    : ProgressBar
var _happiness_pct    : Label
var _pet_btn          : Button
var _tourn_btn        : Button

var _tween: Tween

func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
		if _cooldown <= 0.0:
			_cooldown = 0.0
			_pet_btn.disabled = false
			_pet_btn.text = "🐾  Pet"
		else:
			_pet_btn.text = "🐾  Pet  (%.0fs)" % ceilf(_cooldown)

func show_pet(data: Dictionary, pet_node: Node) -> void:
	if _current_pet != pet_node:
		_cooldown = 0.0
		_pet_btn.disabled = false
		_pet_btn.text = "🐾  Pet"
	_current_pet = pet_node
	_update_display(data)
	if not visible:
		visible = true
		_slide_in()
	else:
		var tw := create_tween()
		tw.tween_property(_card, "modulate:a", 0.55, 0.07)
		tw.tween_property(_card, "modulate:a", 1.0,  0.13)

func hide_panel() -> void:
	if not visible:
		return
	_slide_out()

func _update_display(data: Dictionary) -> void:
	_portrait_label.text = data.get("icon", "❓")
	_name_label.text     = data.get("name", "???")
	_species_label.text  = data.get("species", "Unknown")
	_desc_label.text     = data.get("description", "A mysterious companion.")
	_level_label.text    = "Level  %d" % data.get("level", 1)
	var hp: int          = data.get("happiness", 50)
	_happiness_bar.value = hp
	_happiness_pct.text  = "%d%%" % hp
	_portrait_sb.bg_color = data.get("icon_color", Color(0.95, 0.80, 0.55))
	
	if GameGlobal and GameGlobal.current_story_state < GameGlobal.StoryState.PHASE4_TASK_JOIN_TOURNAMENT:
		_tourn_btn.disabled = true
	else:
		_tourn_btn.disabled = false

func _slide_in() -> void:
	if _tween:
		_tween.kill()
	_card.offset_left  = 20.0
	_card.offset_right = PANEL_WIDTH + 40.0
	_card.modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "offset_left",  -(PANEL_WIDTH + 20.0), SLIDE_TIME)
	_tween.tween_property(_card, "offset_right", -20.0,                 SLIDE_TIME)
	_tween.tween_property(_card, "modulate:a",   1.0, SLIDE_TIME * 0.65)

func _slide_out() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_card, "offset_left",  20.0,              SLIDE_TIME * 0.8)
	_tween.tween_property(_card, "offset_right", PANEL_WIDTH + 40.0, SLIDE_TIME * 0.8)
	_tween.tween_property(_card, "modulate:a",   0.0, SLIDE_TIME * 0.55)
	var fin := create_tween()
	fin.tween_interval(SLIDE_TIME * 0.8)
	fin.tween_callback(func(): visible = false)

func _on_pet_btn_pressed() -> void:
	if _current_pet == null or _cooldown > 0.0:
		return
	_cooldown = PET_COOLDOWN
	_pet_btn.disabled = true
	if _current_pet.has_method("force_idle"):
		_current_pet.force_idle(3.0)
	pet_action_requested.emit(_current_pet)

func _on_tourn_btn_pressed() -> void:
	if _current_pet == null:
		return
		
	var target_scene := ""
	if _current_pet.name == "Cat":
		target_scene = GameState.get_resume_level("")
	elif _current_pet.name == "Snake":
		target_scene = GlobalSnaketower.get_resume_level("")
		
	if target_scene != "":
		var laptops = get_tree().get_nodes_in_group("laptop_ui")
		if laptops.size() > 0:
			laptops[0].change_scene(target_scene, 0.5)
		else:
			if SceneManager.has_method("change_scene_to_file"):
				SceneManager.change_scene_to_file(target_scene, 0.5)
			else:
				get_tree().change_scene_to_file(target_scene)

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	_card = PanelContainer.new()
	_card.name = "Card"
	_card.anchor_left   = 1.0
	_card.anchor_right  = 1.0
	_card.anchor_top    = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left   = -(PANEL_WIDTH + 20.0)
	_card.offset_right  = -20.0
	_card.offset_top    = -(PANEL_HEIGHT * 0.5)
	_card.offset_bottom =  (PANEL_HEIGHT * 0.5)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color             = Color(0.98, 0.95, 0.88)
	card_sb.border_color         = Color(0.80, 0.70, 0.50, 0.55)
	card_sb.set_border_width_all(2)
	card_sb.set_corner_radius_all(14)
	card_sb.shadow_color  = Color(0.10, 0.06, 0.02, 0.22)
	card_sb.shadow_size   = 10
	card_sb.shadow_offset = Vector2(2.0, 4.0)
	_card.add_theme_stylebox_override("panel", card_sb)
	add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   22)
	margin.add_theme_constant_override("margin_right",  22)
	margin.add_theme_constant_override("margin_top",    18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_add_portrait_row(vbox)
	_add_separator(vbox, Color(0.78, 0.67, 0.49, 0.50))
	_add_desc(vbox)
	_add_level_row(vbox)
	_add_happiness(vbox)
	_add_spacer(vbox, 6)
	_add_buttons(vbox)

func _add_portrait_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	_portrait_bg = PanelContainer.new()
	_portrait_bg.custom_minimum_size = Vector2(60, 60)
	_portrait_sb = StyleBoxFlat.new()
	_portrait_sb.bg_color = Color(0.95, 0.80, 0.55)
	_portrait_sb.set_corner_radius_all(30)
	_portrait_bg.add_theme_stylebox_override("panel", _portrait_sb)
	row.add_child(_portrait_bg)

	_portrait_label = Label.new()
	_portrait_label.layout_mode = 2
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 28)
	_portrait_bg.add_child(_portrait_label)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	name_col.add_theme_constant_override("separation", 4)
	row.add_child(name_col)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", Color(0.32, 0.18, 0.06))
	name_col.add_child(_name_label)

	_species_label = Label.new()
	_species_label.add_theme_font_size_override("font_size", 11)
	_species_label.add_theme_color_override("font_color", Color(0.58, 0.43, 0.25))
	name_col.add_child(_species_label)

func _add_separator(parent: VBoxContainer, col: Color) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", col)
	parent.add_child(sep)

func _add_desc(parent: VBoxContainer) -> void:
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", 12)
	_desc_label.add_theme_color_override("font_color", Color(0.40, 0.28, 0.14))
	_desc_label.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0, 44)
	parent.add_child(_desc_label)

func _add_level_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var star := Label.new()
	star.text = "⭐"
	star.add_theme_font_size_override("font_size", 13)
	row.add_child(star)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 13)
	_level_label.add_theme_color_override("font_color", Color(0.32, 0.18, 0.06))
	row.add_child(_level_label)

func _add_happiness(parent: VBoxContainer) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	parent.add_child(section)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	section.add_child(header)

	var paw := Label.new()
	paw.text = "🐾"
	paw.add_theme_font_size_override("font_size", 12)
	header.add_child(paw)

	var title := Label.new()
	title.text = "Happiness"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.40, 0.28, 0.14))
	header.add_child(title)

	_happiness_pct = Label.new()
	_happiness_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_happiness_pct.add_theme_font_size_override("font_size", 11)
	_happiness_pct.add_theme_color_override("font_color", Color(0.58, 0.43, 0.25))
	header.add_child(_happiness_pct)

	_happiness_bar = ProgressBar.new()
	_happiness_bar.min_value          = 0
	_happiness_bar.max_value          = 100
	_happiness_bar.value              = 50
	_happiness_bar.show_percentage    = false
	_happiness_bar.custom_minimum_size = Vector2(0, 13)

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.82, 0.56, 0.22)
	fill_sb.set_corner_radius_all(6)

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.84, 0.77, 0.63)
	bg_sb.set_corner_radius_all(6)

	_happiness_bar.add_theme_stylebox_override("fill",       fill_sb)
	_happiness_bar.add_theme_stylebox_override("background", bg_sb)
	section.add_child(_happiness_bar)

func _add_spacer(parent: VBoxContainer, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)

func _add_buttons(parent: VBoxContainer) -> void:
	_pet_btn = Button.new()
	_pet_btn.text = "🐾  Pet"
	_pet_btn.custom_minimum_size = Vector2(0, 38)
	_pet_btn.add_theme_font_size_override("font_size", 14)
	_style_btn(_pet_btn, Color(0.90, 0.62, 0.28), Color(0.28, 0.14, 0.03))
	_pet_btn.pressed.connect(_on_pet_btn_pressed)
	parent.add_child(_pet_btn)

	_tourn_btn = Button.new()
	_tourn_btn.text = "🏆  Join Tournament"
	_tourn_btn.custom_minimum_size = Vector2(0, 36)
	_tourn_btn.add_theme_font_size_override("font_size", 13)
	_style_btn(_tourn_btn, Color(0.52, 0.68, 0.42), Color(0.10, 0.28, 0.06))
	_tourn_btn.pressed.connect(_on_tourn_btn_pressed)
	parent.add_child(_tourn_btn)

func _style_btn(btn: Button, bg: Color, fg: Color) -> void:
	var styles := {
		"normal":   bg,
		"hover":    bg.lightened(0.10),
		"pressed":  bg.darkened(0.12),
		"disabled": Color(bg.r, bg.g, bg.b, 0.42),
	}
	for state in styles:
		var sb := StyleBoxFlat.new()
		sb.bg_color = styles[state]
		sb.set_corner_radius_all(10)
		sb.content_margin_left   = 10
		sb.content_margin_right  = 10
		sb.content_margin_top    = 6
		sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override(state, sb)

	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = bg.lightened(0.08)
	focus_sb.border_color = Color(fg.r, fg.g, fg.b, 0.7)
	focus_sb.set_border_width_all(2)
	focus_sb.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("focus", focus_sb)

	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    fg)
	btn.add_theme_color_override("font_pressed_color",  fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.45))
