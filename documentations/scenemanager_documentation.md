# Technical Documentation: SceneManager Architecture

This document serves as a technical reference for the `SceneManager` module. It provides context on the design patterns, responsibilities, and specific implementations of this system in the Emberborne Godot project.

---

## 1. System Overview

The `SceneManager` is a global Autoload (Singleton) responsible for asynchronous loading and global visual transitions (fade-to-black) when switching between top-level scenes in the main `SceneTree` (e.g., Main Menu → World).

It is **not** responsible for transitions within SubViewport-based UIs (such as `LaptopUI`). Those systems manage their own internal transition logic independently.

---

## 2. Component Structure
*   **Script Location**: `res://scripts/core/SceneManager.gd`
*   **Scene Location**: `res://scenes/core/SceneManager.tscn`
*   **Node Tree**:
	*   `CanvasLayer` (Layer 100 - Always on top)
		*   `ColorRect` (Anchored to screen, handles the fade interpolation)

---

## 3. Key Design Patterns & Behaviors

### `PROCESS_MODE_ALWAYS`
The SceneManager's `process_mode` is explicitly set to `Node.PROCESS_MODE_ALWAYS` in its `_ready()` function. This is critical. Because `SceneManager` is an Autoload, it inherits its pause state from the `Window` root. If the main game pauses, the `SceneManager` must continue processing to animate the `ColorRect` tween and monitor the asynchronous load status in `_process()`.

### Global Transitions
`change_scene_to_file(path, fade_duration)` handles transitions in the main `SceneTree`. It supports configurable fade durations, where a duration of `0.0` creates an instantaneous scene swap with no black flash:
1.  Starts an asynchronous load via `ResourceLoader.load_threaded_request()`.
2.  Fades the global `ColorRect` to opaque black.
3.  Once loading completes, calls `get_tree().change_scene_to_packed(packed_scene)`.
4.  Fades the `ColorRect` back to transparent.

### Event Hooks (Signals)
The script emits three signals to allow external systems to safely react to the loading pipeline:
*   `transition_started`: Fired immediately when the fade-out begins.
*   `scene_loaded`: Fired after the scene is instantiated, but *before* the fade-in begins (the screen is completely black). Ideal for hidden setup logic.
*   `transition_finished`: Fired when the visual fade-in is complete and the `ColorRect` returns to `MOUSE_FILTER_IGNORE`.

---

## 4. Usage Rules for Future Development

When extending this system, adhere to the following rules:

1.  **Use `change_scene_to_file()` for global transitions only**: This method replaces the entire main scene tree. Do not use it for transitions within SubViewport-based UIs (use the host UI's own transition method instead, e.g., `LaptopUI.change_scene()`).
2.  **Mouse Filter Management**: The `SceneManager` uses `Control.MOUSE_FILTER_STOP` during transitions to block double-clicks or unwanted inputs. Ensure no newly added UI elements inadvertently steal focus with a higher Z-index during a fade.
