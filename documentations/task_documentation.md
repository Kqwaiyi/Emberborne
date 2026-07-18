# Technical Documentation: Task Notification Module

This document serves as a technical reference for the `TaskManager` module. It provides context on the design patterns, responsibilities, visual effects, and specific implementations of this system in the Emberborne Godot project.

---

## 1. System Overview

The `TaskManager` is a global Autoload singleton that provides a modular, futuristic task notification popup. It renders a centralized UI overlay that intercepts player input, ensuring that the player acknowledges the notification before continuing game interaction. The aesthetic is heavily inspired by cyberpunk HUDs, utilizing crisp animation curves, text decryption effects, and scanline shaders.

---

## 2. Component Structure

*   **Manager Script Location**: `res://scripts/core/TaskManager.gd`
*   **Overlay Script Location**: `res://scripts/ui/TaskOverlay.gd`
*   **Overlay Scene Location**: `res://scenes/ui/TaskOverlay.tscn`
*   **Shader Asset Location**: `res://shaders/ui_scanline.gdshader`
*   **Autoload Name**: `TaskManager`
*   **Input Action**: `dialogue_advance` (Space / Enter)

### Overlay Node Tree
```
TaskOverlay (CanvasLayer — Layer 115, PROCESS_MODE_ALWAYS)
└── PopupBox (PanelContainer — bottom-anchored, matching DialogueManager elevation)
	├── ScanlineOverlay (ColorRect — ShaderMaterial: ui_scanline.gdshader)
	├── CornerDecorations (Control — manages the 4 dynamic sliding holographic brackets)
	└── MarginContainer
		└── VBoxContainer
			├── HBoxHeader
			│   ├── StatusPulse (ColorRect — blinking square indicator)
			│   └── TitleLabel (Label — Decryption effect target, 28px)
			├── DescriptionLabel (RichTextLabel — Typewriter target, 22px)
			└── AdvanceIndicator (Label — "[SPACE] TO ACKNOWLEDGE", pulsing)
```

### CanvasLayer Ordering
The task overlay is assigned Layer `115`, placing it slightly above the `DialogueOverlay` (Layer `110`) to ensure critical tasks can overlay active dialogues if necessary.

---

## 3. Key Design Patterns & Behaviors

### Three-Layer Input Blocking
Similar to the `DialogueManager`, the `TaskManager` employs strict three-layer input blocking while a task is visible:

1.  **`_input()` Interception**: Uses `_input()` to aggressively intercept events before they propagate to the SceneTree.
2.  **SubViewportContainer Isolation**: Disables `process_input` and `process_unhandled_input` on all `SubViewportContainer` nodes when a task appears, caching their state in `_blocked_viewport_containers` and restoring them upon close.
3.  **Action Release Polling**: Scans `InputMap` in `_process()` and calls `Input.action_release()` on any held actions (excluding `dialogue_advance`) to prevent bleeding input into game systems that poll via `Input.is_action_pressed()`.

### Futuristic Visual Effects

*   **Digital Unfold Animation**: Replaces traditional bouncy easing with `Tween.TRANS_EXPO`. The box expands horizontally into a thin line (Y=0.02) over 0.25 seconds, and then snaps vertically to full height, mimicking a tactical holographic display boot sequence.
*   **Dynamic Corner Brackets**: Inspired by the laptop UI, four glowing brackets slide inward from outside the panel's boundaries into their resting corners via a cubic ease.
*   **Title Decryption Effect**: Instead of a standard typewriter effect, the main header title utilizes a custom `Timer` (`_decrypt_timer`). It iterates through the string, leaving trailing characters randomized (using symbols like `!@#$%^&*01<>/`) for a few frames before locking them to the correct letter.
*   **Scanline Shader**: A `ColorRect` inside the panel uses a CanvasItem shader (`ui_scanline.gdshader`) to render rolling horizontal lines, giving the interface a CRT projector/diegetic hologram feel.

### Inline Formatting (BBCode)
The task description `RichTextLabel` supports standard BBCode, as well as the custom preprocessing tags used in the dialogue system:
*   **`[sz=X]text[/sz]`**: Dynamically changes font size (e.g., `[sz=32]SHOUT[/sz]`).
*   **`[sh rate=X level=Y]text[/sh]`**: Leverages Godot's native character shake effect.

### Audio Readiness
The `TaskOverlay.tscn` contains an inactive `AudioStreamPlayer`. It is laid out in the tree to easily facilitate adding an electronic boot-up or transmission sound effect in the future.

---

## 4. Public API

All interactions with the task notification system must be done through the `TaskManager` singleton.

### Methods

```gdscript
# Displays a new task popup. Will push a warning and return if a task is already active.
TaskManager.show_task(title: String, description: String) -> void

# Returns true if a task notification is currently visible on screen.
TaskManager.is_active() -> bool

# Force-closes the active task popup without requiring player input.
TaskManager.close_task() -> void
```

### Signals

```gdscript
# Fired when the task popup completes its intro animation and begins typing.
TaskManager.task_started

# Fired when the popup is acknowledged by the player (Space/Enter) and closed.
TaskManager.task_acknowledged
```

---

## 5. Usage Example

Trigger a task notification from any script in your project:

```gdscript
func _on_objective_reached():
	# Use standard strings
	TaskManager.show_task("NEW DIRECTIVE", "Objective updated: Retrieve the lost artifact.")

	# Or utilize custom BBCode for dramatic effect
	TaskManager.show_task("WARNING", "Enemy presence detected in [sh rate=20 level=5][sz=24]SECTOR 7[/sz][/sh].")
```
