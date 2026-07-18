# Technical Documentation: DialogueManager Architecture

This document serves as a technical reference for the `DialogueManager` module. It provides context on the design patterns, responsibilities, and specific implementations of this system in the Emberborne Godot project.

---

## 1. System Overview

The `DialogueManager` is a global Autoload singleton that provides a modular, data-driven dialogue system for the main game world. It renders a bottom-anchored RPG-style dialogue box that overlays **everything** in the scene — including the main game, the `LaptopUI` subviewport, and even the `SceneManager`'s fade transition layer. While active, it completely intercepts all player input, preventing any commands from leaking through to the game world or any running minigame.

---

## 2. Component Structure

*   **Manager Script Location**: `res://scripts/core/DialogueManager.gd`
*   **Overlay Script Location**: `res://scripts/ui/DialogueOverlay.gd`
*   **Overlay Scene Location**: `res://scenes/ui/DialogueOverlay.tscn`
*   **Dialogue Data Location**: `res://scenes/ui/dialogues/`
*   **Portrait Assets Location**: `res://assets/sprites/portraits/`
*   **Autoload Name**: `DialogueManager`
*   **Input Action**: `dialogue_advance` (Space / Enter)

### Overlay Node Tree
```
DialogueOverlay (CanvasLayer — Layer 110, PROCESS_MODE_ALWAYS)
└── DialogueBox (PanelContainer — anchored to bottom ~28% of screen, cyan glowing border)
    └── MarginContainer
        ├── HBoxContainer
        │   ├── PortraitContainer (PanelContainer — fixed 96×96, hidden when no portrait)
        │   │   └── Portrait (TextureRect — expand fit, keep aspect)
        │   └── VBoxContainer
        │       ├── SpeakerLabel (Label — cyan/blue accent color, 28px)
        │       ├── DialogueLabel (RichTextLabel — typewriter target, 22px)
        │       └── AdvanceIndicator (Label — "▼", pulsing, hidden during typewriter)
        └── SkipButton (Button — top right, "SKIP >>")
```

### CanvasLayer Ordering
The overlay renders above all other systems in the project:

| Layer | System |
| :---: | :--- |
| **110** | **DialogueOverlay** ← always on top |
| 100 | SceneManager (fade transitions) |
| 90 | LaptopUI (diegetic laptop screen) |
| — | Main game world |

---

## 3. Key Design Patterns & Behaviors

### Three-Layer Input Blocking
This is the most critical behavior of the system. When dialogue is active, input must be blocked across three distinct pathways that Godot uses to deliver events. Failing to address all three results in partial input leakage:

1.  **`_input()` interception (SceneTree events)**: `DialogueManager` uses `_input()` instead of `_unhandled_input()`. Because `_input()` runs earlier in Godot's event propagation pipeline than `_unhandled_input()`, this ensures `DialogueManager` sees and consumes the `InputEvent` *before* any game node's `_input()` or `_unhandled_input()` can process it. *Note: Because this aggressive blocking also prevents UI `Control` nodes from receiving mouse clicks, the manager manually detects left-clicks over the `SkipButton`'s geometry to process skip logic before unconditionally calling `get_viewport().set_input_as_handled()`.*

2.  **SubViewportContainer isolation**: `SubViewportContainer` nodes forward input events directly into their child `SubViewport` via their own `_input()` callback, which happens *in parallel* with the main tree's propagation — not after it. `set_input_as_handled()` on the root viewport does **not** prevent this. To solve this, when dialogue starts, `DialogueManager` walks the entire scene tree and calls `set_process_input(false)` and `set_process_unhandled_input(false)` on every `SubViewportContainer` found. Their original processing state is cached in `_blocked_viewport_containers` and fully restored when dialogue ends.

3.  **`Input` singleton polling (action state)**: Many scripts poll input using `Input.is_action_pressed()` inside `_process()`. The `Input` singleton maintains its own global action state, which is updated from raw OS events *before* the SceneTree propagation occurs. Calling `set_input_as_handled()` does not clear this state. To address this, `DialogueManager`'s own `_process()` iterates over every registered action in `InputMap` and calls `Input.action_release(action)` for any that are currently pressed, excepting `dialogue_advance`. This simulates an immediate release and prevents any downstream `_process()` from seeing held inputs.

### Data-Driven Dialogue Files
Dialogue content is completely decoupled from the manager. Each dialogue sequence lives in its own `.gd` file under `res://scenes/ui/dialogues/`. The only requirement is that the file exposes a static method:

```gdscript
static func get_lines() -> Array
```

This returns an `Array` of `Dictionary` objects. Each dictionary represents one line and supports the following keys:

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `"speaker"` | `String` | Yes | The name displayed above the text. Use `""` for no name. |
| `"text"` | `String` | Yes | The dialogue body text. Supports `RichTextLabel` BBCode. |
| `"portrait"` | `String` | No | `res://` path to a portrait texture. Empty string hides the portrait panel. |

Because each file is an independent module, new dialogues can be added or removed at any time without modifying `DialogueManager.gd` or `DialogueOverlay.gd`.

### Inline Formatting (BBCode)
The `DialogueLabel` supports both standard Godot BBCode and custom preprocessed tags to dynamically format text. The typewriter animation properly synchronizes with all tags (they do not incorrectly extend the animation duration).

*   **`[b]text[/b]`**: Bolds the text. Font size is explicitly preserved to match the base size (22px).
*   **`[i]text[/i]`**: Italicizes the text. Font size is explicitly preserved to match the base size (22px).
*   **`[sz=X]text[/sz]`**: Custom font size tag. Example: `[sz=16]whisper[/sz]` or `[sz=32]SHOUT[/sz]`. Maps dynamically to Godot's `[font_size]`.
*   **`[sh rate=X level=Y]text[/sh]`**: Shaking text effect. Example: `[sh]scared[/sh]` or `[sh rate=20.0 level=5]custom shake[/sh]`. This leverages Godot's native character shake so the UI panel itself does not jitter.

### Typewriter Effect & Advance Logic
Text is revealed character-by-character using a `Tween` that animates the `RichTextLabel.visible_characters` property from `0` to the total character count. The speed is controlled by the `TYPEWRITER_SPEED` constant (`0.03` seconds per character) in `DialogueOverlay.gd`.

The advance interaction has three interactions, handled in `DialogueManager._input()`:

1.  **If the typewriter is still animating**: Pressing `dialogue_advance` calls `DialogueOverlay.complete_typewriter()`, which kills the tween and instantly sets `visible_ratio = 1.0`. The ▼ indicator then appears.
2.  **If the typewriter has finished**: Pressing `dialogue_advance` calls `DialogueManager.advance()`, which increments the line index and displays the next line, or calls `close_dialogue()` if the sequence is exhausted.
3.  **Skip Button**: Left-clicking over the `SkipButton` geometry immediately calls `close_dialogue()`, terminating the sequence entirely and playing the out animation.

### Visuals and Animations
The UI features a futuristic cyan/blue visual style. The overlay plays a "hologram boot-up" animation (scaling vertically) upon `show_box()`, a brief glitch/flicker effect upon `display_line()`, and a "power down" animation upon `hide_box()`.

### Lazy Overlay Instantiation
`DialogueOverlay.tscn` is not instantiated at startup. `DialogueManager._ensure_overlay()` is called at the beginning of every `start_dialogue()` invocation. If the overlay node does not yet exist (or has been freed), it is loaded, instantiated, and added directly to `get_tree().root` at that point. This keeps startup cost zero for scenes where no dialogue is ever triggered.

### `PROCESS_MODE_ALWAYS`
Both `DialogueManager` and `DialogueOverlay` set `process_mode = Node.PROCESS_MODE_ALWAYS` in their `_ready()` functions. This ensures the system remains fully operational even when `get_tree().paused = true` is in effect (e.g., when `LaptopUI` opens and pauses the main game). Dialogue can therefore be triggered and run at any point in the game regardless of the global pause state.

### Portrait Display
When `display_line()` is called on the overlay, it checks whether the `portrait` path is non-empty and the resource actually exists via `ResourceLoader.exists()`. If valid, it loads the texture synchronously and assigns it to the `TextureRect`. If the path is empty or invalid, the entire `PortraitContainer` node is hidden, and the text area expands to fill the freed space automatically (because the `VBoxContainer` uses `SIZE_EXPAND_FILL`). A placeholder portrait is provided at `res://assets/sprites/portraits/portrait_template.png` for prototyping.

---

## 4. Public API

All interaction with the dialogue system is done exclusively through the `DialogueManager` autoload.

### Methods

```gdscript
# Load a dialogue sequence from a .gd data file and begin playing it.
# The file must expose: static func get_lines() -> Array
DialogueManager.start_dialogue(dialogue_path: String) -> void

# Begin a dialogue sequence directly from a pre-built array of line dictionaries.
# Useful for dynamically constructed or procedurally generated dialogue.
DialogueManager.start_dialogue_from_array(lines: Array) -> void

# Manually advance to the next line (or close if on the last line).
# Normally driven automatically by the dialogue_advance input action.
DialogueManager.advance() -> void

# Returns true if a dialogue sequence is currently playing.
DialogueManager.is_active() -> bool

# Immediately close and hide the dialogue box, regardless of remaining lines.
# Emits dialogue_finished.
DialogueManager.close_dialogue() -> void
```

### Signals

```gdscript
# Fired once when a new dialogue sequence begins (after the first line is shown).
DialogueManager.dialogue_started

# Fired each time a new line is displayed (including the first).
DialogueManager.dialogue_line_displayed

# Fired when the sequence ends, either naturally (last line advanced) or via close_dialogue().
# Passes the file path string (or "" if started from an array).
DialogueManager.dialogue_finished(file_path: String)
```

---

## 5. Adding New Dialogues

1.  Create a new `.gd` file in `res://scenes/ui/dialogues/`. Copy `test_dialogue.gd` as a starting template.
2.  Implement `static func get_lines() -> Array` returning your line data.
3.  Trigger it from any node in the project:
	```gdscript
	DialogueManager.start_dialogue("res://scenes/ui/dialogues/my_new_dialogue.gd")
	```

No changes to `DialogueManager.gd`, `DialogueOverlay.gd`, or `project.godot` are required.

---

## 6. Usage Rules for Future Development

When extending this system, adhere to the following rules:

1.  **Never call `start_dialogue()` while `is_active()` is true**: The manager silently returns if a dialogue is already running. If you need to chain sequences, connect to the `dialogue_finished` signal and trigger the next sequence from there.
2.  **Do not directly call methods on `DialogueOverlay`**: The overlay is an internal implementation detail of `DialogueManager`. All interaction must go through the manager's public API. The overlay node reference is private (`_overlay`) for this reason.
3.  **Respect the input contract**: Do not add new global input handlers that use `_input()` with higher node priority than `DialogueManager` without considering that they may fire during dialogue. If a system *must* respond during dialogue, check `DialogueManager.is_active()` at the top of its input handler and return early.
4.  **Portrait textures should be pre-imported**: Portrait images referenced in dialogue data must be imported by the Godot editor before runtime. Add new portrait images to `res://assets/sprites/portraits/` and let the editor import them. Using `ResourceLoader.exists()` at runtime will return `false` for files that have not been imported, causing the portrait panel to be silently hidden.
5.  **SubViewport state is restored on close**: The `_blocked_viewport_containers` mechanism stores and restores the exact `process_input` state of each `SubViewportContainer`. Do not manually toggle `set_process_input()` on a `SubViewportContainer` while dialogue is active, as that state will be overwritten on close.
