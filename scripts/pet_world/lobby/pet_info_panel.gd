extends CanvasLayer

class_name PetInfoPanel

signal pet_action_requested(pet_node: Node)

const PANEL_WIDTH  := 280.0
const PANEL_HEIGHT := 410.0
const SLIDE_TIME   := 0.26
const PET_COOLDOWN := 5.0
const _SF          := 4.0   # scale-up factor for crisp text on itch.io web export

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

var _hover_sfx: AudioStreamPlayer
var _click_sfx: AudioStreamPlayer

func _ready() -> void:
	layer = 20

	_hover_sfx = AudioStreamPlayer.new()
	_hover_sfx.stream = preload("res://assets/sounds/other_ui/other_ui_hover.mp3")
	add_child(_hover_sfx)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = preload("res://assets/sounds/other_ui/other_ui_click.mp3")
	add_child(_click_sfx)

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
	_portrait_label.text  = data.get("icon", "❓")
	_name_label.text      = data.get("name", "???")
	_species_label.text   = data.get("species", "Unknown")
	_desc_label.text      = data.get("description", "A mysterious companion.")
	_level_label.text     = "Level  %d" % data.get("level", 1)
	var hp: int           = data.get("happiness", 50)
	_happiness_bar.value  = hp
	_happiness_pct.text   = "%d%%" % hp
	_portrait_sb.bg_color = data.get("icon_color", Color(0.95, 0.80, 0.55))

	if GameGlobal and GameGlobal.current_story_state < GameGlobal.StoryState.PHASE4_TASK_JOIN_TOURNAMENT:
		_tourn_btn.disabled = true
	else:
		_tourn_btn.disabled = false

func _slide_in() -> void:
	if _tween:
		_tween.kill()
	_card.offset_left  = 20.0
	_card.offset_right = PANEL_WIDTH * _SF + 40.0
	_card.modulate.a   = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_card, "offset_left",  -(PANEL_WIDTH * _SF + 20.0), SLIDE_TIME)
	_tween.tween_property(_card, "offset_right", -20.0,                       SLIDE_TIME)
	_tween.tween_property(_card, "modulate:a",   1.0, SLIDE_TIME * 0.65)

func _slide_out() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_card, "offset_left",  20.0,                      SLIDE_TIME * 0.8)
	_tween.tween_property(_card, "offset_right", PANEL_WIDTH * _SF + 40.0,  SLIDE_TIME * 0.8)
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

func _on_btn_hover(btn: Button) -> void:
	if _hover_sfx:
		_hover_sfx.play()
	btn.pivot_offset = btn.size / 2.0
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)

func _on_btn_exit(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_btn_click() -> void:
	if _click_sfx:
		_click_sfx.play()

# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Emoji font fallback — fixes 🐱 🐍 🐾 ⭐ 🏆 rendering in web/itch export
	var emoji_file : FontFile = load("res://assets/fonts/Noto_Color_Emoji/NotoColorEmoji-Regular.ttf")
	var emoji_font := SystemFont.new()
	emoji_font.fallbacks = [emoji_file]

	_card = PanelContainer.new()
	_card.name          = "Card"
	_card.anchor_left   = 1.0
	_card.anchor_right  = 1.0
	_card.anchor_top    = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left   = -(PANEL_WIDTH  * _SF + 20.0)
	_card.offset_right  = -20.0
	_card.offset_top    = -(PANEL_HEIGHT * _SF * 0.5)
	_card.offset_bottom =  (PANEL_HEIGHT * _SF * 0.5)
	# Card is laid out at 4× size then scaled down — text renders at high res and downscales crisp
	_card.scale        = Vector2(1.0 / _SF, 1.0 / _SF)
	_card.pivot_offset = Vector2(PANEL_WIDTH * _SF, PANEL_HEIGHT * _SF * 0.5)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color             = Color(0.98, 0.95, 0.88)
	card_sb.border_color         = Color(0.80, 0.70, 0.50, 0.55)
	card_sb.set_border_width_all(roundi(2 * _SF))
	card_sb.set_corner_radius_all(roundi(14 * _SF))
	card_sb.shadow_color  = Color(0.10, 0.06, 0.02, 0.22)
	card_sb.shadow_size   = roundi(10 * _SF)
	card_sb.shadow_offset = Vector2(2.0 * _SF, 4.0 * _SF)
	_card.add_theme_stylebox_override("panel", card_sb)
	add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   roundi(22 * _SF))
	margin.add_theme_constant_override("margin_right",  roundi(22 * _SF))
	margin.add_theme_constant_override("margin_top",    roundi(18 * _SF))
	margin.add_theme_constant_override("margin_bottom", roundi(18 * _SF))
	_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", roundi(10 * _SF))
	margin.add_child(vbox)

	_add_portrait_row(vbox, emoji_font)
	_add_separator(vbox, Color(0.78, 0.67, 0.49, 0.50))
	_add_desc(vbox, emoji_font)
	_add_level_row(vbox, emoji_font)
	_add_happiness(vbox, emoji_font)
	_add_spacer(vbox, 6.0 * _SF)
	_add_buttons(vbox, emoji_font)

func _add_portrait_row(parent: VBoxContainer, ef: Font) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(14 * _SF))
	parent.add_child(row)

	_portrait_bg = PanelContainer.new()
	_portrait_bg.custom_minimum_size = Vector2(60.0 * _SF, 60.0 * _SF)
	_portrait_sb = StyleBoxFlat.new()
	_portrait_sb.bg_color = Color(0.95, 0.80, 0.55)
	_portrait_sb.set_corner_radius_all(roundi(30 * _SF))
	_portrait_bg.add_theme_stylebox_override("panel", _portrait_sb)
	row.add_child(_portrait_bg)

	_portrait_label = Label.new()
	_portrait_label.layout_mode          = 2
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", roundi(28 * _SF))
	_portrait_label.add_theme_font_override("font", ef)
	_portrait_bg.add_child(_portrait_label)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	name_col.add_theme_constant_override("separation", roundi(4 * _SF))
	row.add_child(name_col)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", roundi(20 * _SF))
	_name_label.add_theme_font_override("font", ef)
	_name_label.add_theme_color_override("font_color", Color(0.32, 0.18, 0.06))
	name_col.add_child(_name_label)

	_species_label = Label.new()
	_species_label.add_theme_font_size_override("font_size", roundi(11 * _SF))
	_species_label.add_theme_font_override("font", ef)
	_species_label.add_theme_color_override("font_color", Color(0.58, 0.43, 0.25))
	name_col.add_child(_species_label)

func _add_separator(parent: VBoxContainer, col: Color) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", col)
	parent.add_child(sep)

func _add_desc(parent: VBoxContainer, ef: Font) -> void:
	_desc_label = Label.new()
	_desc_label.add_theme_font_size_override("font_size", roundi(12 * _SF))
	_desc_label.add_theme_font_override("font", ef)
	_desc_label.add_theme_color_override("font_color", Color(0.40, 0.28, 0.14))
	_desc_label.autowrap_mode       = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0.0, 44.0 * _SF)
	parent.add_child(_desc_label)

func _add_level_row(parent: VBoxContainer, ef: Font) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(6 * _SF))
	parent.add_child(row)

	var star := Label.new()
	star.text = "⭐"
	star.add_theme_font_size_override("font_size", roundi(13 * _SF))
	star.add_theme_font_override("font", ef)
	row.add_child(star)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", roundi(13 * _SF))
	_level_label.add_theme_font_override("font", ef)
	_level_label.add_theme_color_override("font_color", Color(0.32, 0.18, 0.06))
	row.add_child(_level_label)

func _add_happiness(parent: VBoxContainer, ef: Font) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", roundi(5 * _SF))
	parent.add_child(section)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", roundi(5 * _SF))
	section.add_child(header)

	var paw := Label.new()
	paw.text = "🐾"
	paw.add_theme_font_size_override("font_size", roundi(12 * _SF))
	paw.add_theme_font_override("font", ef)
	header.add_child(paw)

	var title := Label.new()
	title.text = "Happiness"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", roundi(12 * _SF))
	title.add_theme_font_override("font", ef)
	title.add_theme_color_override("font_color", Color(0.40, 0.28, 0.14))
	header.add_child(title)

	_happiness_pct = Label.new()
	_happiness_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_happiness_pct.add_theme_font_size_override("font_size", roundi(11 * _SF))
	_happiness_pct.add_theme_font_override("font", ef)
	_happiness_pct.add_theme_color_override("font_color", Color(0.58, 0.43, 0.25))
	header.add_child(_happiness_pct)

	_happiness_bar = ProgressBar.new()
	_happiness_bar.min_value           = 0
	_happiness_bar.max_value           = 100
	_happiness_bar.value               = 50
	_happiness_bar.show_percentage     = false
	_happiness_bar.custom_minimum_size = Vector2(0.0, 13.0 * _SF)

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.82, 0.56, 0.22)
	fill_sb.set_corner_radius_all(roundi(6 * _SF))

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.84, 0.77, 0.63)
	bg_sb.set_corner_radius_all(roundi(6 * _SF))

	_happiness_bar.add_theme_stylebox_override("fill",       fill_sb)
	_happiness_bar.add_theme_stylebox_override("background", bg_sb)
	section.add_child(_happiness_bar)

func _add_spacer(parent: VBoxContainer, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0.0, h)
	parent.add_child(s)

func _add_buttons(parent: VBoxContainer, ef: Font) -> void:
	_pet_btn = Button.new()
	_pet_btn.text = "🐾  Pet"
	_pet_btn.custom_minimum_size = Vector2(0.0, 38.0 * _SF)
	_pet_btn.add_theme_font_size_override("font_size", roundi(14 * _SF))
	_pet_btn.add_theme_font_override("font", ef)
	_style_btn(_pet_btn, Color(0.90, 0.62, 0.28), Color(0.28, 0.14, 0.03))
	_pet_btn.pressed.connect(_on_pet_btn_pressed)
	_pet_btn.mouse_entered.connect(_on_btn_hover.bind(_pet_btn))
	_pet_btn.mouse_exited.connect(_on_btn_exit.bind(_pet_btn))
	_pet_btn.button_down.connect(_on_btn_click)
	parent.add_child(_pet_btn)

	_tourn_btn = Button.new()
	_tourn_btn.text = "🏆  Join Tournament"
	_tourn_btn.custom_minimum_size = Vector2(0.0, 36.0 * _SF)
	_tourn_btn.add_theme_font_size_override("font_size", roundi(13 * _SF))
	_tourn_btn.add_theme_font_override("font", ef)
	_style_btn(_tourn_btn, Color(0.52, 0.68, 0.42), Color(0.10, 0.28, 0.06))
	_tourn_btn.pressed.connect(_on_tourn_btn_pressed)
	_tourn_btn.mouse_entered.connect(_on_btn_hover.bind(_tourn_btn))
	_tourn_btn.mouse_exited.connect(_on_btn_exit.bind(_tourn_btn))
	_tourn_btn.button_down.connect(_on_btn_click)
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
		sb.bg_color              = styles[state]
		sb.content_margin_left   = 10.0 * _SF
		sb.content_margin_right  = 10.0 * _SF
		sb.content_margin_top    = 6.0  * _SF
		sb.content_margin_bottom = 6.0  * _SF
		sb.set_corner_radius_all(roundi(10 * _SF))
		btn.add_theme_stylebox_override(state, sb)

	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color     = bg.lightened(0.08)
	focus_sb.border_color = Color(fg.r, fg.g, fg.b, 0.7)
	focus_sb.set_border_width_all(roundi(2 * _SF))
	focus_sb.set_corner_radius_all(roundi(10 * _SF))
	btn.add_theme_stylebox_override("focus", focus_sb)

	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    fg)
	btn.add_theme_color_override("font_pressed_color",  fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.45))
