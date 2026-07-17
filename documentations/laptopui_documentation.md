# Technical Documentation: LaptopUI Architecture

This document serves as a technical reference for the `LaptopUI` module. It provides context on the design patterns, responsibilities, and specific implementations of this system in the Emberborne Godot project.

---

## 1. System Overview

The `LaptopUI` acts as a diegetic holographic interface in the main story world. It serves as a self-contained sandboxed environment where separate game mechanics (e.g., the Snake Tower minigame) can run independently without conflicting with the main game's physics, camera, or input mappings.

The module is fully independent — it owns its own scene transition system, visual effects, and lifecycle management. It does **not** depend on `SceneManager` for any internal operations. `SceneManager` is used only for global (main scene tree) transitions.

---

## 2. Component Structure
*   **Script Location**: `res://scripts/ui/LaptopUI.gd`
*   **Scene Location**: `res://scenes/ui/LaptopUI.tscn`
*   **Shader Locations**:
    *   `res://assets/shaders/hologram_scanlines.gdshader`
    *   `res://assets/shaders/hologram_glitch.gdshader`
*   **Node Tree**:
	*   `CanvasLayer` (Layer 90 - Renders below SceneManager but above main game)
		*   `BackgroundTint` (`ColorRect` — dark blue-tinted overlay to obscure the paused main game)
		*   `CenterContainer` (Full-screen, centers the display)
			*   `DisplayPanel` (`Panel` — translucent dark panel with cyan border glow via `StyleBoxFlat`)
				*   `SubViewportContainer` (Stretch = true, `texture_filter = 1`, offset below header)
					*   `SubViewport` (`canvas_item_default_texture_filter = 0`, 1000×600)
				*   `TransitionRect` (`ColorRect` — overlaid on the viewport area for localized fade transitions)
				*   `ScanLines` (`ColorRect` — `ShaderMaterial` with `hologram_scanlines.gdshader`, covers full panel)
				*   `GlitchOverlay` (`ColorRect` — `ShaderMaterial` with `hologram_glitch.gdshader`, covers full panel)
				*   `HeaderBar` (`HBoxContainer` — anchored at top of panel, 30px tall)
					*   `StatusLabel` (`Label` — "◆ SYSTEM ONLINE", cyan, 13px)
					*   `CloseButton` (`Button` — borderless, uses custom `HoloCloseButton.gd` for procedural holographic drawing and audio)
				*   `CornerDecorations` (`Control` — container for 4 programmatic L-shaped corner brackets)

---

## 3. Key Design Patterns & Behaviors

### Process Mode Isolation
When `open_laptop()` is called, it executes `get_tree().paused = true`. This globally freezes the main game's physics and `_process` loops. The `LaptopUI` circumvents this because its `process_mode` is explicitly set to `Node.PROCESS_MODE_ALWAYS`. Therefore, the `SubViewport` and any minigame instanced inside it continue to run normally.

### Pixel-Perfect Viewport Rendering
To maintain a crisp, pixel-art aesthetic inside the minigame, the `LaptopUI` overrides Godot's default viewport filtering behaviors:
*   The `SubViewportContainer` enforces `texture_filter = 1` (Nearest) so the buffer is rendered to the screen sharply.
*   The `SubViewport` enforces `canvas_item_default_texture_filter = 0` so that internal 2D nodes draw with Nearest Neighbor filtering. This isolates the minigame's aesthetic from any global project settings that might interfere.

### Self-Contained Viewport Transition System
`LaptopUI` owns its own asynchronous scene loading and fade transition system. It does **not** delegate to `SceneManager`. The `change_scene(path, fade_duration)` method:
1.  Calls `ResourceLoader.load_threaded_request(path)` to begin asynchronous loading.
2.  Fades the `TransitionRect` to black over `fade_duration` seconds.
3.  Once loading completes, clears the `SubViewport` children and instantiates the new scene.
4.  Notifies time trackers via `get_tree().call_group("minigame_time_trackers", "_on_laptop_scene_loaded", path)`.
5.  Fades the `TransitionRect` back to transparent.

If `fade_duration` is set to `0.0`, the transition is instantaneous (no black flash).

### Group-Based Discovery
`LaptopUI` registers itself in the `"laptop_ui"` group during `_ready()`. Minigames running inside the `SubViewport` can discover the host laptop by calling:
```gdscript
var laptops = get_tree().get_nodes_in_group("laptop_ui")
if laptops.size() > 0:
	laptops[0].change_scene(target_scene, 0.5)
```

### Holographic Open Animation (~0.6s)
The boot sequence is fully choreographed via `Tween` chains:
1.  Background tint fades in. A thin horizontal cyan line appears (panel at near-zero Y scale).
2.  The line expands vertically with `TRANS_BACK` / `EASE_OUT` overshoot. Glitch shader bands flicker.
3.  Scan lines activate. Header bar fades in. Status label types out "◆ SYSTEM ONLINE" character-by-character.
4.  Corner brackets slide in from outside the panel edges. Close button fades in last.

### Holographic Close Animation (~0.4s)
The shutdown sequence is snappier than the open:
1.  Close button and header vanish. Glitch intensity spikes.
2.  Corner brackets fade out. Scan lines disappear.
3.  Display compresses vertically back to a thin line.
4.  Line and background tint fade out.

### UI Interactions & Audio Synchronization
The Laptop UI features dynamic, synchronized audio-visual feedback:
*   **Procedural Close Button**: `HoloCloseButton.gd` overrides `_draw()` to procedurally animate a holographic "✕" with L-shaped brackets that snap inward on hover and compress on press. It dynamically loads and plays sound effects for hover (`Hover.mp3`), generic clicks (`Click.mp3`), and confirmed close actions (`laptop_ui_close.mp3`).
*   **Glow Synchronization**: When the close button is held down, it emits a `press_state_changed` signal. `LaptopUI.gd` listens to this and synchronizes the entire interface—tweening the panel's border, outer glow, corner brackets, and "SYSTEM ONLINE" text from cyan to an aggressive red. If the click is cancelled, they tween smoothly back to cyan. During the closing animation, the button state locks to preserve the red color until shutdown completes.
*   **Audio Speed Matching**: The boot animation plays `laptop_ui_open.mp3`. Because the visual boot sequence takes a strict ~0.6 seconds, `LaptopUI.gd` dynamically calculates the ratio between the audio file's native length and the 0.6s target, applying it to the `AudioStreamPlayer.pitch_scale`. This guarantees the boot sound always finishes exactly when the holographic screen finishes expanding.

### Lifecycle Cleanup & Group Notifications
When `close_laptop()` is triggered (via the ✕ button):
1.  Any pending scene transition is cancelled (tween killed, `_next_scene_path` cleared).
2.  The close animation plays.
3.  The main game is unpaused (`get_tree().paused = false`).
4.  The viewport's children are destroyed via `queue_free()` to prevent memory leaks.
5.  A global group call `get_tree().call_group("minigame_time_trackers", "pause_time")` is issued.

---

## 4. Public API

### Methods

```gdscript
# Opens the laptop with a holographic boot animation.
# Optionally loads a minigame scene after the animation completes.
LaptopUI.open_laptop(minigame_scene_path: String = "", fade_duration: float = 0.5) -> void

# Closes the laptop with a holographic shutdown animation.
# Clears the viewport, unpauses the game, and notifies time trackers.
LaptopUI.close_laptop() -> void

# Loads a new scene into the SubViewport with a fade transition.
# Primary API for minigames to advance levels while running inside the laptop.
LaptopUI.change_scene(path: String, fade_duration: float = 0.5) -> void

# Destroys all children of the SubViewport to free memory.
LaptopUI.clear_minigame() -> void
```

### Signals

```gdscript
LaptopUI.opened              # After boot animation completes and scene is loaded.
LaptopUI.closed              # After shutdown animation completes and cleanup finishes.
LaptopUI.transition_started   # When a viewport fade-out begins.
LaptopUI.scene_loaded         # After a new scene is instantiated in the SubViewport.
LaptopUI.transition_finished  # When the viewport fade-in completes.
```

---

## 5. Usage Rules for Future Development

When extending this system, adhere to the following rules:

1.  **Keep LaptopUI Modular**: `LaptopUI` is designed to be a "dumb" container. It does not track player progress or minigame state. If a minigame needs to remember the player's last level, the caller (e.g., an interactable node) must query the minigame's specific state manager before calling `LaptopUI.open_laptop(path)`.
2.  **Respect the Pause State**: If adding new global UI overlays, ensure you evaluate whether their `process_mode` needs to be `ALWAYS` or `INHERIT`. If a UI needs to animate while the game is paused, it must be `ALWAYS`.
3.  **Do not call SceneManager from inside the laptop viewport**: Minigames should use `get_tree().get_nodes_in_group("laptop_ui")[0].change_scene()` for level transitions when running inside the laptop. Use `SceneManager.change_scene_to_file()` only as a fallback for standalone testing.
4.  **Do not interrupt animations**: `open_laptop()` and `close_laptop()` guard against re-entry via `_is_animating`. Do not call them while an animation is in progress.
