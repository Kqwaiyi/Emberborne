class_name CutsceneMessenger
extends Control

@export var sfx_incoming: AudioStream = null
@export var sfx_typing: AudioStream = null
@export var sfx_outgoing: AudioStream = null

# ═══════════════════════════════════════════════════════════════════════
# CUTSCENE MESSENGER
# A futuristic texting-app scene that displays cutscene lines as chat
# bubbles inside the LaptopUI SubViewport. Architecture mirrors
# DialogueManager: load script → index → step → advance → finish.
# ═══════════════════════════════════════════════════════════════════════

# ─── Cutscene Registry ───────────────────────────────────────────────
# Maps string keys → res:// paths to cutscene .gd data files.
const CUTSCENE_PATHS: Dictionary = {
	"test": "res://scenes/ui/cutscenes/test_cutscene.gd",
}

# ─── Color Palette (gray-green, WhatsApp-inspired, sci-fi) ──────────
const COLOR_BACKGROUND      := Color("0B1410")
const COLOR_HEADER_BG       := Color("1A2C23")
const COLOR_HEADER_TEXT     := Color("8DCEA0")
const COLOR_BUBBLE_INCOMING := Color("1E3A2F")
const COLOR_BUBBLE_OUTGOING := Color("0A5C3A")
const COLOR_BUBBLE_TEXT     := Color("E0F0E8")
const COLOR_TIMESTAMP       := Color("6B9B80")
const COLOR_SCROLLBAR       := Color("2A4A3A")
const COLOR_ADVANCE_IND     := Color("8DCEA0")
const COLOR_SEPARATOR       := Color("1A2C23")

# ─── Layout Constants ────────────────────────────────────────────────
const HEADER_HEIGHT     := 56
const BUBBLE_MAX_WIDTH_RATIO := 0.85  # max bubble width as fraction of viewport
const BUBBLE_CORNER     := 12
const BUBBLE_TAIL_CORNER := 2
const BUBBLE_H_MARGIN   := 10
const BUBBLE_V_MARGIN   := 6
const BUBBLE_SPACING    := 6

# ─── Animation Constants ─────────────────────────────────────────────
const BUBBLE_ANIM_DURATION  := 0.25
const BUBBLE_FADE_DURATION  := 0.15
const INDICATOR_PULSE_SPEED := 0.5

# ─── Node References ─────────────────────────────────────────────────
var _background: ColorRect
var _header_bar: PanelContainer
var _back_button: TextureButton
var _profile_picture: TextureRect
var _sender_name: Label
var _voice_call_icon: TextureRect
var _video_call_icon: TextureRect
var _menu_icon: TextureRect
var _chat_scroll: ScrollContainer
var _chat_vbox: VBoxContainer
var _advance_indicator: Label

# ─── Playback State ──────────────────────────────────────────────────
var _lines: Array = []
var _sender_data: Dictionary = {}
var _current_index: int = 0
var _current_key: String = ""
var _is_playing: bool = false
var _is_processing_bubble: bool = false
var _bubble_tween: Tween = null
var _typing_tween: Tween = null
var _expand_tween: Tween = null
var _decrypt_tween: Tween = null
var _indicator_tween: Tween = null
var _current_bubble_node: Control = null  # Reference to the bubble being animated
var _audio_incoming: AudioStreamPlayer
var _audio_typing: AudioStreamPlayer
var _audio_outgoing: AudioStreamPlayer

var _audio_back_hover: AudioStreamPlayer
var _audio_back_click: AudioStreamPlayer
var _back_button_tween: Tween = null

# ─── Completion Tracking ─────────────────────────────────────────────
# Static var persists across scene loads within a single game session.
static var _completed_cutscenes: Dictionary = {}

# ─── External Queueing API ───────────────────────────────────────────
static var queued_cutscene_key: String = "test"
static var has_unread_cutscene: bool = true

## Call this to queue up the next cutscene to be played in the messenger.
## If connected, this will trigger the desktop icon notification badge.
static func queue_cutscene(key: String) -> void:
	queued_cutscene_key = key
	if not _completed_cutscenes.has(key):
		has_unread_cutscene = true
	else:
		has_unread_cutscene = false


func _ready() -> void:
	_build_ui()
	_advance_indicator.hide()

	# Automatically open the queued cutscene
	if queued_cutscene_key != "":
		# Defer to ensure the scene tree is fully set up
		call_deferred("open_scene", queued_cutscene_key)


# ═══════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════

## Opens and plays (or redisplays) a cutscene by its dictionary key.
## Call this after the scene has been loaded into the SubViewport.
func open_scene(key: String) -> void:
	if not CUTSCENE_PATHS.has(key):
		push_error("CutsceneMessenger: Unknown cutscene key: " + key)
		return

	_current_key = key
	var script = load(CUTSCENE_PATHS[key])
	if script == null:
		push_error("CutsceneMessenger: Failed to load cutscene script: " + CUTSCENE_PATHS[key])
		return

	_sender_data = script.get_sender()
	_lines = script.get_lines()

	# Pre-calculate timestamps based on real system time
	var time_dict = Time.get_time_dict_from_system()
	var current_hour = time_dict.hour
	var current_minute = time_dict.minute
	
	for i in range(_lines.size()):
		_lines[i]["timestamp"] = "%02d:%02d" % [current_hour, current_minute]
		# Add 1 to 3 minutes random offset for next message
		var offset = (randi() % 3) + 1
		current_minute += offset
		if current_minute >= 60:
			current_minute = current_minute % 60
			current_hour = (current_hour + 1) % 24

	# Populate header bar
	_sender_name.text = _sender_data.get("name", "Unknown")
	var pfp_path: String = _sender_data.get("profile_picture", "")
	if pfp_path != "" and ResourceLoader.exists(pfp_path):
		_profile_picture.texture = load(pfp_path)

	# Check if already completed
	if _is_cutscene_completed(key):
		if key == queued_cutscene_key:
			has_unread_cutscene = false
		_display_full_history()
	else:
		_start_playback(key)


# ═══════════════════════════════════════════════════════════════════════
# INPUT HANDLING (mirrors DialogueManager._input)
# ═══════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not _is_playing:
		return

	if event.is_action_pressed("dialogue_advance"):
		if _is_processing_bubble:
			_complete_bubble_animation()
		else:
			_advance_indicator.hide()
			_stop_indicator_animation()
			_display_next_bubble()
		get_viewport().set_input_as_handled()


# ═══════════════════════════════════════════════════════════════════════
# PLAYBACK LOGIC
# ═══════════════════════════════════════════════════════════════════════

func _is_cutscene_completed(key: String) -> bool:
	return _completed_cutscenes.has(key)

func _mark_cutscene_completed(key: String) -> void:
	_completed_cutscenes[key] = true
	if key == queued_cutscene_key:
		has_unread_cutscene = false

func _start_playback(_key: String) -> void:
	_current_index = 0
	_is_playing = true
	_display_next_bubble()

func _display_next_bubble() -> void:
	if _current_index >= _lines.size():
		_finish_playback()
		return

	_is_processing_bubble = true
	var line = _lines[_current_index]
	var sender = line.get("sender", "them")
	var bubble = _create_bubble(line)
	
	var msg_label = bubble.find_child("MessageLabel", true, false)
	var time_label = bubble.find_child("TimeLabel", true, false)
	time_label.hide()
	
	if sender == "them":
		msg_label.text = "typing..."
	else:
		msg_label.text = _scramble_string(line.get("text", ""))
		
	_chat_vbox.add_child(bubble)
	_current_index += 1

	# Animate the bubble pop-in
	_play_bubble_animation(bubble, sender)

func _finish_playback() -> void:
	_is_playing = false
	_mark_cutscene_completed(_current_key)
	_advance_indicator.hide()
	_stop_indicator_animation()
	_scroll_to_bottom()

func _display_full_history() -> void:
	for line in _lines:
		var bubble = _create_bubble(line)
		_chat_vbox.add_child(bubble)
	_is_playing = false
	# Wait a frame for layout then scroll
	await get_tree().process_frame
	_scroll_to_bottom()


# ═══════════════════════════════════════════════════════════════════════
# BUBBLE CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════

func _create_bubble(line: Dictionary) -> Control:
	var sender: String = line.get("sender", "them")
	var text: String = line.get("text", "")
	var is_me: bool = (sender == "me")

	# ── Outer MarginContainer (horizontal padding from edges) ────────
	var outer = MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 12)
	outer.add_theme_constant_override("margin_right", 12)
	outer.add_theme_constant_override("margin_top", BUBBLE_SPACING / 2)
	outer.add_theme_constant_override("margin_bottom", BUBBLE_SPACING / 2)
	
	outer.set_meta("final_text", text)
	outer.set_meta("sender", sender)

	# ── HBoxContainer for alignment ─────────────────────────────────
	var hbox = HBoxContainer.new()
	outer.add_child(hbox)

	# Spacer for alignment (push bubble to left or right)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ── Bubble PanelContainer ────────────────────────────────────────
	var bubble_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BUBBLE_OUTGOING if is_me else COLOR_BUBBLE_INCOMING
	style.corner_radius_top_left = BUBBLE_TAIL_CORNER if not is_me else BUBBLE_CORNER
	style.corner_radius_top_right = BUBBLE_TAIL_CORNER if is_me else BUBBLE_CORNER
	style.corner_radius_bottom_left = BUBBLE_CORNER
	style.corner_radius_bottom_right = BUBBLE_CORNER
	style.content_margin_left = BUBBLE_H_MARGIN
	style.content_margin_right = BUBBLE_H_MARGIN
	style.content_margin_top = BUBBLE_V_MARGIN
	style.content_margin_bottom = BUBBLE_V_MARGIN
	style.shadow_color = Color(0.12, 0.23, 0.18, 0.6) if not is_me else Color(0.04, 0.36, 0.23, 0.6)
	style.shadow_size = 8
	bubble_panel.add_theme_stylebox_override("panel", style)

	# Calculate max bubble width
	var max_bubble_width: float = size.x * BUBBLE_MAX_WIDTH_RATIO
	bubble_panel.custom_minimum_size.x = 0  # Allow shrinking

	# ── Inner VBox (text + timestamp) ────────────────────────────────
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 2)
	bubble_panel.add_child(inner_vbox)

	# Calculate required width
	var font = ThemeDB.fallback_font
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var time_size = font.get_string_size(line.get("timestamp", "00:00"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var required_width = max(text_size.x, time_size.x) + 16 # padding
	var target_width = min(required_width, max_bubble_width)
	
	outer.set_meta("target_width", target_width)

	# Message text
	var msg_label = RichTextLabel.new()
	msg_label.name = "MessageLabel"
	msg_label.bbcode_enabled = true
	msg_label.text = text
	msg_label.fit_content = true
	msg_label.scroll_active = false
	
	if not _is_playing:
		msg_label.custom_minimum_size.x = target_width
	else:
		if is_me:
			msg_label.custom_minimum_size.x = target_width
		else:
			msg_label.custom_minimum_size.x = 60 # Start small for typing

	msg_label.add_theme_color_override("default_color", COLOR_BUBBLE_TEXT)
	msg_label.add_theme_font_size_override("normal_font_size", 13)
	msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(msg_label)

	# Decorative timestamp
	var time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.text = line.get("timestamp", "00:00")
	time_label.add_theme_color_override("font_color", COLOR_TIMESTAMP)
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(time_label)

	# ── Assemble alignment ───────────────────────────────────────────
	if is_me:
		hbox.add_child(spacer)
		hbox.add_child(bubble_panel)
	else:
		hbox.add_child(bubble_panel)
		hbox.add_child(spacer)

	return outer


# ═══════════════════════════════════════════════════════════════════════
# BUBBLE ANIMATION
# ═══════════════════════════════════════════════════════════════════════

func _play_bubble_animation(bubble: Control, sender: String) -> void:
	_current_bubble_node = bubble

	# Set initial state
	bubble.scale = Vector2(0.3, 0.3)
	bubble.modulate.a = 0.0

	# Set pivot point: bottom-left for incoming, bottom-right for outgoing
	# We need to wait a frame for the layout to compute the size
	await get_tree().process_frame

	if sender == "me":
		bubble.pivot_offset = Vector2(bubble.size.x, bubble.size.y)
	else:
		bubble.pivot_offset = Vector2(0, bubble.size.y)

	# Kill any previous bubble tween
	if _bubble_tween and _bubble_tween.is_valid():
		_bubble_tween.kill()

	_bubble_tween = create_tween().set_parallel(true)
	_bubble_tween.tween_property(bubble, "scale", Vector2(1.0, 1.0), BUBBLE_ANIM_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_bubble_tween.tween_property(bubble, "modulate:a", 1.0, BUBBLE_FADE_DURATION)\
		.set_ease(Tween.EASE_OUT)

	_bubble_tween.finished.connect(_on_bubble_animation_finished.bind(bubble, sender))
	_scroll_to_bottom()

func _on_bubble_animation_finished(bubble: Control, sender: String) -> void:
	if sender == "them":
		_start_typing_phase(bubble)
	else:
		_start_decrypt_phase(bubble)

func _start_typing_phase(bubble: Control) -> void:
	if _audio_typing and _audio_typing.stream:
		_audio_typing.play()
		
	var msg_label = bubble.find_child("MessageLabel", true, false)
	
	_typing_tween = create_tween().set_loops(3)
	_typing_tween.tween_callback(func(): msg_label.text = "typing.")
	_typing_tween.tween_interval(0.3)
	_typing_tween.tween_callback(func(): msg_label.text = "typing..")
	_typing_tween.tween_interval(0.3)
	_typing_tween.tween_callback(func(): msg_label.text = "typing...")
	_typing_tween.tween_interval(0.3)
	
	_typing_tween.finished.connect(func():
		if _audio_typing: _audio_typing.stop()
		_start_expand_phase(bubble)
	)

func _start_expand_phase(bubble: Control) -> void:
	var msg_label = bubble.find_child("MessageLabel", true, false)
	var target_width = bubble.get_meta("target_width", 250.0)
	
	_expand_tween = create_tween()
	_expand_tween.tween_property(msg_label, "custom_minimum_size:x", target_width, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	_expand_tween.finished.connect(func():
		_start_decrypt_phase(bubble)
	)

func _start_decrypt_phase(bubble: Control) -> void:
	var msg_label = bubble.find_child("MessageLabel", true, false)
	var time_label = bubble.find_child("TimeLabel", true, false)
	var final_text = bubble.get_meta("final_text", "")
	var sender = bubble.get_meta("sender", "them")
	
	msg_label.text = _scramble_string(final_text)
	
	_decrypt_tween = create_tween()
	_decrypt_tween.tween_method(_update_decrypt.bind(msg_label, final_text), 0.0, 1.0, 0.5)
	
	_decrypt_tween.finished.connect(func():
		msg_label.text = final_text
		if time_label: time_label.show()
		
		if sender == "me" and _audio_outgoing and _audio_outgoing.stream:
			_audio_outgoing.play()
		elif sender == "them" and _audio_incoming and _audio_incoming.stream:
			_audio_incoming.play()
			
		_is_processing_bubble = false
		_current_bubble_node = null
		_advance_indicator.show()
		_start_indicator_animation()
		_scroll_to_bottom()
	)

func _update_decrypt(progress: float, msg_label: RichTextLabel, final_text: String) -> void:
	var reveal_count = int(progress * final_text.length())
	var revealed = final_text.substr(0, reveal_count)
	var scrambled_len = final_text.length() - reveal_count
	var scrambled = _scramble_string(final_text.substr(reveal_count, scrambled_len))
	msg_label.text = revealed + scrambled

func _scramble_string(text: String) -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	var result = ""
	for i in text.length():
		if text[i] == " ":
			result += " "
		else:
			result += chars[randi() % chars.length()]
	return result

func _complete_bubble_animation() -> void:
	if _bubble_tween and _bubble_tween.is_valid():
		_bubble_tween.kill()
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	if _expand_tween and _expand_tween.is_valid():
		_expand_tween.kill()
	if _decrypt_tween and _decrypt_tween.is_valid():
		_decrypt_tween.kill()
		
	if _audio_typing: _audio_typing.stop()
		
	if _current_bubble_node and is_instance_valid(_current_bubble_node):
		_current_bubble_node.scale = Vector2(1.0, 1.0)
		_current_bubble_node.modulate.a = 1.0
		
		var msg_label = _current_bubble_node.find_child("MessageLabel", true, false)
		var time_label = _current_bubble_node.find_child("TimeLabel", true, false)
		if msg_label:
			msg_label.text = _current_bubble_node.get_meta("final_text", "")
			msg_label.custom_minimum_size.x = _current_bubble_node.get_meta("target_width", 250.0)
		if time_label:
			time_label.show()
			
	_is_processing_bubble = false
	_current_bubble_node = null
	_advance_indicator.show()
	_start_indicator_animation()
	_scroll_to_bottom()


# ═══════════════════════════════════════════════════════════════════════
# ADVANCE INDICATOR (mirrors DialogueOverlay indicator pattern)
# ═══════════════════════════════════════════════════════════════════════

func _start_indicator_animation() -> void:
	_stop_indicator_animation()
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(_advance_indicator, "modulate:a", 0.3, INDICATOR_PULSE_SPEED)
	_indicator_tween.tween_property(_advance_indicator, "modulate:a", 1.0, INDICATOR_PULSE_SPEED)

func _stop_indicator_animation() -> void:
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	_advance_indicator.modulate.a = 1.0


# ═══════════════════════════════════════════════════════════════════════
# AUTO-SCROLL
# ═══════════════════════════════════════════════════════════════════════

func _scroll_to_bottom() -> void:
	# Wait a frame for layout recalculation
	await get_tree().process_frame
	_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)


# ═══════════════════════════════════════════════════════════════════════
# BACK BUTTON
# ═══════════════════════════════════════════════════════════════════════

func _on_back_button_hovered() -> void:
	if _audio_back_hover and _audio_back_hover.stream:
		_audio_back_hover.play()
		
	if _back_button_tween and _back_button_tween.is_valid():
		_back_button_tween.kill()
	_back_button_tween = create_tween().set_parallel(true)
	_back_button_tween.tween_property(_back_button, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_back_button_tween.tween_property(_back_button, "modulate", Color(1.0, 1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

func _on_back_button_unhovered() -> void:
	if _back_button_tween and _back_button_tween.is_valid():
		_back_button_tween.kill()
	_back_button_tween = create_tween().set_parallel(true)
	_back_button_tween.tween_property(_back_button, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
	_back_button_tween.tween_property(_back_button, "modulate", COLOR_HEADER_TEXT, 0.15).set_ease(Tween.EASE_OUT)

func _on_back_button_down() -> void:
	if _audio_back_click and _audio_back_click.stream:
		_audio_back_click.play()
		
	if _back_button_tween and _back_button_tween.is_valid():
		_back_button_tween.kill()
	_back_button_tween = create_tween()
	_back_button_tween.tween_property(_back_button, "scale", Vector2(0.9, 0.9), 0.05).set_ease(Tween.EASE_OUT)

func _on_back_button_pressed() -> void:
	var laptops = get_tree().get_nodes_in_group("laptop_ui")
	if laptops.size() > 0:
		laptops[0].change_scene("res://scenes/ui/DesktopScreen.tscn", 0.5)


# ═══════════════════════════════════════════════════════════════════════
# UI CONSTRUCTION (programmatic)
# ═══════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# Root setup
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	# ── Background ───────────────────────────────────────────────────
	_background = ColorRect.new()
	_background.color = COLOR_BACKGROUND
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	# ── Main VBoxContainer (header + chat) ───────────────────────────
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# ── Header Bar ───────────────────────────────────────────────────
	_header_bar = PanelContainer.new()
	_header_bar.custom_minimum_size.y = HEADER_HEIGHT
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = COLOR_HEADER_BG
	header_style.content_margin_left = 8
	header_style.content_margin_right = 12
	header_style.content_margin_top = 4
	header_style.content_margin_bottom = 4
	# Add subtle bottom border
	header_style.border_width_bottom = 1
	header_style.border_color = COLOR_SEPARATOR
	_header_bar.add_theme_stylebox_override("panel", header_style)
	main_vbox.add_child(_header_bar)

	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 10)
	_header_bar.add_child(header_hbox)

	# Back button
	_back_button = TextureButton.new()
	_back_button.custom_minimum_size = Vector2(32, 32)
	_back_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_back_button.modulate = COLOR_HEADER_TEXT
	var back_icon_path = "res://assets/sprites/messenger/icon_back.png"
	if ResourceLoader.exists(back_icon_path):
		_back_button.texture_normal = load(back_icon_path)
	
	_back_button.pivot_offset = Vector2(16, 16)
	_back_button.mouse_entered.connect(_on_back_button_hovered)
	_back_button.mouse_exited.connect(_on_back_button_unhovered)
	_back_button.button_down.connect(_on_back_button_down)
	_back_button.pressed.connect(_on_back_button_pressed)
	header_hbox.add_child(_back_button)

	# Audio for back button
	_audio_back_hover = AudioStreamPlayer.new()
	var hover_stream = load("res://assets/sounds/futuristic_ui/Hover.mp3")
	if hover_stream:
		_audio_back_hover.stream = hover_stream
	_audio_back_hover.volume_db = -5.0
	add_child(_audio_back_hover)

	_audio_back_click = AudioStreamPlayer.new()
	var click_stream = load("res://assets/sounds/futuristic_ui/Click.mp3")
	if click_stream:
		_audio_back_click.stream = click_stream
	_audio_back_click.volume_db = -2.0
	add_child(_audio_back_click)

	# Profile picture
	_profile_picture = TextureRect.new()
	_profile_picture.custom_minimum_size = Vector2(36, 36)
	_profile_picture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_profile_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_hbox.add_child(_profile_picture)

	# Sender name
	_sender_name = Label.new()
	_sender_name.text = "Contact"
	_sender_name.add_theme_color_override("font_color", COLOR_HEADER_TEXT)
	_sender_name.add_theme_font_size_override("font_size", 16)
	header_hbox.add_child(_sender_name)

	# Spacer (pushes right icons to the right)
	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(header_spacer)

	# Voice call icon (decorative)
	_voice_call_icon = TextureRect.new()
	_voice_call_icon.custom_minimum_size = Vector2(24, 24)
	_voice_call_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_voice_call_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_voice_call_icon.modulate = COLOR_HEADER_TEXT
	_voice_call_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var voice_icon_path = "res://assets/sprites/messenger/icon_voice_call.png"
	if ResourceLoader.exists(voice_icon_path):
		_voice_call_icon.texture = load(voice_icon_path)
	header_hbox.add_child(_voice_call_icon)

	# Video call icon (decorative)
	_video_call_icon = TextureRect.new()
	_video_call_icon.custom_minimum_size = Vector2(24, 24)
	_video_call_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_video_call_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_video_call_icon.modulate = COLOR_HEADER_TEXT
	_video_call_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var video_icon_path = "res://assets/sprites/messenger/icon_video_call.png"
	if ResourceLoader.exists(video_icon_path):
		_video_call_icon.texture = load(video_icon_path)
	header_hbox.add_child(_video_call_icon)

	# Menu icon (decorative)
	_menu_icon = TextureRect.new()
	_menu_icon.custom_minimum_size = Vector2(24, 24)
	_menu_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_menu_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_menu_icon.modulate = COLOR_HEADER_TEXT
	_menu_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu_icon_path = "res://assets/sprites/messenger/icon_menu.png"
	if ResourceLoader.exists(menu_icon_path):
		_menu_icon.texture = load(menu_icon_path)
	header_hbox.add_child(_menu_icon)

	# ── Chat Scroll Area ─────────────────────────────────────────────
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# Style the scrollbar
	var scrollbar = _chat_scroll.get_v_scroll_bar()
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = COLOR_SCROLLBAR
	scroll_style.corner_radius_top_left = 3
	scroll_style.corner_radius_top_right = 3
	scroll_style.corner_radius_bottom_left = 3
	scroll_style.corner_radius_bottom_right = 3
	scrollbar.add_theme_stylebox_override("grabber", scroll_style)
	scrollbar.add_theme_stylebox_override("grabber_highlight", scroll_style)
	scrollbar.add_theme_stylebox_override("grabber_pressed", scroll_style)
	main_vbox.add_child(_chat_scroll)

	_chat_vbox = VBoxContainer.new()
	_chat_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_vbox.add_theme_constant_override("separation", 0)
	_chat_scroll.add_child(_chat_vbox)

	# Top padding inside chat
	var top_pad = Control.new()
	top_pad.custom_minimum_size.y = 12
	_chat_vbox.add_child(top_pad)

	# ── Advance Indicator ────────────────────────────────────────────
	_advance_indicator = Label.new()
	_advance_indicator.text = "[ AWAITING INPUT_ ]"
	_advance_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_advance_indicator.add_theme_color_override("font_color", COLOR_ADVANCE_IND)
	_advance_indicator.add_theme_font_size_override("font_size", 16)
	_advance_indicator.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_advance_indicator.offset_top = -32
	_advance_indicator.offset_bottom = -8
	_advance_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_advance_indicator)
	
	# ── Audio Players ────────────────────────────────────────────────
	_audio_incoming = AudioStreamPlayer.new()
	_audio_incoming.stream = sfx_incoming
	add_child(_audio_incoming)
	
	_audio_typing = AudioStreamPlayer.new()
	_audio_typing.stream = sfx_typing
	add_child(_audio_typing)
	
	_audio_outgoing = AudioStreamPlayer.new()
	_audio_outgoing.stream = sfx_outgoing
	add_child(_audio_outgoing)
