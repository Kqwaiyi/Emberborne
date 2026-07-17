extends Node

signal music_started
signal music_stopped

var fade_in_duration: float = 1.0
var fade_out_duration: float = 1.0

var _audio_player: AudioStreamPlayer
var _timer: Timer
var _fade_tween: Tween
var _current_path: String = ""
var _repeat: bool = false
var _repeat_delay: float = 3.5

# Optional: Add keys here that map to string paths like "res://assets/audio/music.ogg"
var _music_tracks: Dictionary = {
	"minigame_bgm": "res://assets/audio/placeholder_bgm.ogg",
	"pet_home": "res://assets/audio/placeholder_pet_home.ogg"
}

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.finished.connect(_on_audio_finished)
	
	_timer = Timer.new()
	add_child(_timer)
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)

## Starts playing music from the given path or dictionary key.
## If repeat is true, it loops with a 3.5s delay.
func play_music(path: String, repeat: bool = true) -> void:
	# If a dictionary key is provided, resolve it to the full path.
	if _music_tracks.has(path):
		path = _music_tracks[path]
		
	# If the requested music is already playing, do nothing.
	if _current_path == path and _audio_player.playing:
		return
		
	# If the requested music is currently waiting in the delay timer, do nothing.
	if _current_path == path and not _audio_player.playing and not _timer.is_stopped():
		return

	# If something is currently playing, we need to crossfade/stop it first
	if _audio_player.playing:
		_fade_out_and_play(path, repeat)
	else:
		_start_track(path, repeat)

func _fade_out_and_play(path: String, repeat: bool) -> void:
	_repeat = false # Prevent it from looping while fading out
	_timer.stop()
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	_fade_tween = create_tween()
	_fade_tween.tween_property(_audio_player, "volume_db", -80.0, fade_out_duration)
	_fade_tween.tween_callback(func():
		_audio_player.stop()
		music_stopped.emit()
		_start_track(path, repeat)
	)

func _start_track(path: String, repeat: bool) -> void:
	_current_path = path
	_repeat = repeat
	
	var stream = load(path)
	if stream is AudioStream:
		_audio_player.stream = stream
		_audio_player.volume_db = -80.0
		_audio_player.play()
		music_started.emit()
		
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_audio_player, "volume_db", 0.0, fade_in_duration)
	else:
		push_error("MusicManager: Could not load audio stream from path: " + path)

## Stops the currently playing music and cancels the repeat timer.
func stop_music(instant: bool = false) -> void:
	_repeat = false
	_timer.stop()
	_current_path = ""
	
	if not _audio_player.playing:
		return
		
	if instant:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_audio_player.stop()
		music_stopped.emit()
	else:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_audio_player, "volume_db", -80.0, fade_out_duration)
		_fade_tween.tween_callback(func():
			_audio_player.stop()
			music_stopped.emit()
		)

func _on_audio_finished() -> void:
	if _repeat:
		_timer.start(_repeat_delay)
	else:
		music_stopped.emit()
		_current_path = ""

func _on_timer_timeout() -> void:
	if _current_path != "":
		# When a loop restarts, fade it in
		_audio_player.volume_db = -80.0
		_audio_player.play()
		
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_audio_player, "volume_db", 0.0, fade_in_duration)
