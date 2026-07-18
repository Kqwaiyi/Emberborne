# Cutscene Messenger Module Documentation

## Overview

The `CutsceneMessenger` is a texting-app-style cutscene runner designed for Emberborne's futuristic UI. Rather than presenting dialogue in a traditional visual novel format, conversations play out dynamically inside the Laptop SubViewport, mimicking a secure messaging application (e.g., WhatsApp, Signal). 

It features a dual-scene architecture, dynamic diegetic timestamps, text decryption sequences, typing indicators, active telemetry UI animations, and a robust external queueing API that integrates deeply with the Desktop UI to display unread notification badges.

---

## Architecture & Workflow

The module has been heavily upgraded to split responsibilities into two separate scenes, mediated by a shared global state:

1. **Data Files**: Conversations are stored as standalone `.gd` scripts returning static dictionaries.
2. **Registry & Global State**: `CutsceneMessenger.gd` contains a registry mapping unique string keys to script paths, and acts as the global state holder (`_contact_histories`, `_contact_profile_pics`, `queued_cutscene_key`, `selected_contact`).
3. **Dual-Scene Structure**:
    - **CutsceneMessengerList.tscn**: Acts as the "home screen." It parses the global state to render a WhatsApp-style list of completed conversations and any currently queued cutscene (marked with a pulsing red badge). It reads the cutscene data directly to generate hover previews.
    - **CutsceneMessenger.tscn**: The active chat interface. When a row in the list is clicked, `CutsceneMessenger.selected_contact` is set, and the `LaptopUI` transitions to this scene. It either dumps the completed history instantly, or locks inputs to sequence a new cutscene line-by-line.
4. **Queueing**: Any script can remotely queue a conversation to be played.
5. **Playback**: When the player enters a queued chat, the UI blocks inputs, sequences the chat bubbles line by line with animations, and marks the cutscene as completed when finished.

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
*(Note: Timestamps are generated dynamically at runtime based on the player's real-world system clock adjusted for local time zone bias, with slight randomized offsets to simulate passing time.)*

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

1. **Activation**: Calling `queue_cutscene()` checks if the cutscene is already completed. If it is unread, it sets `has_unread_cutscene = true` and updates `queued_cutscene_key`.
2. **Desktop Visuals**: The `DesktopAppButton` script continuously polls this flag. If `true`, a neon-glowing, pulsing notification badge (with a secondary radar ping ripple) automatically appears on the Messenger's desktop icon.
3. **List Visuals**: The `CutsceneMessengerList` will render this queued conversation at the top of the list, complete with a breathing red notification badge and the real first line of the cutscene extracted for the hover preview.
4. **Resolution**: The unread flag (and thus the notification badges) is **only** cleared when the player actually finishes the cutscene inside the chat view.

---

## 4. Advanced Futuristic UI Features

The Messenger UI is heavily engineered to feel like a living, sci-fi operating system:

- **Decryption Text Reveal**: List items slide in sequentially, and their text doesn't just fade—it rapidly decrypts from random ASCII/hex characters into the actual names.
- **Active Telemetry**: The right edge of the list rows features dynamic ping and hex data that randomly fluctuates via background timers, giving the UI a constantly processing feel.
- **Kinetic Hover & Header Previews**: Hovering over a row physically shifts its margins rightward and updates a sleek, right-aligned text preview in the main header displaying the contact's name and their first message.
- **Placeholder Swap Animation**: When clicking a conversation, the layout system executes a dummy-control swap. The actual row is popped out of the layout (without causing the VBox to collapse) and aggressively slides off-screen to the right in parallel with the scene crossfade.

---

## 5. Playback Phases and Visuals (Inside Chat)

When a cutscene is actively playing, advancing through the dialogue (pressing Space/Enter) triggers a multi-phase animation sequence for each bubble:

### Phase A: Typing
If the sender is `"them"`, the bubble starts as a small pill. The text cycles through `typing.`, `typing..`, and `typing...` to simulate the NPC composing the message. (If the sender is `"me"`, this phase is skipped.)

### Phase B: Expansion
Once typing is complete, the bubble smoothly expands via a `Tween` from its small pill shape to the exact width required to hold the final message text.

### Phase C: Decryption
The final text is populated but completely scrambled with random hexadecimal/special characters. A tween runs that progressively unscrambles the string from left to right until the clear text is revealed.

### Input Skipping
During any of these phases, pressing the `dialogue_advance` input action will instantly abort all tweens, skip the sequences, and snap the bubble to its final completed state.

---

## 6. Audio Hooks

The Messenger relies heavily on UI audio for its futuristic feel. Various nodes use standard `AudioStreamPlayer` assignments for hover blips and satisfying tech clicks. 
The chat scene (`CutsceneMessenger.tscn`) specifically exposes three `AudioStream` exports in the Inspector:
- `sfx_incoming`: Plays when an incoming message is received.
- `sfx_typing`: Plays (and loops) while the NPC is in the "Typing" phase.
- `sfx_outgoing`: Plays when the player sends an outgoing message.
