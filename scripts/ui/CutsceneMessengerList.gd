class_name CutsceneMessengerList
extends Control

# ─── Color Palette (matching CutsceneMessenger) ──────────
const COLOR_BACKGROUND      := Color("0B1410")
const COLOR_HEADER_BG       := Color("1A2C23")
const COLOR_HEADER_TEXT     := Color("8DCEA0")
const COLOR_BUBBLE_TEXT     := Color("E0F0E8")
const COLOR_SCROLLBAR       := Color("2A4A3A")
const COLOR_SEPARATOR       := Color("1A2C23")

const HEADER_HEIGHT         := 56

var _background: ColorRect
var _list_screen: VBoxContainer
var _list_vbox: VBoxContainer
var _audio_back_hover: AudioStreamPlayer
var _audio_back_click: AudioStreamPlayer

func _ready() -> void:
	add_to_group("messenger_listener")
	_build_ui()
	_populate_conversation_list()

func _on_cutscene_queued(_key: String) -> void:
	_populate_conversation_list()

func _populate_conversation_list() -> void:
	for child in _list_vbox.get_children():
		child.queue_free()
		
	var contacts_data = []
	var processed_names = {}
	
	# Access static history dictionary from the main messenger script
	var histories = CutsceneMessenger._contact_histories
	var queued_key = CutsceneMessenger.queued_cutscene_key
	var cutscene_paths = CutsceneMessenger.CUTSCENE_PATHS
	
	# 1. Add history contacts
	for c_name in histories.keys():
		var history = histories[c_name]
		var latest_time = 0.0
		if history.size() > 0:
			latest_time = history.back().get("unix_time", 0.0)
		contacts_data.append({
			"name": c_name,
			"time": latest_time,
			"queued": false
		})
		processed_names[c_name] = true
		
	# 2. Add queued contact if any
	var messenger = load("res://scripts/ui/CutsceneMessenger.gd")
	if queued_key != "" and messenger and not messenger._completed_cutscenes.has(queued_key):
		if cutscene_paths.has(queued_key):
			var script = load(cutscene_paths[queued_key])
			if script:
				var sender = script.get_sender()
				var c_name = sender.get("name", "Unknown")
				# Profile pics are also stored in CutsceneMessenger statics
				CutsceneMessenger._contact_profile_pics[c_name] = sender.get("profile_picture", "")
				var dialogue = script.get_lines()
				var q_msg = ""
				if dialogue.size() > 0:
					q_msg = dialogue[0].get("text", "")
					
				if processed_names.has(c_name):
					for cd in contacts_data:
						if cd["name"] == c_name:
							cd["queued"] = true
							cd["queued_msg"] = q_msg
							cd["time"] = Time.get_unix_time_from_system()
							break
				else:
					contacts_data.append({
						"name": c_name,
						"time": Time.get_unix_time_from_system(),
						"queued": true,
						"queued_msg": q_msg
					})
					
	# Sort descending by time
	contacts_data.sort_custom(func(a, b): return a["time"] > b["time"])
	
	for cd in contacts_data:
		var c_name = cd["name"]
		var is_queued = cd["queued"]
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size.y = 72
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_BACKGROUND
		style.border_width_bottom = 1
		style.border_color = COLOR_SEPARATOR
		panel.add_theme_stylebox_override("panel", style)
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hbox)
		
		var margin = MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 32) # Starts offset for entrance anim
		margin.add_theme_constant_override("margin_right", 16)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(margin)
		
		var inner_hbox = HBoxContainer.new()
		inner_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_hbox.add_theme_constant_override("separation", 16)
		margin.add_child(inner_hbox)
		
		var pfp_bg = PanelContainer.new()
		pfp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pfp_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var pfp_style = StyleBoxFlat.new()
		pfp_style.bg_color = Color(0, 0, 0, 0.3)
		pfp_style.border_width_left = 1
		pfp_style.border_width_right = 1
		pfp_style.border_width_top = 1
		pfp_style.border_width_bottom = 1
		pfp_style.border_color = COLOR_SEPARATOR
		pfp_style.corner_radius_top_left = 4
		pfp_style.corner_radius_top_right = 4
		pfp_style.corner_radius_bottom_left = 4
		pfp_style.corner_radius_bottom_right = 4
		pfp_style.content_margin_left = 3
		pfp_style.content_margin_right = 3
		pfp_style.content_margin_top = 3
		pfp_style.content_margin_bottom = 3
		pfp_bg.add_theme_stylebox_override("panel", pfp_style)
		inner_hbox.add_child(pfp_bg)
		
		var pfp = TextureRect.new()
		pfp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pfp.custom_minimum_size = Vector2(42, 42)
		pfp.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		pfp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pfp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var pfp_path = CutsceneMessenger._contact_profile_pics.get(c_name, "")
		if pfp_path != "" and ResourceLoader.exists(pfp_path):
			pfp.texture = load(pfp_path)
		pfp_bg.add_child(pfp)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_vbox.add_theme_constant_override("separation", 2)
		inner_hbox.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.text = c_name
		name_lbl.add_theme_color_override("font_color", COLOR_BUBBLE_TEXT)
		name_lbl.add_theme_font_size_override("font_size", 16)
		text_vbox.add_child(name_lbl)
		
		var sub_lbl = Label.new()
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_queued:
			sub_lbl.text = "[ STATUS: UNREAD MESSAGES ]"
			sub_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		else:
			sub_lbl.text = "[ STATUS: READ ALL MESSAGES ]"
			sub_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.5))
		sub_lbl.add_theme_font_size_override("font_size", 11)
		text_vbox.add_child(sub_lbl)
		
		var spacer = Control.new()
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner_hbox.add_child(spacer)
		
		var telemetry_vbox = VBoxContainer.new()
		telemetry_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		telemetry_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		telemetry_vbox.alignment = BoxContainer.ALIGNMENT_END
		inner_hbox.add_child(telemetry_vbox)
		
		var ping_lbl = Label.new()
		ping_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ping_lbl.text = "PING: %dms" % randi_range(12, 45)
		ping_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6, 0.7))
		ping_lbl.add_theme_font_size_override("font_size", 10)
		ping_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		telemetry_vbox.add_child(ping_lbl)
		
		var hex_lbl = Label.new()
		hex_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hex_lbl.text = "[0x%04X]" % randi_range(0x1000, 0xFFFF)
		hex_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6, 0.5))
		hex_lbl.add_theme_font_size_override("font_size", 10)
		hex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		telemetry_vbox.add_child(hex_lbl)
		
		var t_timer = Timer.new()
		t_timer.wait_time = randf_range(1.0, 3.0)
		t_timer.autostart = true
		t_timer.timeout.connect(func():
			ping_lbl.text = "PING: %dms" % randi_range(12, 85)
			hex_lbl.text = "[0x%04X]" % randi_range(0x1000, 0xFFFF)
		)
		telemetry_vbox.add_child(t_timer)
		
		if is_queued:
			var badge = PanelContainer.new()
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.custom_minimum_size = Vector2(12, 12)
			badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var b_style = StyleBoxFlat.new()
			b_style.bg_color = Color.RED
			b_style.corner_radius_top_left = 6
			b_style.corner_radius_top_right = 6
			b_style.corner_radius_bottom_left = 6
			b_style.corner_radius_bottom_right = 6
			badge.add_theme_stylebox_override("panel", b_style)
			inner_hbox.add_child(badge)
			
			var badge_tween = badge.create_tween().set_loops()
			badge_tween.tween_property(badge, "modulate:a", 0.4, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			badge_tween.tween_property(badge, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			
		var tween_state = {"hover": null}
		
		var first_msg = ""
		if CutsceneMessenger._contact_histories.has(c_name) and CutsceneMessenger._contact_histories[c_name].size() > 0:
			first_msg = CutsceneMessenger._contact_histories[c_name][0].get("text", "")
		elif is_queued:
			first_msg = cd.get("queued_msg", "[ENCRYPTED TRANSMISSION]")
			
		var pvbox = get_meta("preview_vbox") if has_meta("preview_vbox") else null
		var pname = get_meta("preview_name") if has_meta("preview_name") else null
		var pmsg = get_meta("preview_msg") if has_meta("preview_msg") else null
		
		panel.mouse_entered.connect(func():
			if _audio_back_hover and _audio_back_hover.stream:
				_audio_back_hover.play()
			if tween_state["hover"] and tween_state["hover"].is_valid():
				tween_state["hover"].kill()
			tween_state["hover"] = create_tween().set_parallel(true)
			tween_state["hover"].tween_property(margin, "theme_override_constants/margin_left", 24, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween_state["hover"].tween_property(margin, "theme_override_constants/margin_right", 8, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween_state["hover"].tween_property(style, "bg_color", COLOR_BACKGROUND.lightened(0.08), 0.2)
			tween_state["hover"].tween_property(style, "border_color", COLOR_HEADER_TEXT, 0.2)
			tween_state["hover"].tween_property(pfp_style, "border_color", COLOR_HEADER_TEXT, 0.2)
			
			if pvbox and pname and pmsg:
				pname.text = c_name
				pmsg.text = first_msg
				if pvbox.has_meta("tween"):
					var old_t = pvbox.get_meta("tween")
					if old_t and old_t.is_valid(): old_t.kill()
				var pt = pvbox.create_tween()
				pt.tween_property(pvbox, "modulate:a", 1.0, 0.2)
				pvbox.set_meta("tween", pt)
		)
		panel.mouse_exited.connect(func():
			if tween_state["hover"] and tween_state["hover"].is_valid():
				tween_state["hover"].kill()
			tween_state["hover"] = create_tween().set_parallel(true)
			tween_state["hover"].tween_property(margin, "theme_override_constants/margin_left", 16, 0.2).set_ease(Tween.EASE_OUT)
			tween_state["hover"].tween_property(margin, "theme_override_constants/margin_right", 16, 0.2).set_ease(Tween.EASE_OUT)
			tween_state["hover"].tween_property(style, "bg_color", COLOR_BACKGROUND, 0.2)
			tween_state["hover"].tween_property(style, "border_color", COLOR_SEPARATOR, 0.2)
			tween_state["hover"].tween_property(pfp_style, "border_color", COLOR_SEPARATOR, 0.2)
			
			if pvbox:
				if pvbox.has_meta("tween"):
					var old_t = pvbox.get_meta("tween")
					if old_t and old_t.is_valid(): old_t.kill()
				var pt = pvbox.create_tween()
				pt.tween_property(pvbox, "modulate:a", 0.0, 0.2)
				pvbox.set_meta("tween", pt)
		)
		
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if _audio_back_click and _audio_back_click.stream:
					_audio_back_click.play()
				
				# Record exact bounds
				var start_pos = panel.global_position
				var start_size = panel.size
				
				# Insert layout placeholder
				var dummy = Control.new()
				dummy.custom_minimum_size = start_size
				var idx = panel.get_index()
				_list_vbox.add_child(dummy)
				_list_vbox.move_child(dummy, idx)
				
				# Break out of layout and slide
				panel.top_level = true
				panel.global_position = start_pos
				panel.size = start_size
				
				var pt = panel.create_tween().set_parallel(true)
				pt.tween_property(panel, "global_position:x", start_pos.x + 2000.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
				pt.tween_property(panel, "modulate:a", 0.0, 0.3).set_delay(0.1)
				
				_open_chat_for_contact(c_name)
		)
		
		var row_data = {
			"name_lbl": name_lbl,
			"target_name": c_name,
			"sub_lbl": sub_lbl,
			"target_sub": sub_lbl.text
		}
		name_lbl.text = ""
		sub_lbl.text = ""
		panel.set_meta("row_data", row_data)
		
		_list_vbox.add_child(panel)

	# Cascade Entrance Animation with Decryption Scrambler
	var delay = 0.05
	for child in _list_vbox.get_children():
		child.modulate.a = 0.0
		var c_margin = child.get_child(0).get_child(0)
		var t = child.create_tween().set_parallel(true)
		t.tween_property(child, "modulate:a", 1.0, 0.3).set_delay(delay).set_ease(Tween.EASE_OUT)
		t.tween_property(c_margin, "theme_override_constants/margin_left", 16, 0.4).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		var row_data = child.get_meta("row_data")
		var scramble = func(val: float):
			if not is_instance_valid(row_data["name_lbl"]): return
			var chars = "!@#$%^&*0123456789ABCDEF"
			
			var n_len = row_data["target_name"].length()
			var n_locked = int(val * n_len)
			var n_curr = ""
			for i in range(n_len):
				if i < n_locked: n_curr += row_data["target_name"][i]
				else: n_curr += chars[randi() % chars.length()]
			row_data["name_lbl"].text = n_curr
			
			var s_len = row_data["target_sub"].length()
			var s_locked = int(val * s_len)
			var s_curr = ""
			for i in range(s_len):
				if i < s_locked: s_curr += row_data["target_sub"][i]
				else: s_curr += chars[randi() % chars.length()]
			row_data["sub_lbl"].text = s_curr

		t.tween_method(scramble, 0.0, 1.0, 0.3).set_delay(delay)
		delay += 0.07

func _open_chat_for_contact(contact_name: String) -> void:
	# Set the static variable so the next scene knows who to load
	CutsceneMessenger.selected_contact = contact_name
	
	var laptops = get_tree().get_nodes_in_group("laptop_ui")
	if laptops.size() > 0:
		laptops[0].change_scene("res://scenes/ui/CutsceneMessenger.tscn", 0.5)

func _build_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_background = ColorRect.new()
	_background.color = COLOR_BACKGROUND
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_list_screen = VBoxContainer.new()
	_list_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list_screen.add_theme_constant_override("separation", 0)
	add_child(_list_screen)
	
	var list_header = PanelContainer.new()
	list_header.custom_minimum_size.y = HEADER_HEIGHT
	var lh_style = StyleBoxFlat.new()
	lh_style.bg_color = COLOR_HEADER_BG
	lh_style.content_margin_left = 8
	lh_style.content_margin_right = 12
	lh_style.content_margin_top = 4
	lh_style.content_margin_bottom = 4
	lh_style.border_width_bottom = 1
	lh_style.border_color = COLOR_SEPARATOR
	list_header.add_theme_stylebox_override("panel", lh_style)
	_list_screen.add_child(list_header)
	
	var lh_hbox = HBoxContainer.new()
	lh_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lh_hbox.add_theme_constant_override("separation", 10)
	list_header.add_child(lh_hbox)
	
	var list_back = TextureButton.new()
	list_back.custom_minimum_size = Vector2(32, 32)
	list_back.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	list_back.modulate = COLOR_HEADER_TEXT
	var list_back_icon_path = "res://assets/sprites/messenger/icon_back.svg"
	if ResourceLoader.exists(list_back_icon_path):
		list_back.texture_normal = load(list_back_icon_path)
		
	list_back.pivot_offset = list_back.custom_minimum_size / 2.0
	var tween_state_back = {"hover": null}
	list_back.mouse_entered.connect(func():
		if _audio_back_hover and _audio_back_hover.stream:
			_audio_back_hover.play()
		if tween_state_back["hover"] and tween_state_back["hover"].is_valid():
			tween_state_back["hover"].kill()
		var pt = create_tween().set_parallel(true)
		pt.tween_property(list_back, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		pt.tween_property(list_back, "modulate", Color(1.0, 1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
		tween_state_back["hover"] = pt
	)
	list_back.mouse_exited.connect(func():
		if tween_state_back["hover"] and tween_state_back["hover"].is_valid():
			tween_state_back["hover"].kill()
		var pt = create_tween().set_parallel(true)
		pt.tween_property(list_back, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)
		pt.tween_property(list_back, "modulate", COLOR_HEADER_TEXT, 0.15).set_ease(Tween.EASE_OUT)
		tween_state_back["hover"] = pt
	)
	list_back.button_down.connect(func():
		if _audio_back_click and _audio_back_click.stream:
			_audio_back_click.play()
		if tween_state_back["hover"] and tween_state_back["hover"].is_valid():
			tween_state_back["hover"].kill()
		var pt = create_tween()
		pt.tween_property(list_back, "scale", Vector2(0.9, 0.9), 0.05).set_ease(Tween.EASE_OUT)
		tween_state_back["hover"] = pt
	)
	
	list_back.pressed.connect(func():
		var laptops = get_tree().get_nodes_in_group("laptop_ui")
		if laptops.size() > 0:
			laptops[0].change_scene("res://scenes/ui/DesktopScreen.tscn", 0.5)
	)
	lh_hbox.add_child(list_back)
	
	var list_title = Label.new()
	list_title.text = "Messages"
	list_title.add_theme_color_override("font_color", COLOR_HEADER_TEXT)
	list_title.add_theme_font_size_override("font_size", 16)
	lh_hbox.add_child(list_title)
	
	var lh_spacer = Control.new()
	lh_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lh_hbox.add_child(lh_spacer)
	
	var list_scroll = ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var list_scrollbar = list_scroll.get_v_scroll_bar()
	var list_scroll_style = StyleBoxFlat.new()
	list_scroll_style.bg_color = COLOR_SCROLLBAR
	list_scroll_style.corner_radius_top_left = 3
	list_scroll_style.corner_radius_top_right = 3
	list_scroll_style.corner_radius_bottom_left = 3
	list_scroll_style.corner_radius_bottom_right = 3
	list_scrollbar.add_theme_stylebox_override("grabber", list_scroll_style)
	list_scrollbar.add_theme_stylebox_override("grabber_highlight", list_scroll_style)
	list_scrollbar.add_theme_stylebox_override("grabber_pressed", list_scroll_style)
	
	_list_screen.add_child(list_scroll)
	
	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 0)
	list_scroll.add_child(_list_vbox)
	
	var preview_vbox = VBoxContainer.new()
	preview_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_vbox.modulate.a = 0.0
	lh_hbox.add_child(preview_vbox)
	
	var preview_name = Label.new()
	preview_name.add_theme_color_override("font_color", COLOR_BUBBLE_TEXT)
	preview_name.add_theme_font_size_override("font_size", 13)
	preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_vbox.add_child(preview_name)
	
	var preview_msg = Label.new()
	preview_msg.add_theme_color_override("font_color", COLOR_HEADER_TEXT)
	preview_msg.add_theme_font_size_override("font_size", 11)
	preview_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_msg.custom_minimum_size.x = 250
	preview_msg.clip_text = true
	preview_msg.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	preview_vbox.add_child(preview_msg)
	
	set_meta("preview_vbox", preview_vbox)
	set_meta("preview_name", preview_name)
	set_meta("preview_msg", preview_msg)
	
	# Audio setup
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
