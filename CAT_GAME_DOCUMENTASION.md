# Cat Game — Project Technical Documentation

> **Scope:** This document covers the `cat_game` section of the Emberborne project exclusively.  
> All references to `snake_tower` and `pet_world` are out of scope.  
> Written against the codebase state as of **July 2026**.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Structure](#2-project-structure)
3. [Collision Layer Map](#3-collision-layer-map)
4. [Input Actions](#4-input-actions)
5. [Global Systems](#5-global-systems)
6. [Scene Reference](#6-scene-reference)
7. [Script Reference](#7-script-reference)
8. [Core Systems Deep Dive](#8-core-systems-deep-dive)
9. [Level Flow: Start to Finish](#9-level-flow-start-to-finish)
10. [Scene and Script Communication](#10-scene-and-script-communication)
11. [Known Issues and Unfinished Features](#11-known-issues-and-unfinished-features)
12. [Extension and Modification Guide](#12-extension-and-modification-guide)
13. [Troubleshooting](#13-troubleshooting)
14. [Summary for New Developers](#14-summary-for-new-developers)

---

## 1. Project Overview

**Cat Game** is a top-down 2D stealth game in Godot 4.7 built with GDScript. The player controls a cat that must:

1. Sneak around a level populated by patrolling enemies (dogs and humans).
2. Catch a required number of mice to unlock the exit door.
3. Reach the exit door to complete the level.

The game tracks a running score that carries across all levels. Score is built from starting points, mouse catches, time bonuses, and penalties for being caught by enemies. All levels feed into a final **End Screen** that reveals the cumulative total.

### Current Project Scope

- The game is in **demo / prototype phase**. Most levels use placeholder art (solid-colour rectangles for walls, floors, and the cat itself). `tutorial00.tscn` is the exception — it is a fully art-based level with real sprite assets.
- The cat character uses a real `AnimatedSprite2D` with directional walk/run/idle animations. Dogs use real sprite sheets. Humans use a layered sprite system.
- Mice use real animated sprites. Hiding spots, walls, and doors in the main levels are still placeholder `ColorRect` nodes.
- Four playable levels (`level_01` through `level_04`) plus one standalone tutorial level (`tutorial00`) exist. A placeholder `level_00` serves as the current entry point via `main.tscn`.

---

## 2. Project Structure

```
res://
├── project.godot
├── scenes/
│   └── cat_game/
│       ├── core/
│       │   └── main.tscn               ← entry point; instances level_00
│       ├── characters/
│       │   ├── cat.tscn                ← player character
│       │   ├── dog.tscn                ← dog enemy
│       │   ├── human.tscn              ← human enemy (layered sprites)
│       │   ├── mouse.tscn              ← catchable mouse
│       │   └── enemy_base.tscn         ← base enemy (not placed directly)
│       ├── environment/
│       │   ├── hiding_spot.tscn        ← reusable hiding furniture node
│       │   ├── exit_door.tscn          ← level exit trigger
│       │   ├── wall_segment.tscn       ← reusable wall collision block
│       │   ├── patrol_route.tscn       ← waypoint path for enemies / mice
│       │   └── solid_furniture.tscn    ← collidable furniture block
│       ├── levels/
│       │   ├── level_00.tscn           ← placeholder entry level (linked from main.tscn)
│       │   ├── level_01.tscn           ← first real level
│       │   ├── level_02.tscn           ← second level
│       │   ├── level_03.tscn           ← third level (multi-section with transitions)
│       │   ├── level_04.tscn           ← fourth / final level
│       │   └── tutorial00.tscn         ← art-based tutorial (NOT in main scene chain yet)
│       └── ui/
│           ├── hud.tscn                ← in-level HUD overlay
│           ├── results_screen.tscn     ← between-level score breakdown
│           └── end_screen.tscn         ← final cumulative score reveal
│
├── scripts/
│   └── cat_game/
│       ├── autoload/
│       │   └── game_state.gd           ← global score singleton
│       ├── characters/
│       │   ├── cat.gd                  ← player logic
│       │   ├── cat_animator.gd         ← player AnimatedSprite2D controller
│       │   ├── cat_visual.gd           ← placeholder visual (blue square)
│       │   ├── layered_character.gd    ← multi-layer AnimatedSprite2D system
│       │   ├── character_appearance.gd ← saved appearance Resource
│       │   ├── enemy_base.gd           ← shared enemy AI (patrol/alert/chase/return)
│       │   ├── dog.gd                  ← dog enemy (extends EnemyBase)
│       │   ├── dog_animator.gd         ← dog AnimatedSprite2D controller
│       │   ├── enemy_animator.gd       ← placeholder enemy visual
│       │   ├── human.gd                ← human enemy (extends EnemyBase)
│       │   ├── mouse.gd                ← catchable mouse logic
│       │   ├── mouse_animator.gd       ← mouse AnimatedSprite2D controller
│       │   └── shadow.gd               ← draws an ellipse shadow under any node
│       ├── environment/
│       │   ├── hiding_spot.gd          ← furniture hiding zone logic
│       │   ├── exit_door.gd            ← level completion trigger
│       │   ├── vision_cone.gd          ← draws enemy vision cone (visual only)
│       │   ├── transition_trigger.gd   ← section teleport with screen fade
│       │   └── cactus_hazard.gd        ← instant-catch hazard (Area2D)
│       ├── levels/
│       │   └── level_02.gd             ← shared level controller (used by levels 01–04)
│       └── ui/
│           ├── hud.gd                  ← in-game HUD logic
│           ├── results_screen.gd       ← between-level results panel
│           └── end_screen.gd           ← final animated score reveal
│
└── assets/
	├── sprites/                        ← character and environment sprite sheets
	│   ├── dogs/                       ← dog variant PNGs (dog1.png–dog5.png)
	│   └── ...
	└── ui/
		└── Loot/                       ← anger face stage images (stage1–3 .png)
```

---

## 3. Collision Layer Map

Godot uses bitmasks for collision layers and masks. The following layers are used in Cat Game:

| Layer # | Bit value | Name            | Used by                                             |
|---------|-----------|-----------------|-----------------------------------------------------|
| 1       | 1         | WorldSolid      | Walls (`StaticBody2D`), furniture, `WallSegment`    |
| 2       | 2         | Player          | `Cat` (`CharacterBody2D`)                           |
| 3       | 4         | Enemy           | `Dog`, `Human` (`CharacterBody2D`)                  |
| 4       | 8         | Mouse           | `Mouse` (`CharacterBody2D`)                         |
| 5       | 16        | ExitDoor        | `ExitDoor` (`Area2D`)                               |
| 6       | 32        | HideArea        | `HidingSpot/HideArea` (`Area2D`)                    |
| 7       | 64        | VisionBlocker   | `HidingSpot/VisionBlocker` (`StaticBody2D`), walls  |

**Important combined values:**
- Walls use `collision_layer = 65` (1 + 64), meaning they block both physical movement (layer 1) and enemy vision raycasts (layer 7) simultaneously.
- `HideArea` has `collision_mask = 2` — it only detects the player (layer 2).
- `ExitDoor` has `collision_mask = 2` — it only fires when the player enters.
- The enemy vision raycast in `enemy_base.gd` checks `(1 << 6) | (1 << 0)` = 65, catching both solid walls and `VisionBlocker` geometry.
- `HidingSpot/VisionBlocker` is on layer 64 only, so it blocks vision without physically stopping the cat or enemies from walking through it.

---

## 4. Input Actions

Defined in `project.godot` under `[input]`. Physical keys only (no controller mappings configured yet).

| Action       | Key   | Purpose                        |
|--------------|-------|--------------------------------|
| `move_up`    | W     | Move cat upward                |
| `move_down`  | S     | Move cat downward              |
| `move_left`  | A     | Move cat left                  |
| `move_right` | D     | Move cat right                 |
| `ui_accept`  | Enter | Advance through ResultsScreen  |

All four movement actions are read together via `Input.get_vector("move_left", "move_right", "move_up", "move_down")` in `cat.gd`. The vector supports analogue stick input via the configured `deadzone: 0.5`.

---

## 5. Global Systems

### 5.1 `GameState` Autoload

- **File:** `scripts/cat_game/autoload/game_state.gd`
- **Registration:** `project.godot` → `[autoload]` → `GameState="*res://scripts/cat_game/autoload/game_state.gd"`
- **Persists:** Across all scene changes for the duration of a play session.

**Variables:**

| Variable      | Type  | Default | Purpose                             |
|---------------|-------|---------|-------------------------------------|
| `total_score` | `int` | `0`     | Running cumulative score across all levels |

**Methods:**

| Method                     | Purpose                                  |
|----------------------------|------------------------------------------|
| `add_score(amount: int)`   | Adds `amount` to `total_score`           |
| `reset()`                  | Resets `total_score` to 0                |

**Usage pattern:**  
At the end of each level, `level_02.gd` calls `GameState.add_score(level_total)`. The HUD reads `GameState.total_score` on `_ready()` to show the running total. The `EndScreen` reads it to display the final cumulative score.

> **Note:** `GameState.reset()` is defined but is never called anywhere in the current codebase. The score accumulates indefinitely until the game process ends. There is no "New Game" flow implemented yet.

---

## 6. Scene Reference

### 6.1 `main.tscn` — Entry Point

- **Path:** `scenes/cat_game/core/main.tscn`
- **Set as:** Project main scene in `project.godot`
- **Root node:** `Main` (`Node2D`)
- **Contents:** Instances `level_00.tscn` as a child named `Level01`
- **Purpose:** Simple container. Does not have its own script. To change the starting level, update the instanced scene reference.

---

### 6.2 `level_00.tscn` — Placeholder Level

- **Root node:** `Level01` (`Node2D`) with an **embedded GDScript** (not the shared `level_02.gd`)
- **Purpose:** First playable prototype level. Uses `ColorRect` nodes for all visuals. No real art.
- **Structure:** `Environment/Walls` (StaticBody2D blocks), `Environment/Floor` (ColorRect), hiding spots, patrol routes, Cat, enemies, HUD, ResultsScreen
- **Script defaults:** `required_mice = 3`, `total_mice = 5`, `next_scene_path = ""` (empty → reloads itself on completion)
- **Known issue:** Root node is named `Level01` despite being in `level_00.tscn`. The embedded script is a copy/variant of `level_02.gd` — changes to `level_02.gd` will NOT affect this scene.

---

### 6.3 `level_01.tscn` through `level_04.tscn` — Main Levels

All four scenes share `scripts/cat_game/levels/level_02.gd` as their script. Exported variables are overridden per scene.

| Scene        | `required_mice` | `total_mice` | `next_scene_path`           |
|--------------|-----------------|--------------|-----------------------------|
| `level_01`   | 2 (default)     | 3 (default)  | `level_02.tscn`             |
| `level_02`   | 4               | 7            | `level_03.tscn`             |
| `level_03`   | 5               | 7            | `level_04.tscn`             |
| `level_04`   | 1               | 7            | `end_screen.tscn`           |

**Common scene structure in each level:**
```
[LevelRoot] (Node2D, script = level_02.gd)
├── Environment/
│   ├── Floor (ColorRect)
│   └── Walls/ (StaticBody2D children — WallTop, WallBottom, WallLeft, WallRight, IntH1–IntH4)
├── HidingSpots/ (instances of hiding_spot.tscn)
├── Mice/ (instances of mouse.tscn with patrol_route set)
├── Patrol Routes/ (instances of patrol_route.tscn)
├── Cat (instance of cat.tscn)
├── Characters/ (dog.tscn and/or human.tscn instances)
├── ExitDoor (instance of exit_door.tscn)
├── HUD (instance of hud.tscn)
└── ResultsScreen (instance of results_screen.tscn)
```

`level_02.tscn` additionally contains multiple `cactus_hazard.gd` nodes (instant-catch hazard zones scattered around the level).

---

### 6.4 `tutorial00.tscn` — Art Tutorial Level

- **Path:** `scenes/cat_game/levels/tutorial00.tscn`
- **Root node:** `tutorial map` (`Node2D`), script = `level_02.gd` (via ExtResource)
- **NOT connected to the main scene chain** — `main.tscn` does not instance or link to it
- **Structure:** Single section called `seciton 1` (typo in scene data) containing real sprite-based floor, walls, furniture nodes, hiding spots, exit doors, patrol routes, dogs, humans, and a Cat instance
- **Hiding spots in this scene:**
  - `seciton 1/Rbed3/BedHide` — correctly nested under the bed furniture node
  - `seciton 1/Coloured_round_table/TableHide` — correctly nested under the table
  - `seciton 1/SofaHide` — direct child of `seciton 1` (map-level parent); has `fade_self_only = true` set to prevent the entire section from dimming
- **Section transitions:** `transition_trigger.gd` is attached to black Sprite2D trigger nodes in `level_03.tscn` and `level_04.tscn` for section-to-section teleportation

---

### 6.5 `cat.tscn` — Player Character

- **Root:** `Cat` (`CharacterBody2D`), `collision_layer = 2`, script = `cat.gd`
- **Children:**

| Node              | Type                    | Purpose                                                    |
|-------------------|-------------------------|------------------------------------------------------------|
| `Shadow`          | `Node2D`                | Draws ellipse ground shadow; script = `shadow.gd`          |
| `BodyCollision`   | `CollisionShape2D`      | Physical hitbox (circle shape)                             |
| `MouseCatchArea`  | `Area2D` (mask=8)       | Detects overlap with mice (layer 4) for catching           |
| `CatchCollision`  | `CollisionShape2D`      | Shape for `MouseCatchArea`                                 |
| `Camera2D`        | `Camera2D`              | Follows the cat                                            |
| `CaughtSound`     | `AudioStreamPlayer2D`   | Plays on being caught by an enemy                          |
| `Visual`          | `AnimatedSprite2D`      | Cat sprite; script = `cat_animator.gd`                     |

---

### 6.6 `dog.tscn` — Dog Enemy

- **Root:** `Dog` (`CharacterBody2D`), `collision_layer = 4`, script = `dog.gd`
- **Children:**

| Node               | Type                    | Purpose                                                    |
|--------------------|-------------------------|------------------------------------------------------------|
| `Shadow`           | `Node2D`                | Ground shadow; script = `shadow.gd`                        |
| `BodyCollision`    | `CollisionShape2D`      | Physical hitbox                                            |
| `VisionCone`       | `Node2D`                | Draws the visible detection cone; script = `vision_cone.gd`|
| `CatchArea`        | `Area2D` (mask=2)       | Overlaps cat to trigger a catch                            |
| `CatchCollision`   | `CollisionShape2D`      | Shape for `CatchArea`                                      |
| `NavigationAgent2D`| `NavigationAgent2D`     | Present but unused — movement is direct, not nav-mesh based|
| `AlertIcon`        | `Label`                 | Shows an exclamation mark when dog spots the cat           |
| `Visual`           | `AnimatedSprite2D`      | Dog sprite; script = `dog_animator.gd`                     |

Configurable via **dog variants** (`.tres` resources in `scenes/cat_game/characters/dog_variants/`): `dog1.tres` through `dog5.tres` — each sets a different sprite sheet on the `Visual` node.

---

### 6.7 `human.tscn` — Human Enemy

- **Root:** `Human` (`CharacterBody2D`), `collision_layer = 4`, script = `human.gd`
- **Same child structure as dog except:**
  - `Visual` is a `Node2D` with four `AnimatedSprite2D` children (`LayerBase`, `LayerOutfit`, `LayerHair`, `LayerHat`) managed by `layered_character.gd`
  - Human variants are set via `.tres` resources in `human_variants/` (body, hair1/2, hat1/2, outfit1/2/3)

---

### 6.8 `mouse.tscn` — Catchable Mouse

- **Root:** `Mouse` (`CharacterBody2D`), `collision_layer = 8`, script = `mouse.gd`
- **Children:** `Shadow` (`shadow.gd`), `BodyCollision`, `Visual` (`AnimatedSprite2D`, script = `mouse_animator.gd`)
- Mouse variants (`.tres` resources in `mouse_variants/`): `mouse1.tres` through `mouse3.tres`

---

### 6.9 `hiding_spot.tscn` — Hiding Zone

- **Root:** `HidingSpot` (`Node2D`), script = `hiding_spot.gd`
- **Children:**

| Node              | Type                | Collision layer | Purpose                                 |
|-------------------|---------------------|-----------------|-----------------------------------------|
| `HideArea`        | `Area2D`            | 32, mask=2      | Detects cat entering/leaving            |
| `HideCollision`   | `CollisionShape2D`  | —               | Shape for `HideArea`                    |
| `VisionBlocker`   | `StaticBody2D`      | 64, mask=0      | Blocks enemy vision raycasts; no physical collision |
| `VisionCollision` | `CollisionShape2D`  | —               | Shape for `VisionBlocker`               |

---

### 6.10 `exit_door.tscn` — Level Exit

- **Root:** `ExitDoor` (`Area2D`), `collision_layer = 16`, `collision_mask = 2`, script = `exit_door.gd`
- **Children:** `Visual` (`ColorRect` — red when locked, green when active), `DoorCollision` (`CollisionShape2D`)

---

### 6.11 `wall_segment.tscn` — Reusable Wall

- **Root:** `WallSegment` (`StaticBody2D`), `collision_layer = 65` (layers 1 + 7)
- **Children:** `Visual` (`ColorRect`), `BodyCollision` (`CollisionShape2D`)
- The dual layer (1 + 64) means walls both block character movement AND block enemy vision rays.

---

### 6.12 `patrol_route.tscn` — Enemy Waypoint Path

- **Root:** `PatrolRoute` (`Node2D`)
- **Children:** `Point01` (`Marker2D`), `Point02` (`Marker2D`) — extend with more `Marker2D` children for longer routes
- Referenced by enemies and mice via `@export var patrol_route: NodePath`

---

### 6.13 `hud.tscn` — In-Level HUD

- **Root:** `HUD` (`CanvasLayer`), script = `hud.gd`
- **Key child paths accessed by script:**

| Path                                          | Node type      | Displays                        |
|-----------------------------------------------|----------------|---------------------------------|
| `HUDPanel/HBox/InfoBox/TimeRow/TimeLabel`     | `Label`        | Elapsed time (MM:SS)            |
| `HUDPanel/HBox/InfoBox/MiceRow/MiceLabel`     | `Label`        | Mice caught / required          |
| `TopRightPanel/VBox/AngerHBox/BarBox/AngerBar`| `ProgressBar`  | Enemy anger level (0–100)       |
| `TopRightPanel/VBox/AngerHBox/FaceBox/FaceIcon`| `TextureRect` | Anger face sprite (3 stages)    |
| `TopRightPanel/VBox/AngerHBox/FaceBox/TopIcon`| `TextureRect`  | Anger hat/accessory sprite      |
| `TopRightPanel/VBox/InfoLine`                 | `Label`        | Total score + total mice counts |
| `MessageLabel`                                | `Label`        | Floating feedback messages      |
| `MessageTimer`                                | `Timer`        | Auto-hides `MessageLabel`       |

---

### 6.14 `results_screen.tscn` — Level Results Panel

- **Root:** `ResultsScreen` (`CanvasLayer`), `process_mode = PROCESS_MODE_ALWAYS`, script = `results_screen.gd`
- **Starts hidden** (`visible = false`); shown by `level_02.gd` at level end
- Contains a stats breakdown panel with rows for: Time, Mice Caught, Time Bonus, Mouse Points, Times Hurt, Level Total, Previous Total, New Total
- `NextButton` advances to `next_scene_path` or reloads current scene if path is empty

---

### 6.15 `end_screen.tscn` — Final Score Screen

- **Root:** `EndScreen` (`Control`), script = `end_screen.gd`
- **Contains:** Background `ColorRect`, `Panel/VBox/ScoreCenter/ScoreRow` (`HBoxContainer` — digits added dynamically), `BracketLabel` (`Label` — placeholder text)
- Reads `GameState.total_score` and runs a slot-machine digit animation

---

## 7. Script Reference

### 7.1 `cat.gd`

**Class:** `Cat` | **Extends:** `CharacterBody2D`  
**Attached to:** `cat.tscn` root node

#### Exports

| Variable                       | Default | Purpose                                               |
|--------------------------------|---------|-------------------------------------------------------|
| `maximum_speed`                | 220.0   | Top movement speed (px/s)                             |
| `acceleration_time`            | 0.2     | Seconds to reach full speed from rest                 |
| `deceleration_time`            | 0.2     | Seconds to stop from full speed                       |
| `caught_speed_multiplier`      | 1.5     | Speed multiplier applied immediately after being caught|
| `caught_speed_duration`        | 1.5     | How long the speed boost lasts (seconds)              |
| `caught_invulnerability_duration` | 1.5  | How long the cat is immune after being caught (seconds)|

#### Runtime State

| Variable           | Purpose                                                      |
|--------------------|--------------------------------------------------------------|
| `is_hidden`        | `true` while inside a hiding spot — enemies ignore the cat   |
| `is_invulnerable`  | `true` during the post-catch immunity window                 |
| `hide_zone_count`  | Counter of overlapping hide zones (prevents flicker on exit) |
| `is_boosted`       | `true` during the post-catch speed boost window              |
| `_input_enabled`   | Set to `false` by the level when it ends                     |

#### Signals

| Signal                              | When emitted                                              |
|-------------------------------------|-----------------------------------------------------------|
| `mouse_caught(mouse_points: int)`   | Cat's `MouseCatchArea` overlaps a catchable mouse         |
| `player_caught()`                   | `trigger_caught()` is called (and not invulnerable)       |
| `hidden_state_changed(is_hidden)`   | Cat enters or exits a hiding zone                         |

#### Key Methods

| Method                         | Called by               | Purpose                                                   |
|--------------------------------|-------------------------|-----------------------------------------------------------|
| `_apply_movement(delta)`       | `_physics_process`      | Reads WASD input, applies acceleration/deceleration        |
| `enter_hide_zone()`            | `hiding_spot.gd`        | Increments hide counter; goes transparent at count = 1    |
| `leave_hide_zone()`            | `hiding_spot.gd`        | Decrements hide counter; restores opacity when count = 0  |
| `trigger_caught()`             | `level_02.gd`, `enemy_base.gd` | Activates invulnerability + speed boost, plays sound|
| `disable_input()`              | `level_02.gd`           | Stops all player movement (called at level completion)    |
| `_update_outline(bool)`        | Internal timers         | Calls `set_outline()` on `Visual` for red caught tint     |

#### Node references (`@onready`)

| Variable       | Path             | Type                    |
|----------------|------------------|-------------------------|
| `_visual`      | `$Visual`        | `AnimatedSprite2D`      |
| `_catch_area`  | `$MouseCatchArea`| `Area2D`                |
| `_caught_sound`| `$CaughtSound`   | `AudioStreamPlayer2D`   |

---

### 7.2 `cat_animator.gd`

**Extends:** `AnimatedSprite2D`  
**Attached to:** `Visual` node inside `cat.tscn`

Manages the cat's sprite animation. Expected animation names in `SpriteFrames`: `walk_left`, `walk_right`, `run_left`, `run_right`, `idle1`, `idle2`.

#### Exports

| Variable     | Default | Purpose                                          |
|--------------|---------|--------------------------------------------------|
| `idle_delay` | 1.0     | Seconds of stillness before a random idle plays  |

#### Key constants

`ANIM_OFFSETS` — a `Dictionary` mapping each animation name to a `Vector2` pixel offset. Used to compensate for sprite anchor differences across animations so the cat stays visually centred over its hitbox.

#### Key Methods

| Method                      | Called by      | Purpose                                                       |
|-----------------------------|----------------|---------------------------------------------------------------|
| `update_direction(vel)`     | `cat.gd`       | Chooses walk/run + left/right based on velocity               |
| `set_outline(is_active)`    | `cat.gd`       | Tints sprite red (caught) or white (normal), preserving alpha |
| `set_force_run(enabled)`    | `cat.gd`       | Forces run animation during speed-boost window                |
| `_pick_random_idle()`       | `_process`     | Randomly picks `idle1` or `idle2` after `idle_delay`          |
| `_play(anim)`               | Internal       | Applies offset from `ANIM_OFFSETS` then calls `play(anim)`    |

> **On start:** `_ready()` calls `_play("walk_right")` so the cat begins in a walking pose rather than the `AnimatedSprite2D` default.

---

### 7.3 `cat_visual.gd`

**Extends:** `Node2D`  
**Attached to:** `Visual` (`Node2D`) inside older cat scene variants  

A **placeholder visual** that draws a blue square with a yellow directional triangle using `_draw()`. Kept for backward compatibility. In the current `cat.tscn`, the `Visual` node is an `AnimatedSprite2D` with `cat_animator.gd` instead — `cat_visual.gd` is not actively used but remains in the project.

Exports `use_placeholder: bool = true` — flip to `false` and add an `AnimatedSprite2D` child named `Sprite` to switch to sprite mode.

---

### 7.4 `enemy_base.gd`

**Class:** `EnemyBase` | **Extends:** `CharacterBody2D`  
**Attached to:** Not used directly — extended by `dog.gd` and `human.gd`

The core AI for all enemies. Implements a four-state machine:

```
PATROL → ALERT → CHASE → RETURN → PATROL
```

#### Exports

| Variable             | Default | Purpose                                                      |
|----------------------|---------|--------------------------------------------------------------|
| `patrol_speed`       | 80.0    | Movement speed during PATROL and RETURN states               |
| `chase_speed`        | 55.0    | Base chase speed at 0% anger (scales up with anger)          |
| `cat_max_speed`      | 220.0   | Used as reference for anger-scaled chase speed ceiling        |
| `vision_range`       | 180.0   | Maximum detection distance (pixels)                          |
| `vision_angle`       | 55.0    | Total cone width in degrees (half-angle is 27.5° each side)  |
| `patrol_route`       | `""`    | `NodePath` to a `patrol_route.tscn` instance                 |
| `patrol_ping_pong`   | `true`  | If true, enemy reverses at end of route; if false, loops     |
| `lost_sight_delay`   | 2.0     | Seconds of losing sight before giving up chase               |
| `alert_duration`     | 0.3     | Brief pause before transitioning from ALERT to CHASE         |
| `bark_duration`      | 1.0     | How long enemy stops to bark after tagging the cat           |

#### State Machine Details

**PATROL:** Enemy walks between `_patrol_points` in sequence. Calls `_can_see_player()` every frame. On detection, transitions to ALERT.

**ALERT:** Enemy stops, faces the cat, waits for `alert_duration`. If the cat hides during this window, returns to PATROL without chasing. `detection_started` signal fires here (increases anger in `level_02.gd`). After the timer, transitions to CHASE.

**CHASE:** Enemy moves directly toward the cat's `global_position`. If the cat is hidden (`is_hidden == true`), immediately transitions to RETURN. Polls `CatchArea.get_overlapping_bodies()` every frame (see note below). After `lost_sight_delay` seconds without a line of sight, transitions to RETURN.

**RETURN:** Enemy moves toward the nearest patrol point. On arrival, resumes PATROL. Can re-enter ALERT if the cat comes into view.

#### Vision Detection (`_can_see_player`)

Checks three conditions in order:
1. Cat is not hidden (`is_hidden == false`)
2. Distance to cat ≤ `vision_range`
3. Angle to cat within `vision_angle * 0.5` of `facing` direction
4. No blocking geometry (raycast on layers 1 + 64) between enemy and cat

All four must pass for the enemy to "see" the cat.

#### Anger System

The level passes a `Callable` (`anger_getter`) to each enemy via `setup(player, anger_getter)`. The callable returns the current anger value (0–100). Higher anger:
- Increases patrol speed by up to 30% (`_patrol_speed_mult`)
- Scales chase speed from `chase_speed` up to `cat_max_speed * 1.25` (`_get_chase_speed`)
- Triggers run animation when anger ≥ 60%

#### Catch Polling Note

`body_entered` signals from `CatchArea` are edge-triggered and won't re-fire if the cat never left. To handle the cat staying inside the catch zone, `_tick_chase()` calls `_poll_catch_area()` every physics frame, which manually checks `get_overlapping_bodies()`.

#### Signal

| Signal               | When emitted                         |
|----------------------|--------------------------------------|
| `detection_started`  | On entering ALERT state              |

#### Key Methods

| Method                        | Purpose                                                         |
|-------------------------------|-----------------------------------------------------------------|
| `setup(player, anger_getter)` | Called by `level_02.gd` to inject player ref and anger source  |
| `disable()`                   | Stops physics processing; called by level at completion         |
| `_can_see_player()`           | Full four-condition vision check with raycast                   |
| `_tick_patrol/alert/chase/return` | Per-state logic called each `_physics_process`             |

---

### 7.5 `dog.gd`

**Class:** `Dog` | **Extends:** `EnemyBase`

Overrides: `patrol_speed = 95.0`. Uses `EnemyBase` defaults for `vision_range = 180` and `vision_angle = 55`.

---

### 7.6 `human.gd`

**Class:** `Human` | **Extends:** `EnemyBase`

Overrides: `patrol_speed = 95.0`, `vision_range = 240.0`, `vision_angle = 55.0`.  
Also overrides `_sync_run_animation()` with an empty pass — humans always use the walk animation regardless of anger or speed.

---

### 7.7 `dog_animator.gd`

**Extends:** `AnimatedSprite2D`  
**Attached to:** `Visual` in `dog.tscn`

Expected animation names: `Walk`, `Walk_chase`, `Run`, `Bark`. Sprites are left-facing by default; `flip_h = true` when moving right.

| Method                 | Called by      | Purpose                                              |
|------------------------|----------------|------------------------------------------------------|
| `update_direction(vel)`| `enemy_base.gd`| Flips sprite; calls `_refresh_anim()`                |
| `set_chasing(bool)`    | `enemy_base.gd`| Switches between patrol Walk and chase Walk_chase/Run|
| `set_force_run(bool)`  | `enemy_base.gd`| Forces Run when anger ≥ 60%                          |
| `set_barking(bool)`    | `enemy_base.gd`| Plays Bark on tag; returns to normal when done       |

---

### 7.8 `enemy_animator.gd`

**Extends:** `Node2D`  
**Attached to:** `Visual` in placeholder enemy variants

Placeholder that does nothing when `use_placeholder = true` (default). Exports same interface as `layered_character.gd` for compatibility. Set `use_placeholder = false` and add an `AnimatedSprite2D` child named `Sprite` to activate.

---

### 7.9 `layered_character.gd`

**Class:** `LayeredCharacter` | **Extends:** `Node2D`  
**Attached to:** `Visual` in `human.tscn`

Manages up to four stacked `AnimatedSprite2D` layers (Base, Outfit, Hair, Hat) that all play the same animation in sync, creating a composited character appearance.

#### Exports

| Variable          | Purpose                                                         |
|-------------------|-----------------------------------------------------------------|
| `outfit_variants` | Array of `SpriteFrames` resources for outfit options            |
| `hair_variants`   | Array of `SpriteFrames` for hair styles                         |
| `hat_variants`    | Array of `SpriteFrames` for hat options                         |
| `starting_outfit` | Index into `outfit_variants` to use on load                     |
| `starting_hair`   | Index into `hair_variants`                                      |
| `starting_hat`    | Index into `hat_variants`; -1 = no hat                          |
| `run_threshold`   | Speed (px/s) that auto-switches walk→run animations             |
| `idle_delay`      | Seconds of stillness before random idle plays                   |

**Required animation names on all SpriteFrames:** `walk_left`, `walk_right`, `run_left`, `run_right`. Run animations are optional — if missing, `_resolve_anim()` falls back to the walk equivalent automatically.

---

### 7.10 `character_appearance.gd`

**Class:** `CharacterAppearance` | **Extends:** `Resource`

A simple data resource with three fields: `outfit_index`, `hair_index`, `hat_index`. Save as a `.tres` file and call `LayeredCharacter.apply_appearance(resource)` to apply a preset. All human variant `.tres` files in `human_variants/` use this pattern.

---

### 7.11 `mouse.gd`

**Class:** `Mouse` | **Extends:** `CharacterBody2D`

#### Exports

| Variable          | Default | Purpose                                             |
|-------------------|---------|-----------------------------------------------------|
| `patrol_speed`    | 45.0    | Mouse movement speed                                |
| `patrol_route`    | `""`    | `NodePath` to a patrol route node                   |
| `patrol_ping_pong`| `true`  | Route direction behaviour                           |
| `point_value`     | 500     | Points awarded to the cat when this mouse is caught |

#### State

`can_be_caught: bool = true` — set to `false` inside `catch()` to prevent double-catching.

#### Key Method: `catch() -> int`

Called by `cat.gd._on_catch_area_body_entered()`. Sets `can_be_caught = false`, emits `mouse_caught_signal`, hides the node, and calls `queue_free()`. Returns `point_value`.

Signal: `mouse_caught_signal(points: int)`

Mouse is added to group `"mouse"` in `_ready()`.

---

### 7.12 `mouse_animator.gd`

**Extends:** `AnimatedSprite2D`  
**Attached to:** `Visual` in `mouse.tscn`

Plays animation `"walk"` on start. Flips `flip_h` based on horizontal velocity direction.

---

### 7.13 `hiding_spot.gd`

**Extends:** `Node2D`  
**Attached to:** `HidingSpot` root in `hiding_spot.tscn`

#### Exports

| Variable         | Default | Purpose                                                            |
|------------------|---------|--------------------------------------------------------------------|
| `alpha_hint`     | 0.6     | Opacity of the furniture when no one is hiding (visual hint)       |
| `alpha_hidden`   | 0.4     | Opacity when the cat is inside (cat visible through furniture)     |
| `fade_self_only` | `false` | If `true`, fades `self` instead of `get_parent()`                 |

#### How Fading Works

In `_ready()`, calls `_set_furniture_alpha(alpha_hint)`. This sets either `self.modulate.a` or `get_parent().modulate.a` depending on `fade_self_only`.

**Critical design rule:** `fade_self_only` must be `true` when the hiding spot is a direct child of a large container node. In `tutorial00.tscn`, `SofaHide` (placed directly under `seciton 1`) has `fade_self_only = true` to prevent the entire level section from dimming. Hiding spots correctly nested inside individual furniture nodes (e.g. `Rbed3/BedHide`) use the default `false` to dim only their parent furniture node.

When the cat enters `HideArea`, calls `cat.enter_hide_zone()`. On exit, calls `cat.leave_hide_zone()`.

---

### 7.14 `exit_door.gd`

**Class:** `ExitDoor` | **Extends:** `Area2D`  
**Group:** `"exit_door"`

| State      | `is_active` | Door colour | On player entry             |
|------------|-------------|-------------|-----------------------------|
| Locked     | `false`     | Red         | Emits `exit_attempted()`    |
| Unlocked   | `true`      | Green       | Emits `level_completed()`   |

`activate()` is called by `level_02.gd` when `_mice_caught >= required_mice`.  
A `_cooldown` timer (2.5 seconds) prevents the `exit_attempted` message from spamming.

---

### 7.15 `vision_cone.gd`

**Extends:** `Node2D`  
**Attached to:** `VisionCone` child in `dog.tscn` and `human.tscn`  
**Location (note):** Script is in `scripts/cat_game/environment/`, not `characters/`

A **visual-only** renderer for the enemy's field of view. Casts `ray_count` rays (default 36) across the cone angle and builds a filled polygon clipped by walls and `VisionBlocker` geometry (layer 64 only). Does **not** perform actual detection — that is handled entirely by `enemy_base.gd._can_see_player()`.

Reads `vision_range`, `vision_angle`, and `facing` from its parent node every frame, so Inspector changes are reflected live.

| Export       | Default            | Purpose                           |
|--------------|--------------------|-----------------------------------|
| `ray_count`  | 36                 | Ray density (higher = smoother)   |
| `fill_color` | Red 22% alpha      | Cone fill colour                  |
| `edge_color` | Red 55% alpha      | Cone edge line colour             |
| `edge_width` | 1.5                | Edge line thickness               |

---

### 7.16 `transition_trigger.gd`

**Extends:** `Node2D`  
**Attached to:** Black Sprite2D trigger nodes in `level_03.tscn` and `level_04.tscn`

Teleports the player between sections with a black screen fade. Creates a runtime `Area2D` in `_ready()` sized to the host Sprite2D's texture. On player entry, fades to black (0.25s), moves the cat, fades back (0.25s).

#### Export

| Variable      | Type       | Purpose                                                         |
|---------------|------------|-----------------------------------------------------------------|
| `destination` | `NodePath` | Points to the destination Sprite2D node (spawn point)          |

#### Known Issue

Most NodePaths in `level_03.tscn` resolve to `null` at runtime (paths go three levels up to the scene root then back down). The working path is the one to `section2/transition node/hidden area from section1`. Investigation required — likely a path format or scene tree structure issue. Debug print statements remain in the script.

---

### 7.17 `cactus_hazard.gd`

**Extends:** `Area2D`

A simple instant-catch hazard. On body entry, checks if the body is in group `"player"` and has `trigger_caught()`; calls it if so. Used extensively in `level_02.tscn` as environmental hazard zones.

---

### 7.18 `level_02.gd`

**Extends:** `Node2D`  
**Used by:** `level_01.tscn` through `level_04.tscn` (and `tutorial00.tscn`)  

The central level controller. Manages scoring, mouse tracking, enemy setup, HUD updates, and level completion.

#### Exports

| Variable                  | Default | Purpose                                                   |
|---------------------------|---------|-----------------------------------------------------------|
| `required_mice`           | 2       | Mice needed to unlock the exit                            |
| `starting_score`          | 1000    | Initial score for this level (set to 0 in all scenes)     |
| `points_per_mouse`        | 500     | Points added per mouse caught (at level end calculation)  |
| `caught_penalty`          | 300     | Points deducted per catch by enemy                        |
| `maximum_time_bonus`      | 3000    | Max time bonus if level is completed within optimal time  |
| `optimal_time_seconds`    | 60.0    | Time threshold for full time bonus                        |
| `time_penalty_per_second` | 20.0    | Points lost per second beyond `optimal_time_seconds`      |
| `anger_per_detection`     | 20.0    | Anger added each time an enemy detects the cat            |
| `total_mice`              | 3       | Total mice in the level (for HUD display)                 |
| `next_scene_path`         | `""`    | Path to load on results screen "Next" press               |

#### Runtime State

| Variable        | Purpose                                  |
|-----------------|------------------------------------------|
| `_elapsed_time` | Time in seconds since level start        |
| `_current_score`| Running score for this level             |
| `_mice_caught`  | How many mice caught so far              |
| `_times_caught` | How many times the cat was caught        |
| `_anger`        | Current anger value (0–100)              |
| `_level_active` | `false` after level completion           |

#### Key Signal Connections (made in `_ready`)

| Signal source                     | Signal                | Handler                    |
|-----------------------------------|-----------------------|----------------------------|
| `_cat`                            | `mouse_caught`        | `_on_mouse_caught`         |
| `_cat`                            | `player_caught`       | `_on_player_caught`        |
| Each exit door (group)            | `exit_attempted`      | `_on_exit_attempted`       |
| Each exit door (group)            | `level_completed`     | `_on_level_completed`      |
| Each enemy (group)                | `detection_started`   | `_on_detection_started`    |
| Each enemy's `CatchArea`          | `body_entered`        | `_on_catch_area_body_entered` |

#### Score Calculation at Level End

```
time_bonus      = max(0, maximum_time_bonus - int(overtime * time_penalty_per_second))
mouse_points    = _mice_caught * points_per_mouse
caught_deductions = _times_caught * caught_penalty
level_total     = time_bonus + mouse_points - caught_deductions
GameState.add_score(level_total)
```

Results are then passed to `ResultsScreen.show_results(...)`.

---

### 7.19 `hud.gd`

**Class:** `HUD` | **Extends:** `CanvasLayer`

Updates the in-level HUD. Called by `level_02.gd` every frame and on score/state changes.

| Method                                             | Purpose                                                   |
|----------------------------------------------------|-----------------------------------------------------------|
| `update_mouse_count(caught, required)`             | Updates mice label text                                   |
| `update_time(elapsed)`                             | Formats and updates time label                            |
| `update_anger(value)`                              | Updates `AngerBar` and swaps anger face stage (0/1/2)     |
| `set_level_mice(count)`                            | Sets the InfoLine text with total mice + global score     |
| `show_message(text, color, size, duration, shake)` | Shows a timed floating message; optional shake effect     |
| `update_score(_v)`                                 | **Empty (pass)** — score display not yet implemented      |
| `update_caught_count(_v)`                          | **Empty (pass)** — caught counter display not implemented |

Anger stage thresholds: stage 0 = value < 33, stage 1 = 33–65, stage 2 = 66+. Three face textures loaded from `assets/ui/Loot/stage1.png`, `stage2.png`, `stage3.png`.

---

### 7.20 `results_screen.gd`

**Class:** `ResultsScreen` | **Extends:** `CanvasLayer`

Displayed at the end of each level over the paused game. `process_mode = PROCESS_MODE_ALWAYS` so the Next button works even if the scene tree is paused.

`show_results(...)` is called with all breakdown values. Picks a random congratulations message from the `MESSAGES` constant array. The "Next" button (or Enter key) calls `get_tree().change_scene_to_file(next_path)` or `reload_current_scene()` if path is empty.

---

### 7.21 `end_screen.gd`

**Class:** `EndScreen` | **Extends:** `Control`

Reads `GameState.total_score` and performs a slot-machine digit animation:
1. All digits show random numbers simultaneously (22 shuffle steps)
2. Digits are revealed left-to-right with decreasing spin counts per digit
3. Each revealed digit turns gold; remaining digits keep shuffling
4. After all revealed, `_apply_color()` sets the final colour based on score

#### Score colour thresholds

| Score range    | Colour  |
|----------------|---------|
| ≥ 10,000       | Rainbow (cycling HSV) |
| < 10,000       | Red     |

> **Known bug:** The thresholds for Green (≥ 15,000), Yellow (≥ 13,000), and Orange (≥ 11,000) are **dead code** — any score ≥ 10,000 triggers the `_rainbow_active = true; return` early exit before those checks are reached. Green/Yellow/Orange will never display.

`BracketLabel` is a placeholder `Label` node in the scene that currently shows no meaningful content (not populated by the script).

---

### 7.22 `shadow.gd`

**Extends:** `Node2D`  
**Attached to:** `Shadow` child in cat, dog, human, mouse scenes

Draws a semi-transparent dark ellipse using `draw_colored_polygon` in `_draw()`. No physics, no interaction — purely cosmetic.

| Export         | Default           | Purpose                         |
|----------------|-------------------|---------------------------------|
| `radius_x`     | 12.0              | Horizontal radius of ellipse    |
| `radius_y`     | 5.0               | Vertical radius of ellipse      |
| `shadow_color` | Black 28% alpha   | Shadow fill colour              |

---

## 8. Core Systems Deep Dive

### 8.1 Player Movement

`cat.gd._apply_movement()` is called every `_physics_process`. It:
1. Reads a normalised 2D input vector via `Input.get_vector()` with WASD
2. Clamps diagonal movement to unit length (preserves analogue stick partial magnitudes via `length_squared > 1.0`)
3. Multiplies by `maximum_speed * caught_speed_multiplier` if boosted
4. Uses `velocity.move_toward(target, _accel * delta)` for smooth acceleration
5. Uses `velocity.move_toward(ZERO, _decel * delta)` for smooth deceleration when no input
6. Calls `_visual.update_direction(velocity)` to drive the animator
7. Calls `move_and_slide()` to apply physics and handle wall collision

When `_input_enabled = false` (set by `disable_input()` at level end), only deceleration runs.

### 8.2 Enemy AI State Machine

The enemy spends most of its time in PATROL, walking a ping-pong route between `Marker2D` waypoints. Every frame it checks `_can_see_player()`. On detection:

```
PATROL
  ↓ sees cat
ALERT (alert_duration = 0.3s)
  ↓ timer ends (and cat still visible)
CHASE
  ↓ cat hides OR lost_sight_delay (2s) with no LOS
RETURN
  ↓ reaches nearest patrol point
PATROL
```

If the cat hides during ALERT, the enemy drops back to PATROL immediately without chasing.

### 8.3 Hiding System

`hiding_spot.gd` creates a hide zone via `HideArea` (Area2D, layer 32, mask 2). When the cat enters:
- `hiding_spot.gd` calls `cat.enter_hide_zone()` → increments `hide_zone_count` → at count 1, `is_hidden = true`, cat visual goes to 35% alpha
- Enemy `_can_see_player()` returns `false` immediately (`if _player.is_hidden: return false`)
- If in CHASE state, enemy immediately transitions to RETURN
- `VisionBlocker` (StaticBody2D, layer 64) blocks the enemy's vision raycast so the vision cone is cut off at the furniture edge

When the cat exits: `leave_hide_zone()` decrements `hide_zone_count`; at 0 cat becomes visible again. The counter prevents flicker when transitioning between two adjacent hiding spots.

### 8.4 Mouse Catching

The cat has a `MouseCatchArea` (Area2D, mask=8). When this area overlaps a Mouse (layer 8):
- `cat.gd._on_catch_area_body_entered()` is called
- Checks `body.is_in_group("mouse")` and `mouse_node.can_be_caught`
- Calls `mouse_node.catch()` → mouse hides itself, schedules `queue_free()`, returns `point_value`
- Cat emits `mouse_caught(pts)` → `level_02.gd._on_mouse_caught()` updates the HUD and checks if exit should unlock

### 8.5 Scoring System

Scores flow through two systems:

**Within a level (live tracking):**
- `_current_score` in `level_02.gd` starts at `starting_score` (0 in all current levels)
- Each catch by enemy: `_current_score -= caught_penalty` (300)
- Live score updates passed to HUD via `_hud.update_score()`

**At level completion:**
- Mouse points: `_mice_caught × points_per_mouse`
- Time bonus: `max(0, maximum_time_bonus - overtime_seconds × time_penalty_per_second)`
- Caught deductions: `_times_caught × caught_penalty`
- `level_total = time_bonus + mouse_points - caught_deductions`
- `GameState.add_score(level_total)` persists it globally

### 8.6 Anger System

`_anger` in `level_02.gd` starts at 0 and increases by `anger_per_detection` (20.0) each time any enemy fires `detection_started`. Capped at 100.

This value is passed to every enemy as a `Callable` (`func() -> float: return _anger`). Enemies call it via `_anger_norm()` (returns 0–1 range) to scale their patrol speed and chase speed.

At anger ≥ 60% (`_anger_norm() >= 0.6`), `_sync_run_animation()` forces the run animation on dogs. Humans override this method to do nothing (always walk).

### 8.7 Level Completion Flow

1. Cat catches enough mice → `level_02.gd._on_mouse_caught()` calls `door.activate()` on all exit doors
2. Cat enters the exit door → `ExitDoor` emits `level_completed()`
3. `level_02.gd._on_level_completed()`:
   - Sets `_level_active = false`
   - Calls `_cat.disable_input()`
   - Calls `enemy.disable()` on all enemies
   - Calculates final score and calls `GameState.add_score(level_total)`
   - Calls `_results.show_results(...)` to display the results panel
4. Player presses Next (or Enter) → `results_screen.gd._on_next_pressed()` loads `next_scene_path`

### 8.8 Transition System (Level 3 & 4)

Black Sprite2D nodes named "transition node" exist in `level_03.tscn` and `level_04.tscn`. `transition_trigger.gd` is attached to these. At runtime, a rectangular `Area2D` is created matching the sprite's texture size. When the cat steps on it, a `CanvasLayer` (layer=100) with a black `ColorRect` fades in over 0.25s, the cat's `global_position` is set to the destination node's position, then the overlay fades out.

**Current status:** Partially working. The section1→section2 path works. Most other NodePaths return null. See Section 11 for details.

---

## 9. Level Flow: Start to Finish

```
Game Launch
    ↓
main.tscn loaded (Project Main Scene)
    ↓
level_00.tscn instanced (placeholder)
    ↓
[Player catches required_mice mice]
    ↓
Exit door activates (turns green)
    ↓
[Player reaches exit door]
    ↓
level_02.gd: level_completed → score calculated → GameState updated
    ↓
ResultsScreen shown → player presses Next
    ↓
level_01.tscn loaded
    ↓  (same flow per level)
level_02.tscn → level_03.tscn → level_04.tscn
    ↓
end_screen.tscn loaded
    ↓
GameState.total_score displayed with slot-machine animation
    ↓
[No restart flow implemented — game ends here]
```

---

## 10. Scene and Script Communication

### How `level_02.gd` connects everything

```
level_02.gd
  ├── @onready _cat: Cat = $Cat
  ├── _hud:     HUD     = get_node_or_null("HUD")
  ├── _results: ResultsScreen = get_node_or_null("ResultsScreen")
  │
  ├── _cat.mouse_caught   → _on_mouse_caught()
  ├── _cat.player_caught  → _on_player_caught()
  │
  ├── get_tree().get_nodes_in_group("exit_door") → each ExitDoor
  │     ├── exit_attempted  → _on_exit_attempted()
  │     └── level_completed → _on_level_completed()
  │
  └── get_tree().get_nodes_in_group("enemy") → each EnemyBase
        ├── enemy.setup(_cat, anger_callable)
        ├── detection_started → _on_detection_started()
        └── CatchArea.body_entered → _on_catch_area_body_entered()
```

### Groups used

| Group name    | Members              | Used for                                            |
|---------------|----------------------|-----------------------------------------------------|
| `"player"`    | `Cat`                | Enemy vision checks, exit door detection, hazards   |
| `"enemy"`     | `Dog`, `Human`       | Level setup, mass disable, anger subscription       |
| `"mouse"`     | `Mouse`              | Cat catch area detection                            |
| `"exit_door"` | `ExitDoor`           | Level script finds all doors to activate/connect    |

### Key cross-script calls

| Caller                  | Callee method                        | Purpose                               |
|-------------------------|--------------------------------------|---------------------------------------|
| `level_02.gd`           | `enemy.setup(cat, callable)`         | Inject dependencies into enemy AI     |
| `level_02.gd`           | `door.activate()`                    | Unlock exit doors                     |
| `level_02.gd`           | `_cat.disable_input()`               | Stop player on level end              |
| `level_02.gd`           | `enemy.disable()`                    | Freeze enemies on level end           |
| `level_02.gd`           | `_results.show_results(...)`         | Show end-of-level panel               |
| `hiding_spot.gd`        | `cat.enter_hide_zone()`              | Tell cat it's hidden                  |
| `hiding_spot.gd`        | `cat.leave_hide_zone()`              | Tell cat it's visible again           |
| `cat.gd`                | `mouse_node.catch()`                 | Remove mouse, get point value         |
| `cat.gd`                | `_visual.update_direction(velocity)` | Drive cat animation                   |
| `enemy_base.gd`         | `_player.trigger_caught()`           | Tag the cat                           |
| `enemy_base.gd`         | `_player.is_hidden`                  | Check hiding state                    |
| `results_screen.gd`     | `get_tree().change_scene_to_file()`  | Load next level                       |

---

## 11. Known Issues and Unfinished Features

### 11.1 `tutorial00.tscn` Not in Main Scene Chain

`main.tscn` instances `level_00.tscn`, not `tutorial00.tscn`. The art tutorial level is not reachable through normal gameplay. To add it, update `main.tscn` to instance `tutorial00.tscn`, or set `level_00`'s `next_scene_path` to point to `tutorial00.tscn`.

### 11.2 `level_00.tscn` Has No Next Scene

The embedded script in `level_00.tscn` has `next_scene_path = ""`. After completing this level, `ResultsScreen` calls `reload_current_scene()`. It does not progress to `level_01`.

### 11.3 Transition NodePaths Broken in `level_03.tscn`

`transition_trigger.gd` uses `NodePath` exports to find destination nodes. Most resolve to `null` at runtime. Only the `section1 → section2` transition works. Cause: the relative paths navigate to the scene root (via `../../../`) and then back into another section. The exact node names or depth levels appear to mismatch in most paths. Debug prints remain in the script.

**Suggested fix:** Switch from `NodePath` to `@export var destination: Node2D` (direct node reference) so Godot resolves the path at import time, not runtime.

### 11.4 `end_screen.gd` — Colour Thresholds are Dead Code

The `_apply_color()` function checks `if _total >= 10000` first and returns early with `_rainbow_active = true`. The subsequent checks for Green (≥ 15,000), Yellow (≥ 13,000), and Orange (≥ 11,000) are never reached. The effective behaviour is: score < 10,000 = Red, score ≥ 10,000 = Rainbow.

**Fix:** Move the rainbow check to the end, or raise the rainbow threshold above 15,000.

### 11.5 `HUD.update_score()` and `HUD.update_caught_count()` Are Empty

Both methods contain only `pass`. Score and caught count are not displayed in the HUD during gameplay (only the time and mice count update live). Completing these would require adding Label nodes to `hud.tscn`.

### 11.6 `NavigationAgent2D` in `dog.tscn` Is Unused

A `NavigationAgent2D` node exists in `dog.tscn` but `enemy_base.gd` moves enemies using direct `velocity` toward target positions, not nav-mesh navigation. It can be safely removed, or nav-mesh movement could replace the direct approach for better obstacle avoidance.

### 11.7 `level_01.gd` Exists But Is Unused

The file `scripts/cat_game/levels/level_02.gd` is the active level script. A `level_01.gd` filename was referenced in documentation but does not contain the active code. All levels 01–04 use `level_02.gd`.

### 11.8 `GameState.reset()` Is Never Called

There is no "return to start" or "new game" flow. `total_score` never resets during a play session. If the game is restarted from the OS, it resets automatically since the autoload re-initialises.

### 11.9 `seciton 1` Typo in `tutorial00.tscn`

The section node is named `seciton 1` (typo). Any NodePath references to this node must use the misspelled name. Renaming it in Godot will update internal paths but may break any hardcoded NodePath strings.

### 11.10 `BracketLabel` on End Screen Is Placeholder

`end_screen.tscn` contains a `BracketLabel` label with placeholder text ("You have placed — in your bracket"). `end_screen.gd` does not populate this label. It is an unimplemented feature.

### 11.11 `transition_trigger.gd` Contains Debug Prints

Numerous `print()` statements remain in `transition_trigger.gd` from debugging. These should be removed before release.

### 11.12 `solid_furniture.tscn` Purpose Unclear

This scene file exists but was not found used in any level scene during this audit. It is likely a utility collision block for furniture in the art levels.

---

## 12. Extension and Modification Guide

### Adding a New Level

1. Duplicate an existing level scene (e.g. `level_03.tscn`)
2. Update the exported values on the root node in the Inspector: `required_mice`, `total_mice`, `next_scene_path`
3. Update the previous level's `next_scene_path` to point to the new level
4. Place enemies: instance `dog.tscn` or `human.tscn`, set `patrol_route` to a patrol route node
5. Place mice: instance `mouse.tscn`, set `patrol_route`
6. Call `enemy.setup()` is handled automatically by `level_02.gd` at `_ready()` — no manual connection needed
7. Place hiding spots: instance `hiding_spot.tscn`; adjust `HideCollision` and `VisionCollision` shapes to match furniture
8. Place exit door: instance `exit_door.tscn` — the level script connects its signals automatically via the `"exit_door"` group

### Adding a New Enemy Type

1. Create a new script that `extends EnemyBase`
2. Override `patrol_speed`, `vision_range`, `vision_angle` in `_ready()` before calling `super._ready()`
3. Override `_sync_run_animation()` if the enemy should not switch to run animation
4. Create a scene with a `CharacterBody2D` root (collision_layer=4), add `BodyCollision`, `CatchArea` (mask=2), `VisionCone`, `AlertIcon`, `Visual`, `Shadow` children
5. No changes to `level_02.gd` needed — it uses the `"enemy"` group to find all enemies

### Adding a New Hiding Spot

1. Instance `hiding_spot.tscn` as a child of the furniture sprite you want to be hideable
2. Resize `HideCollision` to cover the hiding area
3. Resize `VisionCollision` to cover what the furniture should block visually
4. If the hiding spot is a direct child of a large container node (not a specific furniture node), set `fade_self_only = true` in the Inspector
5. Adjust `alpha_hint` and `alpha_hidden` as desired

### Changing the Cat's Visual

The `Visual` node in `cat.tscn` is an `AnimatedSprite2D` with `cat_animator.gd`. To update animations:
1. Replace the `SpriteFrames` resource on `Visual` with one that includes: `walk_left`, `walk_right`, `run_left`, `run_right`, `idle1`, `idle2`
2. Update `ANIM_OFFSETS` in `cat_animator.gd` if the new sprite anchor differs per animation

### Adding Human Appearance Variants

1. Create a new `SpriteFrames` resource with animations: `walk_left`, `walk_right`, `run_left`, `run_right`
2. Add it to `LayeredCharacter.outfit_variants` (or `hair_variants` / `hat_variants`) on the `Visual` node in the Inspector
3. Or create a `.tres` file of type `CharacterAppearance` and call `apply_appearance()` at runtime

### Fixing the End Screen Colour Bug

In `end_screen.gd`, reorder `_apply_color()`:

```gdscript
func _apply_color() -> void:
	var score_color: Color
	if _total >= 15000:
		score_color = _GREEN
	elif _total >= 13000:
		score_color = _YELLOW
	elif _total >= 11000:
		score_color = _ORANGE
	elif _total >= 10000:
		_rainbow_active = true
		return
	else:
		score_color = _RED
	for label in _digit_labels:
		label.add_theme_color_override("font_color", score_color)
```

### Fixing Transition NodePaths

In `transition_trigger.gd`, change the export from:
```gdscript
@export var destination: NodePath = NodePath("")
```
to:
```gdscript
@export var destination: Node2D
```

Then in `_on_body_entered()`, use `destination` directly instead of `get_node_or_null(destination)`. Reassign the destination references in the Inspector.

---

## 13. Troubleshooting

### Enemy does not detect the player

- Check that the cat is in group `"player"` (`cat.gd._ready()` adds it — confirm `cat.gd` is attached)
- Check `vision_range` and `vision_angle` on the enemy in the Inspector
- Verify the cat is not inside a hiding spot (`is_hidden = true`)
- Ensure no extra `VisionBlocker` geometry (layer 64) is sitting between the enemy and cat

### Enemy detects player through walls

- Walls must be on collision layer 64 (VisionBlocker) as well as layer 1. Check `wall_segment.tscn` has `collision_layer = 65`.
- The vision raycast checks `(1 << 6) | (1 << 0)` = 65. Any wall with only layer 1 (value=1) will not block vision.

### Cat does not hide when entering hiding spot

- Confirm `hiding_spot.gd` is attached to the `HidingSpot` root node
- Check `HideArea.collision_mask = 2` (player layer) and `Cat.collision_layer = 2`
- Check that `HideCollision` shape is sized correctly and the cat can physically overlap it

### Exit door does not activate

- Check `_mice_caught >= required_mice` condition — verify `required_mice` is set correctly in the Inspector
- Check the exit door is in group `"exit_door"` (added by `exit_door.gd._ready()`)
- Check that signal connections were made in `level_02.gd._ready()`

### Transition teleport does nothing / prints null destination

- `destination` NodePath is resolving to null at runtime
- Open the scene in Godot, select the trigger sprite, and check the `Destination` export in the Inspector
- The path format `../../../section3/...` requires exactly 3 parent levels to reach the scene root; count the actual node depth

### Score not saving between levels

- `GameState` must be registered as autoload. Check `project.godot` → `[autoload]` contains the line
- `GameState.add_score()` is called inside `_on_level_completed()` — verify the level's `level_completed` signal fires (door must be active AND cat must enter it)

### `HUD` or `ResultsScreen` shows as null

- `level_02.gd` uses `get_node_or_null("HUD")` and `get_node_or_null("ResultsScreen")` — the nodes must be direct children of the level root node with exactly those names
- If using a different name, update the path in `level_02.gd._ready()`

### Everything in a level appears darker than expected

- A `hiding_spot.gd` instance is likely a direct child of a large container node
- Find which `HidingSpot` node has `get_parent()` pointing to a section/map-level node
- Set `fade_self_only = true` on that specific instance in the Inspector

---

## 14. Summary for New Developers

Cat Game is a Godot 4.7 top-down 2D stealth game where the player is a cat catching mice while avoiding dog and human enemies. Here are the essential things to understand:

**The entry point** is `main.tscn` → `level_00.tscn`. The game progresses through level_01 → level_02 → level_03 → level_04 → end_screen, controlled by `next_scene_path` exports on each level's root node.

**The level controller** is `level_02.gd`, shared by all four real levels. It manages scoring, mouse tracking, enemy wiring, HUD updates, and level completion. It finds everything via groups (`"enemy"`, `"exit_door"`) and direct node references (`$Cat`, `$HUD`, `$ResultsScreen`).

**All enemies** extend `EnemyBase` which implements a PATROL → ALERT → CHASE → RETURN state machine. Vision is raycast-based. The cat is invisible to enemies when `is_hidden = true`, set by entering any `HidingSpot` node.

**Score accumulates globally** via the `GameState` autoload singleton. Each level adds its calculated `level_total` to `GameState.total_score`. The end screen reads this and displays it.

**Most art is placeholder.** Walls are `ColorRect` nodes, the cat's visual is an actual `AnimatedSprite2D`, dogs have real sprites, but most environment geometry is still coloured rectangles. `tutorial00.tscn` is the only fully art-based level but is not connected to the main game flow yet.

**The three things most likely to need work** before a proper release are: connecting `tutorial00.tscn` to the level chain, fixing the transition NodePath bug in levels 3 and 4, and fixing the dead colour thresholds in `end_screen.gd`.
