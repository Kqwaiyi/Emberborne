# Technical Documentation: Gamestate & Story Orchestration

This document details the central state machine inside `GameGlobal` (`res://scripts/core/game_global.gd`), which orchestrates the storyline progression in Emberborne. 

---

## 1. System Overview

The gamestate machine is responsible for seamlessly chaining together different narrative modules such as the `DialogueManager`, `CutsceneMessenger`, `TaskManager`, and `SceneManager`. Instead of hardcoding sequential logic inside individual scripts (which causes tight coupling), the game relies on an event-driven global state machine. 

`GameGlobal` listens to completion signals from these various UI systems and uses them to advance the global `StoryState` enum to the next phase, which in turn automatically triggers the next event.

---

## 2. Core Components

### The `StoryState` Enum
All story phases are strictly defined in the `StoryState` enum inside `game_global.gd`. These act as the single source of truth for the player's current progression in the story.

### Advancement Methods
*   **`advance_story_state(new_state: StoryState)`**: The primary method for changing states. It updates the internal tracker, emits the `story_state_changed` signal, and calls `_handle_state_entry()`.
*   **`_advance_with_delay(new_state: StoryState, delay: float = 0.8)`**: A helper function used heavily during automated transitions. It uses a `SceneTreeTimer` to introduce a brief pause before advancing, giving UI elements time to animate out or preventing events from abruptly snapping from one to the next.

### `_handle_state_entry(state: StoryState)`
This massive `match` statement acts as the "Entry Action" for the state machine. Whenever a new state begins, this function fires the associated event. Examples include:
*   `DialogueManager.start_dialogue()`
*   `CutsceneMessenger.queue_cutscene()`
*   `TaskManager.show_task()`
*   `SceneManager.change_scene_to_file()`

---

## 3. Signal Integration & Transitions

The state machine advances itself by catching global signals emitted by the UI subsystems when they finish their respective actions.

*   **`_on_dialogue_finished(file_path)`**: Triggered by `DialogueManager.dialogue_finished`. Used to progress out of dialogue-heavy states (e.g., `PHASE1_APARTMENT`, `PHASE3_LOANDIALOGUE1`).
*   **`_on_cutscene_completed(key)`**: Triggered by `CutsceneMessenger.cutscene_completed`. Used to progress out of laptop texting sequences (e.g., `PHASE1_IRSMAIN1`, `PHASE3_LOANCHAT2`).
*   **`_on_task_acknowledged()`**: Triggered by `TaskManager.task_acknowledged`. Used when the player clicks the 'X' to close a popup directive, usually leading into a cutscene or waiting state.
*   **`_on_lobby_scene_opened()`**: Connected dynamically by the `lobby_manager.gd` in the Pet World. This acts as a physical trigger transition; if the player is in the correct task state (`PHASE1_TASK_GO_TO_PET_WORLD` or `PHASE4_TASK_GO_TO_PET_WORLD_`), entering this specific scene pushes the story forward.

---

## 4. Current Phase Pipelines

### Phase 1: The Setup
1.  **`PHASE1_EXPOSITION`**: Initiated by `exposition.tscn`, waiting 2 seconds before loading the main map and kicking off Phase 1.
2.  **`PHASE1_APARTMENT`**: Plays the initial apartment dialogue.
3.  **`PHASE1_TASK_CHECK_HOLOGRAM`**: Prompts the player to open the hologram.
4.  **`PHASE1_IRSMAIN(1-4)` & `PHASE1_IRSDIALOGUE(1-4)`**: An alternating loop of texting cutscenes and internal monologues.
5.  **`PHASE1_TASK_GO_TO_PET_WORLD`**: Prompts the player to travel to the Pet World.

### Phase 2: Pet World Entry
1.  **`PHASE2_PETWORLD_ENTRY`**: Triggered physically by loading into the lobby scene. Plays the Pet World dialogue.
2.  **`PHASE2_TASK_GO_TO_MESSENGER`**: Directs the player to open their messenger app again.

### Phase 3: The Loan Sequence
1.  **`PHASE3_LOANCHAT1` / `PHASE3_LOANDIALOGUE1`**: The first loan bot interaction and reaction.
2.  **`PHASE3_LOANCHAT2` / `PHASE3_LOANDIALOGUE2`**: The second loan bot interaction and reaction.

### Phase 4: Return to World
1.  **`PHASE4_DOOR`**: Immediately triggered after the loan sequence. Reloads the home map (`map.tscn`) via `SceneManager` with a 2-second fade-out.
2.  **`PHASE4_TASK_GO_TO_PET_WORLD_`**: Initiated 1 second after returning to the apartment. Tasks the player to return to the Pet World.
3.  **`PHASE4_TASK_JOIN_TOURNAMENT`**: Triggered physically by returning to the Pet World lobby. Tasks the player to select a pet and join the tournament.

---

## 5. Usage Rules for Future Development

1.  **Never hardcode sequential events**: If a cutscene must follow a dialogue, DO NOT call `CutsceneMessenger` from the dialogue script. Define a new `StoryState`, add the cutscene trigger to `_handle_state_entry`, and add the transition logic to `_on_dialogue_finished`.
2.  **Rely on `_advance_with_delay`**: Always use `_advance_with_delay()` instead of `advance_story_state()` for automated transitions. Immediate transitions can cause input locks or visual glitches (e.g., UI boxes overlapping).
3.  **Beware of Scene Reloads**: When triggering a `SceneManager` scene change inside `_handle_state_entry`, ensure that `SceneManager` cleans up global pauses (`get_tree().paused = false`). Otherwise, transitioning from a paused state (like the Laptop UI) into a new scene will leave the new scene permanently paused.
