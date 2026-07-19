extends RichTextLabel
class_name TerminalTypewriter

var full_text: String = ""
var current_chars: int = 0
var typing: bool = false
var is_reversing: bool = false
var cursor_blink_speed: float = 0.3
var _scramble_pool: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"

var _active_tween: Tween
var _audio_player: AudioStreamPlayer
var _last_char_count: int = 0

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = preload("res://assets/music/text_sound.mp3")
	_audio_player.volume_db = -15.0
	add_child(_audio_player)

func type_text(new_text: String, char_delay: float = 0.02) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	# Reset state
	full_text = new_text
	current_chars = 0
	typing = true
	is_reversing = false
	modulate.a = 1.0
	
	# Start audio
	_audio_player.volume_db = -10.0
	_audio_player.pitch_scale = 1.0
	_audio_player.play()
	
	# Create tween for character count
	_active_tween = create_tween()
	_active_tween.tween_property(self, "current_chars", full_text.length(), full_text.length() * char_delay)
	_active_tween.tween_callback(_on_typing_finished)

func _process(_delta: float) -> void:
	if not typing and not is_reversing and full_text == "":
		text = ""
		return
		
	# Determine if cursor should be visible
	var show_cursor = int(Time.get_ticks_msec() / (cursor_blink_speed * 1000.0)) % 2 == 0
	var cursor = "|" if show_cursor else " "
	
	# Safely substring
	var display_text = ""
	
	if is_reversing:
		# Scramble the last few characters near the head as it deletes backwards
		for i in range(current_chars):
			# Scramble the 5 characters immediately before the current head
			if i >= current_chars - 5:
				display_text += _scramble_pool[randi() % _scramble_pool.length()]
			else:
				display_text += full_text[i]
	else:
		display_text = full_text.substr(0, current_chars)
	
	text = display_text + cursor

func _on_typing_finished() -> void:
	typing = false
	
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	# Smoothly fade out audio
	var audio_tween = create_tween()
	audio_tween.tween_property(_audio_player, "volume_db", -80.0, 0.5)
	audio_tween.tween_callback(func(): _audio_player.stop())
	
	# Wait 3 seconds, then start reverse typing
	_active_tween = create_tween()
	_active_tween.tween_interval(3.0)
	_active_tween.tween_callback(_start_reverse)

func _start_reverse() -> void:
	is_reversing = true
	var char_delay = 0.0075 # Twice as fast reverse
	
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	
	_active_tween = create_tween()
	_active_tween.tween_property(self, "current_chars", 0, full_text.length() * char_delay)
	_active_tween.tween_callback(_clear_text)

func _clear_text() -> void:
	is_reversing = false
	full_text = ""
	text = ""
