# Cat Game — Project Technical Documentation

> **Scope:** Covers `cat_game` section of the Emberborne project exclusively. References to `snake_tower` and `pet_world` are out of scope. Written against the codebase state as of **July 2026**.

---

## 1. Project Overview

**Cat Game** is a top-down 2D stealth game in Godot 4.7 (GDScript).
- **Gameplay:** Control a cat, sneak past dogs/humans, catch mice, and reach the exit.
- **Score:** Cumulative across levels. Includes time bonuses, mouse points, and catch penalties.
- **Scope:** Prototype phase. Most levels (`level_00` to `level_04`) use placeholders (`ColorRect`). `tutorial00.tscn` is fully art-based.

---

## 2. Project Structure

```
res://
├── scenes/cat_game/
│   ├── core/main.tscn
│   ├── characters/cat.tscn, dog.tscn, human.tscn, mouse.tscn
│   ├── environment/hiding_spot.tscn, exit_door.tscn, wall_segment.tscn, patrol_route.tscn
│   ├── levels/level_00.tscn to level_04.tscn, tutorial00.tscn
│   └── ui/hud.tscn, results_screen.tscn, end_screen.tscn
├── scripts/cat_game/
│   ├── autoload/game_state.gd
│   ├── characters/cat.gd, enemy_base.gd, layered_character.gd, mouse.gd, etc.
│   ├── environment/hiding_spot.gd, exit_door.gd, vision_cone.gd, transition_trigger.gd
│   ├── levels/level_02.gd (shared controller)
│   └── ui/hud.gd, results_screen.gd, end_screen.gd
└── assets/sprites/ (dogs, ui, etc.)
```

---

## 3. Collision Layer Map

| Layer | Bit | Name | Used by |
|---|---|---|---|
| 1 | 1 | WorldSolid | Walls (`StaticBody2D`), furniture |
| 2 | 2 | Player | `Cat` (`CharacterBody2D`) |
| 3 | 4 | Enemy | `Dog`, `Human` (`CharacterBody2D`) |
| 4 | 8 | Mouse | `Mouse` (`CharacterBody2D`) |
| 5 | 16 | ExitDoor | `ExitDoor` (`Area2D`) |
| 6 | 32 | HideArea | `HidingSpot/HideArea` (`Area2D`) |
| 7 | 64 | VisionBlocker | `HidingSpot/VisionBlocker` (`StaticBody2D`), walls |

**Key Mechanics:** Walls use layer 65 (1 + 64) to block both physical movement and enemy vision. `HideArea` checks mask 2.

---

## 4. Input Actions

| Action | Key | Purpose |
|---|---|---|
| `move_up/down/left/right` | W/S/A/D | Movement (via `Input.get_vector`) |
| `ui_accept` | Enter | Advance screens |

---

## 5. Global Systems

### `GameState` (`game_state.gd`)
Autoloaded singleton tracking `total_score` across all levels.
- `add_score(amount: int)`: Appends to score at level completion.
- `reset()`: Resets score (currently unused in codebase).

---

## 6. Scene Reference

### Main & Levels
- **`main.tscn`:** Entry point; instances `level_00.tscn`.
- **`level_00.tscn`:** Placeholder entry. Reloads itself upon completion.
- **`level_01.tscn` to `level_04.tscn`:** Share `level_02.gd`.
- **`tutorial00.tscn`:** Art-based tutorial. Not connected to main flow.

### Characters
- **`cat.tscn` (Player):** Uses `MouseCatchArea` (mask 8) and `Visual` (`AnimatedSprite2D`).
- **`dog.tscn` / `human.tscn`:** Use `VisionCone` and `CatchArea` (mask 2). Configurable via `.tres` resources.
- **`mouse.tscn`:** Catchable target. Uses `patrol_route.tscn`.

### Environment & UI
- **`hiding_spot.tscn`:** `HideArea` (Area2D) and `VisionBlocker` (StaticBody2D).
- **`exit_door.tscn`:** Level completion trigger.
- **`hud.tscn` & `results_screen.tscn`:** Display game state and level breakdowns.
- **`end_screen.tscn`:** Slot-machine final score reveal.

---

## 7. Script Reference & Core Logic

### `cat.gd`
Handles WASD movement and catching mice. Signals: `mouse_caught`, `player_caught`, `hidden_state_changed`.
| Export | Default | Purpose |
|---|---|---|
| `maximum_speed` | 220.0 | Top speed |
| `caught_speed_multiplier` | 1.5 | Speed boost multiplier when caught |
| `caught_invulnerability_duration` | 1.5 | I-frames after catch |

### `enemy_base.gd`
Core AI checking vision raycasts against layer 65.
| Export | Default | Purpose |
|---|---|---|
| `patrol_speed` | 80.0 | Base speed |
| `vision_range` | 180.0 | Detection distance |
| `vision_angle` | 55.0 | Total cone width |
| `alert_duration` | 0.3 | Pause between ALERT and CHASE |
| `lost_sight_delay`| 2.0 | Time before returning to PATROL |

### `level_02.gd`
Core level logic connecting `"player"`, `"enemy"`, `"exit_door"` groups.
| Export | Default | Purpose |
|---|---|---|
| `required_mice` | 2 | Mice needed to unlock exit |
| `maximum_time_bonus`| 3000 | Max bonus for speed |
| `points_per_mouse`| 500 | Value per catch |
| `caught_penalty` | 300 | Score loss per tag |
| `anger_per_detection`| 20.0| Anger added when spotted |

### Other Key Scripts
- **`layered_character.gd`:** Composites multiple `AnimatedSprite2D` layers for human appearances.
- **`hiding_spot.gd`:** Updates cat's `is_hidden` state. `fade_self_only` dictates transparency behavior.
- **`vision_cone.gd`:** Cosmetic renderer for FOV.

---

## 8. Core Systems Deep Dive

- **Enemy AI:** `PATROL` (follows waypoints) → sees cat → `ALERT` (0.3s pause) → `CHASE`. If sight lost for 2s or cat hides → `RETURN`.
- **Hiding:** `hide_zone_count` tracks active hiding spots to prevent flicker. Enemies immediately ignore hidden cats.
- **Scoring:** Live deductions for being caught. At level end: `time_bonus + (mice * points) - (catches * penalty)`.
- **Anger:** Global level anger (0-100). Increases per detection. Scales enemy speed (dogs sprint >= 60%).
- **Level Completion:** Mice caught >= required → door activates → player enters → UI shows results → next level loads.

---

## 9. Level Flow & Communication

- **Flow:** `main.tscn` → `level_00` → `level_01` → `level_02` → `level_03` → `level_04` → `end_screen.tscn`.
- **Communication:** `level_02.gd` utilizes groups (`"enemy"`, `"exit_door"`) to batch-connect signals and command states. Direct references (e.g., `$Cat`, `$HUD`) are used internally. Enemies read the cat's `is_hidden` property directly.

---

## 10. Known Issues & Unfinished Features

1. **Tutorial Flow:** `tutorial00.tscn` is disconnected.
2. **`level_00` End Loop:** Re-loads itself endlessly.
3. **Transition Nodes (`level_03.tscn`):** `NodePath` structures resolve to `null`. Change `destination` to `Node2D`.
4. **End Screen Colors:** Checks `>= 10000` (Rainbow) before 15k, 13k, 11k, making them dead code.
5. **Unused Elements:** `HUD.update_score()`, `dog.tscn`'s NavigationAgent2D, `BracketLabel`, `level_01.gd`.
6. **No Restart Loop:** `GameState.reset()` is never called.

---

## 11. Extension & Modification Guide

- **New Level:** Duplicate `level_03.tscn`, update `required_mice` / `next_scene_path`, and place instances.
- **New Enemy:** Extend `EnemyBase`, adjust vision/speed, and add to `"enemy"` group.
- **Hiding Spots:** Instance under furniture, resize colliders, and use `fade_self_only = true` if un-parented.

---

## 12. Troubleshooting

- **Enemies don't see player:** Verify cat is in `"player"` group, unhidden, and unblocked.
- **Enemies see through walls:** Walls must possess collision layer 65.
- **Whole level dims when hiding:** Set `fade_self_only = true` on the `HidingSpot`.
- **Transitions fail:** Convert `destination` export to `Node2D`.
- **Door locked:** Verify `required_mice` matches in-level `Mouse` instances.

---

## 13. Summary for Developers
Cat Game heavily relies on data-driven exports and shared logic (`level_02.gd`). AI is state-based, vision is raycast-dependent (layer 65), and state persists globally (`GameState`). Priority fixes include the NodePath bug in transitions and End Screen thresholds.
