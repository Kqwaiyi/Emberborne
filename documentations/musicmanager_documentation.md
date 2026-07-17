# MusicManager Documentation

The `MusicManager` is a globally accessible Singleton (autoload) responsible for handling background music playback across the entire game. It is designed to be persistent across scene changes, preventing music from arbitrarily stopping or restarting when players move between levels or screens (such as during the Snake Tower minigame).

## Features

1. **Persistent Playback:** Because it is an autoload, `MusicManager` persists independently of the current scene tree.
2. **Track Caching & Greediness:** If you request to play a track that is already playing, the `MusicManager` intelligently ignores the request. This allows multiple scripts or scenes to "greedily" call `play_music` without interrupting the ongoing track.
3. **Loop Delays:** Supports a customizable delay between track loops (default is 3.5 seconds) to create more natural pacing for background music.
4. **Signals:** Emits global signals when music actually starts or stops, making it easy to synchronize other game events (like UI animations) with the audio state.

---

## API Reference

### Variables

- `fade_in_duration` (float): Duration in seconds to fade in a starting track. Default is `1.0`.
- `fade_out_duration` (float): Duration in seconds to fade out a stopping track. Default is `1.0`.
- `_repeat_delay` (float): The delay in seconds before a track repeats. Default is `3.5`.
- `_music_tracks` (Dictionary): An optional mapping of string keys (e.g., `"level_1"`) to resource paths (e.g., `"res://assets/audio/level1.ogg"`). 

### Signals

- `music_started`: Emitted when a track successfully begins playing. (Note: When a track repeats automatically, this signal is *not* emitted again.)
- `music_stopped`: Emitted when a track finishes playing (and `repeat` is false), or when `stop_music()` is explicitly called (after the fade-out completes).

### Methods

#### `play_music(path: String, repeat: bool = true) -> void`
Starts playing a track with a smooth fade-in effect.
- **`path`**: The file path to the audio stream (e.g., `"res://assets/audio/track.ogg"`) or a key defined in the `_music_tracks` dictionary.
- **`repeat`**: If `true`, the track will continuously loop with a `3.5` second delay in between. If `false`, the track will play exactly once and then stop.

**Behavior Notes:**
- If another track is currently playing, it will be faded out smoothly before the new track starts.
- If the *same* track is already playing (or waiting in the loop delay timer), the call is ignored to prevent overlapping or restarting.

#### `stop_music(instant: bool = false) -> void`
Halts any currently playing music.
- **`instant`**: If `false` (default), the track will fade out smoothly over `fade_out_duration` seconds before stopping. If `true`, it stops immediately.
Emits the `music_stopped` signal once playback is completely stopped.

---

## Usage Examples

### 1. Playing a Track
To start music when entering a level:

```gdscript
func _ready():
	# Plays the track and loops it automatically
	MusicManager.play_music("res://assets/audio/bgm_main.ogg")
```

### 2. Stopping Music
To stop music when returning to a quiet menu:

```gdscript
func _on_back_to_menu():
	MusicManager.stop_music()
```

### 3. Using Dictionary Keys (Optional)
If you populate the `_music_tracks` dictionary in `MusicManager.gd`:

```gdscript
# Inside MusicManager.gd
var _music_tracks: Dictionary = {
	"boss_fight": "res://assets/audio/boss.ogg"
}

# Inside your level script
func _on_boss_spawn():
	MusicManager.play_music("boss_fight", true)
```

---

## Important Warnings for Audio Import

For the 3.5-second loop delay to function correctly, Godot must emit the `finished` signal at the end of the audio track.

> [!WARNING]
> By default, Godot often imports `.ogg` and `.wav` files with the **Loop** setting enabled internally. If Godot loops the audio internally, the `finished` signal will **never** fire, and the 3.5-second delay will not happen.
> 
> **How to fix this:**
> 1. Select your imported audio file in the Godot FileSystem dock.
> 2. Open the **Import** tab (next to the Scene tab).
> 3. Uncheck the **Loop** checkbox.
> 4. Click **Reimport**.
