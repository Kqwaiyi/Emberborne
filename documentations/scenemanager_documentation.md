# Technical Documentation: SceneManager & LaptopUI Architecture

This document serves as a comprehensive technical reference for the `SceneManager` and `LaptopUI` modules. It is designed to provide context for future developers and AI assistants on the design patterns, responsibilities, and specific implementations of these systems in the Emberborne Godot project.

---

## 1. System Overview

The project utilizes a hybrid scene management architecture to handle both global scene transitions (e.g., Main Menu to World) and encapsulated sub-scene rendering (e.g., Minigames within a UI). 

This is achieved via two primary components:
1. **`SceneManager`**: A global Autoload (Singleton) responsible for asynchronous loading and global visual transitions (fade-to-black).
2. **`LaptopUI`**: A local CanvasLayer overlay that encapsulates a `SubViewport`, allowing an independent game loop to run while the main game tree is explicitly paused.

By integrating these two systems, the project ensures that both global and local scene transitions share the same visual polish and asynchronous loading mechanics without duplicating code.

---

## 2. The SceneManager Module

### Purpose
The `SceneManager` abstracts the complexities of Godot 4's threaded resource loading (`ResourceLoader.load_threaded_request`). It prevents the main thread from blocking during heavy scene instantiation and manages a global CanvasLayer overlay to hide the pop-in effects of new scenes.

### Component Structure
*   **Script Location**: `res://scripts/core/SceneManager.gd`
*   **Scene Location**: `res://scenes/core/SceneManager.tscn`
*   **Node Tree**:
    *   `CanvasLayer` (Layer 100 - Always on top)
        *   `ColorRect` (Anchored to screen, handles the fade interpolation)

### Key Design Patterns & Behaviors

#### `PROCESS_MODE_ALWAYS`
The SceneManager's `process_mode` is explicitly set to `Node.PROCESS_MODE_ALWAYS` in its `_ready()` function. This is critical. Because `SceneManager` is an Autoload, it inherits its pause state from the `Window` root. If the main game pauses (e.g., when `LaptopUI` opens), the `SceneManager` must continue processing to animate the `ColorRect` tween and monitor the asynchronous load status in `_process()`.

#### Dual-Target Transitioning
The `SceneManager` supports two types of transitions, handled internally by `_start_transition()`:
1.  **Global Transitions (`change_scene_to_file`)**: The target is the main `SceneTree`. Upon loading, it calls `get_tree().change_scene_to_packed(packed_scene)`.
2.  **Viewport Transitions (`change_scene_in_viewport`)**: The target is a specific `Node` (usually a `SubViewport`). Upon loading, it clears the viewport's existing children and calls `target.add_child(packed_scene.instantiate())`.

#### Event Hooks (Signals)
The script emits three signals to allow external systems to safely react to the loading pipeline:
*   `transition_started`: Fired immediately when the fade-out begins.
*   `scene_loaded`: Fired after the scene is instantiated, but *before* the fade-in begins (the screen is completely black). Ideal for hidden setup logic.
*   `transition_finished`: Fired when the visual fade-in is complete and the `ColorRect` returns to `MOUSE_FILTER_IGNORE`.

---

## 3. The LaptopUI Module

### Purpose
The `LaptopUI` acts as a diegetic interface in the main story world. It serves as a sandboxed environment where separate game mechanics (e.g., the Snake Tower minigame) can run independently without conflicting with the main game's physics, camera, or input mappings.

### Component Structure
*   **Script Location**: `res://scripts/ui/LaptopUI.gd`
*   **Scene Location**: `res://scenes/ui/LaptopUI.tscn`
*   **Node Tree**:
	*   `CanvasLayer` (Layer 90 - Renders below SceneManager but above main game)
		*   `BackgroundTint` (`ColorRect` to obscure the paused main game)
		*   `CenterContainer` -> `Panel` (The physical laptop bezel constraint)
			*   `SubViewportContainer` (Stretch = true, `texture_filter = 1`)
				*   `SubViewport` (`canvas_item_default_texture_filter = 1`)
			*   `CloseButton` (Z-indexed above the viewport to capture clicks)

### Key Design Patterns & Behaviors

#### Process Mode Isolation
When `open_laptop()` is called, it executes `get_tree().paused = true`. This globally freezes the main game's physics and `_process` loops. The `LaptopUI` circumvents this because its `process_mode` is explicitly set to `Node.PROCESS_MODE_ALWAYS`. Therefore, the `SubViewport` and any minigame instanced inside it continue to run normally.

#### Pixel-Perfect Viewport Rendering
To maintain a crisp, pixel-art aesthetic inside the minigame, the `LaptopUI` overrides Godot's default viewport filtering behaviors:
*   The `SubViewportContainer` enforces `texture_filter = 1` (Nearest) so the buffer is rendered to the screen sharply.
*   The `SubViewport` enforces `canvas_item_default_texture_filter = 1` so that internal 2D nodes draw with Nearest Neighbor filtering. This isolates the minigame's aesthetic from any global project settings that might interfere.

#### Integration with SceneManager
Instead of manually instantiating packed scenes, `LaptopUI.gd` delegates its loading to `SceneManager.change_scene_in_viewport(path, viewport, 0.5)`. This ensures that advancing levels inside a minigame triggers the same global fade-to-black visual polish as the main game.

#### Lifecycle Cleanup & Group Notifications
When `close_laptop()` is triggered (via the X button):
1.  The main game is unpaused (`get_tree().paused = false`).
2.  The viewport's children are destroyed via `queue_free()` to prevent memory leaks.
3.  A global group call `get_tree().call_group("minigame_time_trackers", "pause_time")` is issued. This acts as a broadcast to any lingering or persistent minigame systems (e.g., external timers) to halt their logic, ensuring background systems don't desync when the laptop is closed.

---

## 4. Usage Rules for Future Development

When extending this system, adhere to the following rules:

1.  **Do not blindly use `change_scene_to_file()` inside minigames**: A minigame script should dynamically check its host environment. By checking if `get_viewport() is SubViewport`, the minigame can delegate to `SceneManager.change_scene_in_viewport()` when running inside the laptop, or fallback to `SceneManager.change_scene_to_file()` when running as a standalone test scene.
2.  **Keep LaptopUI Modular**: `LaptopUI` is designed to be a "dumb" container. It does not track player progress or minigame state. If a minigame needs to remember the player's last level, the caller (e.g., an interactable node) must query the minigame's specific state manager before calling `LaptopUI.open_laptop(path)`.
3.  **Respect the Pause State**: If adding new global UI overlays, ensure you evaluate whether their `process_mode` needs to be `ALWAYS` or `INHERIT`. If a UI needs to animate while the game is paused, it must be `ALWAYS`.
4.  **Mouse Filter Management**: The `SceneManager` uses `Control.MOUSE_FILTER_STOP` during transitions to block double-clicks or unwanted inputs. Ensure no newly added UI elements inadvertently steal focus with a higher Z-index during a fade.
