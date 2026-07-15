# Technical Documentation: SceneManager Architecture

This document serves as a technical reference for the `SceneManager` module. It provides context on the design patterns, responsibilities, and specific implementations of this system in the Emberborne Godot project.

---

## 1. System Overview

The project utilizes a hybrid scene management architecture to handle both global scene transitions (e.g., Main Menu to World) and encapsulated sub-scene rendering (e.g., Minigames within a UI). 

This is achieved via the **`SceneManager`**: A global Autoload (Singleton) responsible for asynchronous loading and global visual transitions (fade-to-black).

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

### Dual-Target Transitioning
The `SceneManager` supports two types of transitions, handled internally by `_start_transition()`. Both support configurable fade durations, where a duration of `0.0` creates an instantaneous scene swap with no black flash:
1.  **Global Transitions (`change_scene_to_file(path, fade_duration)`)**: The target is the main `SceneTree`. Uses the SceneManager's global `ColorRect`. Upon loading, it calls `get_tree().change_scene_to_packed(packed_scene)`.
2.  **Viewport Transitions (`change_scene_in_viewport(path, viewport, custom_fade_rect, fade_duration)`)**: The target is a specific `Node` (usually a `SubViewport`). The transition requires passing a `custom_fade_rect` from the host UI scene (like LaptopUI) to handle the fade locally, keeping the global screen untouched. Upon loading, it clears the viewport's existing children and calls `target.add_child(packed_scene.instantiate())`.

### Event Hooks (Signals)
The script emits three signals to allow external systems to safely react to the loading pipeline:
*   `transition_started`: Fired immediately when the fade-out begins.
*   `scene_loaded`: Fired after the scene is instantiated, but *before* the fade-in begins (the screen is completely black). Ideal for hidden setup logic.
*   `transition_finished`: Fired when the visual fade-in is complete and the `ColorRect` returns to `MOUSE_FILTER_IGNORE`.

---

## 4. Integrating SubViewport UIs (e.g., LaptopUI)

To connect a local UI wrapper (like `LaptopUI`) to the `SceneManager` so that minigames transition seamlessly without fading the main game:

1.  **Add a Transition Layer**: In your UI scene (`LaptopUI.tscn`), create a `ColorRect` (e.g., `TransitionRect`) that covers the same screen area as your `SubViewportContainer`. It should be ordered in the scene tree so it draws *on top* of the viewport. Ensure its `mouse_filter` is set to `Ignore` by default.
2.  **Pass it to SceneManager**: When the UI wrapper needs to load a minigame, it should call `SceneManager.change_scene_in_viewport()` and pass its own `TransitionRect`.
    ```gdscript
    @onready var viewport = $CenterContainer/Panel/SubViewportContainer/SubViewport
    @onready var transition_rect = $CenterContainer/Panel/TransitionRect
    
    func load_minigame(path: String, fade_duration: float = 0.5):
        SceneManager.change_scene_in_viewport(path, viewport, transition_rect, fade_duration)
    ```
3.  **Internal Minigame Delegation**: When a minigame running *inside* the viewport needs to advance to the next level, it must dynamically locate the host's `TransitionRect` by walking up the scene tree, then delegate to `SceneManager`.
	```gdscript
	var vp = get_viewport()
	if vp is SubViewport:
		var custom_rect: ColorRect = null
		if vp.get_parent() and vp.get_parent().get_parent():
			custom_rect = vp.get_parent().get_parent().get_node_or_null("TransitionRect")
		SceneManager.change_scene_in_viewport(target_scene, vp, custom_rect, 0.5)
	```

---

## 5. Usage Rules for Future Development

When extending this system, adhere to the following rules:

1.  **Do not blindly use `change_scene_to_file()` inside minigames**: A minigame script should dynamically check its host environment. By checking if `get_viewport() is SubViewport`, the minigame can fetch the host's `TransitionRect` and delegate to `SceneManager.change_scene_in_viewport()` when running inside the laptop, or fallback to `SceneManager.change_scene_to_file()` when running as a standalone test scene.
2.  **Mouse Filter Management**: The `SceneManager` uses `Control.MOUSE_FILTER_STOP` during transitions to block double-clicks or unwanted inputs. Ensure no newly added UI elements inadvertently steal focus with a higher Z-index during a fade.
