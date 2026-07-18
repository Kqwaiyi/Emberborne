extends CanvasLayer

@onready var popup_box: PanelContainer = $PopupBox
@onready var title_label: Label = $PopupBox/MarginContainer/VBoxContainer/HBoxHeader/TitleLabel
@onready var description_label: RichTextLabel = $PopupBox/MarginContainer/VBoxContainer/DescriptionLabel
@onready var advance_indicator: Label = $PopupBox/MarginContainer/VBoxContainer/AdvanceIndicator
@onready var status_pulse: ColorRect = $PopupBox/MarginContainer/VBoxContainer/HBoxHeader/StatusPulse
@onready var typewriter_audio: AudioStreamPlayer = $TypewriterAudio
@onready var open_audio: AudioStreamPlayer = $OpenAudio
@onready var close_audio: AudioStreamPlayer = $CloseAudio
@onready var corner_decorations: Control = $PopupBox/CornerDecorations

const STREAM_TEXT = preload("res://assets/music/text_sound.mp3")
const STREAM_OPEN = preload("res://assets/sounds/laptop_ui/laptop_ui_open.mp3")
const STREAM_CLOSE = preload("res://assets/music/quest.mp3")

var _typewriter_tween: Tween = null
var _typewriter_audio_tween: Tween = null
var _indicator_tween: Tween = null
var _pulse_tween: Tween = null
var _is_typewriter_playing: bool = false
var _regex_sz: RegEx = null
var _regex_sh: RegEx = null

var _title_target: String = ""
var _title_idx: int = 0
var _decrypt_timer: Timer = null
var _corners: Array = []

const TYPEWRITER_SPEED: float = 0.02 # Faster typing for high-tech feel
const HOLO_CYAN_DIM := Color(0.3, 0.85, 1.0, 1.0)
const CORNER_LENGTH := 16.0
const CORNER_WIDTH := 2.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	popup_box.hide()
	advance_indicator.hide()
	
	typewriter_audio.stream = STREAM_TEXT
	open_audio.stream = STREAM_OPEN
	close_audio.stream = STREAM_CLOSE
	close_audio.volume_db = -15.0
	
	_regex_sz = RegEx.new()
	_regex_sz.compile("\\[sz=(.*?)\\](.*?)\\[\\/sz\\]")
	
	_regex_sh = RegEx.new()
	_regex_sh.compile("\\[sh(.*?)\\](.*?)\\[\\/sh\\]")
	
	_decrypt_timer = Timer.new()
	add_child(_decrypt_timer)
	_decrypt_timer.timeout.connect(_on_decrypt_tick)
	
	_create_corner_decorations()
	_start_status_pulse()

func display_task(title: String, description: String) -> void:
	_title_target = title
	_title_idx = 0
	title_label.text = ""
	_decrypt_timer.start(0.04)

	# Preprocess custom BBCode tags
	var processed_text = description
	if _regex_sz and _regex_sz.is_valid():
		processed_text = _regex_sz.sub(processed_text, "[font_size=$1]$2[/font_size]", true)
	if _regex_sh and _regex_sh.is_valid():
		processed_text = _regex_sh.sub(processed_text, "[shake$1]$2[/shake]", true)

	# Set text with typewriter effect
	description_label.text = processed_text
	description_label.visible_characters = 0
	advance_indicator.hide()
	_stop_indicator_animation()

	_is_typewriter_playing = true

	if _typewriter_audio_tween and _typewriter_audio_tween.is_valid():
		_typewriter_audio_tween.kill()
	typewriter_audio.volume_db = 0.0
	typewriter_audio.play()

	# Kill any previous typewriter tween
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var total_chars = description_label.get_total_character_count()
	var duration = total_chars * TYPEWRITER_SPEED
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(description_label, "visible_characters", total_chars, duration)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

func _stop_typewriter_audio() -> void:
	if typewriter_audio.playing:
		if _typewriter_audio_tween and _typewriter_audio_tween.is_valid():
			_typewriter_audio_tween.kill()
		_typewriter_audio_tween = create_tween()
		_typewriter_audio_tween.tween_property(typewriter_audio, "volume_db", -80.0, 0.2)
		_typewriter_audio_tween.tween_callback(func(): typewriter_audio.stop())

func complete_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	description_label.visible_characters = -1
	_stop_typewriter_audio()
	
	_decrypt_timer.stop()
	title_label.text = _title_target
	
	_is_typewriter_playing = false
	advance_indicator.show()
	_start_indicator_animation()

func is_typewriter_playing() -> bool:
	return _is_typewriter_playing

func show_box() -> void:
	popup_box.modulate.a = 0.0
	popup_box.pivot_offset = popup_box.size / 2.0
	
	if open_audio.stream:
		var stream_len = open_audio.stream.get_length()
		if stream_len > 0.0:
			open_audio.pitch_scale = stream_len / 0.35
		open_audio.play()
	
	# Stage 1: Thin horizontal line
	popup_box.scale = Vector2(0.0, 0.02)
	popup_box.show()
	
	var tween = create_tween()
	# Fade in and expand X very fast
	tween.tween_property(popup_box, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup_box, "scale", Vector2(1.0, 0.02), 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Snap Y to full height
	tween.tween_property(popup_box, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# Animate corners in
	tween.tween_callback(_animate_corners_in).set_delay(0.1)

func hide_box() -> void:
	if close_audio.stream:
		var stream_len = close_audio.stream.get_length()
		if stream_len > 0.0:
			close_audio.pitch_scale = stream_len / 0.2
		close_audio.play()

	_animate_corners_out()
	popup_box.pivot_offset = popup_box.size / 2.0
	var tween = create_tween()
	tween.tween_property(popup_box, "scale", Vector2(1.0, 0.02), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(popup_box, "scale", Vector2(0.0, 0.02), 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(popup_box, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): popup_box.hide())

func _on_typewriter_finished() -> void:
	_is_typewriter_playing = false
	_stop_typewriter_audio()
	advance_indicator.show()
	_start_indicator_animation()

func _start_indicator_animation() -> void:
	_stop_indicator_animation()
	_indicator_tween = create_tween().set_loops()
	_indicator_tween.tween_property(advance_indicator, "modulate:a", 0.3, 0.5)
	_indicator_tween.tween_property(advance_indicator, "modulate:a", 1.0, 0.5)

func _stop_indicator_animation() -> void:
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	advance_indicator.modulate.a = 1.0

func _start_status_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(status_pulse, "modulate:a", 0.2, 0.1)
	_pulse_tween.tween_property(status_pulse, "modulate:a", 1.0, 0.8)

func _on_decrypt_tick() -> void:
	_title_idx += 1
	if _title_idx > _title_target.length():
		_decrypt_timer.stop()
		title_label.text = _title_target
		return
		
	var scrambled = ""
	var chars = "!@#$%^&*01<>/"
	for i in range(_title_target.length() - _title_idx):
		scrambled += chars[randi() % chars.length()]
		
	title_label.text = _title_target.substr(0, _title_idx) + scrambled

func _create_corner_decorations() -> void:
	for i in 4:
		var h_rect = ColorRect.new()
		var v_rect = ColorRect.new()
		h_rect.color = HOLO_CYAN_DIM
		v_rect.color = HOLO_CYAN_DIM
		h_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h_rect.size = Vector2(CORNER_LENGTH, CORNER_WIDTH)
		v_rect.size = Vector2(CORNER_WIDTH, CORNER_LENGTH)
		corner_decorations.add_child(h_rect)
		corner_decorations.add_child(v_rect)
		_corners.append({"h": h_rect, "v": v_rect})
		
		h_rect.modulate.a = 0.0
		v_rect.modulate.a = 0.0

func _get_rest_positions() -> Array:
	var s = popup_box.size
	return [
		{"h": Vector2(0, 0), "v": Vector2(0, 0)},
		{"h": Vector2(s.x - CORNER_LENGTH, 0), "v": Vector2(s.x - CORNER_WIDTH, 0)},
		{"h": Vector2(0, s.y - CORNER_WIDTH), "v": Vector2(0, s.y - CORNER_LENGTH)},
		{"h": Vector2(s.x - CORNER_LENGTH, s.y - CORNER_WIDTH), "v": Vector2(s.x - CORNER_WIDTH, s.y - CORNER_LENGTH)},
	]

func _animate_corners_in() -> void:
	var corner_offset = 30.0
	var positions = _get_rest_positions()

	_corners[0].h.position = positions[0].h + Vector2(-corner_offset, -corner_offset)
	_corners[0].v.position = positions[0].v + Vector2(-corner_offset, -corner_offset)
	_corners[1].h.position = positions[1].h + Vector2(corner_offset, -corner_offset)
	_corners[1].v.position = positions[1].v + Vector2(corner_offset, -corner_offset)
	_corners[2].h.position = positions[2].h + Vector2(-corner_offset, corner_offset)
	_corners[2].v.position = positions[2].v + Vector2(-corner_offset, corner_offset)
	_corners[3].h.position = positions[3].h + Vector2(corner_offset, corner_offset)
	_corners[3].v.position = positions[3].v + Vector2(corner_offset, corner_offset)

	var tween = create_tween().set_parallel(true)
	for i in 4:
		_corners[i].h.modulate.a = 1.0
		_corners[i].v.modulate.a = 1.0
		tween.tween_property(_corners[i].h, "position", positions[i].h, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_corners[i].v, "position", positions[i].v, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _animate_corners_out() -> void:
	var tween = create_tween().set_parallel(true)
	for corner in _corners:
		tween.tween_property(corner.h, "modulate:a", 0.0, 0.15)
		tween.tween_property(corner.v, "modulate:a", 0.0, 0.15)
