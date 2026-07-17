# Cutscene Messenger Module Documentation

## Overview

The `CutsceneMessenger` is a texting-app-style cutscene runner designed for Emberborne's futuristic UI. Rather than presenting dialogue in a traditional visual novel format, conversations play out dynamically inside the Laptop SubViewport, mimicking a secure messaging application (e.g., WhatsApp, Signal). 

It features dynamic diegetic timestamps, text decryption sequences, typing indicators, and a robust external queueing API that integrates deeply with the Desktop UI to display unread notification badges.

---

## Architecture & Workflow

The module follows an architecture similar to `DialogueManager`:
1. **Data Files**: Conversations are stored as standalone `.gd` scripts returning static dictionaries.
2. **Registry**: `CutsceneMessenger.gd` maps unique string keys to the paths of these data scripts.
3. **Queueing**: Any script can remotely queue a conversation to be played.
4. **Playback**: When the player opens the app, the UI blocks inputs, sequences the chat bubbles line by line with animations, and marks the cutscene as completed when finished.
5. **History Mode**: Re-opening a completed conversation simply dumps the entire chat history instantaneously without re-playing the animations.

---

## 1. Creating a Cutscene Data Script

To create a new cutscene, create a new script inheriting from `RefCounted` in `res://scenes/ui/cutscenes/`. The script must provide two static functions: `get_sender()` and `get_lines()`.

```gdscript
extends RefCounted

## Returns metadata about the contact displayed in the header bar.
static func get_sender() -> Dictionary:
	return {
		"name": "Agent Voss",
		"profile_picture": "res://assets/sprites/messenger/pfp_placeholder.png"
	}

## Returns the ordered array of message lines for this cutscene.
## "sender": "them" (left-aligned) or "me" (right-aligned).
static func get_lines() -> Array:
	return [
		{
			"sender": "them",
			"text": "We've intercepted a signal. Are you in position?",
		},
		{
			"sender": "me",
			"text": "Copy. Moving to intercept now.",
		}
	]
```
*(Note: Timestamps are generated dynamically at runtime based on the player's real-world system clock, with slight randomized offsets to simulate passing time.)*

---

## 2. Registering the Cutscene

Once your data script is created, you must register it in `CutsceneMessenger.gd`.

Locate the `CUTSCENE_PATHS` dictionary at the top of the file and add your key and path:

```gdscript
const CUTSCENE_PATHS: Dictionary = {
	"test": "res://scenes/ui/cutscenes/test_cutscene.gd",
	"mission_1": "res://scenes/ui/cutscenes/mission_1_intel.gd",
}
```

---

## 3. The External Queueing API & Notification Badge

The Messenger provides a globally accessible API for other scripts (e.g., triggers, level managers, or event buses) to seamlessly queue the next conversation.

### Queueing a Cutscene

Call the static function from anywhere:
```gdscript
CutsceneMessenger.queue_cutscene("mission_1")
```

### How the Notification System Works

1. **Activation**: Calling `queue_cutscene()` checks if the cutscene is already completed. If it is unread, it sets `has_unread_cutscene = true`.
2. **Desktop Visuals**: The `DesktopAppButton` script continuously polls this flag. If `true`, a neon-glowing, pulsing notification badge (with a secondary radar ping ripple) automatically appears on the Messenger's desktop icon.
3. **Resolution**: The unread flag (and thus the notification badge) is **only** cleared when the player actually finishes the cutscene. If the player opens the app but exits before reaching the final message, the badge will remain active on the desktop.

---

## 4. Playback Phases and Visuals

When a cutscene is actively playing, advancing through the dialogue (pressing Space/Enter) triggers a multi-phase animation sequence for each bubble:

### Phase A: Typing
If the sender is `"them"`, the bubble starts as a small (60px) pill. The text cycles through `typing.`, `typing..`, and `typing...` to simulate the NPC composing the message. (If the sender is `"me"`, this phase is skipped.)

### Phase B: Expansion
Once typing is complete, the bubble smoothly expands via a `Tween` from its small pill shape to the exact width required to hold the final message text.

### Phase C: Decryption
The final text is populated but completely scrambled with random hexadecimal/special characters (e.g., `#$X!@`). A tween runs for `0.5s` that progressively unscrambles the string from left to right until the clear text is revealed.

### Input Skipping
During any of these phases, pressing the `dialogue_advance` input action will instantly abort all tweens, skip the typing/decryption sequences, and snap the bubble to its final completed state.

---

## 5. Audio Hooks

The `CutsceneMessenger.tscn` node exposes three `AudioStream` exports in the Inspector:
- `sfx_incoming`: Plays when an incoming message is received.
- `sfx_typing`: Plays (and loops) while the NPC is in the "Typing" phase.
- `sfx_outgoing`: Plays when the player sends an outgoing message.

Assign these via the Godot Editor inspector to complete the immersive soundscape.
