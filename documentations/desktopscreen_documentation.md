# Desktop Screen Documentation

## Overview

The `DesktopScreen` serves as the primary home interface for the in-game Laptop UI. Designed with a sleek, futuristic, and "alive" holographic aesthetic, it acts as a central hub where players can access various app modules (e.g., Messenger, Minigames) via interactive app buttons. 

The screen is built to be highly dynamic, featuring 3D parallax effects, cascading entrance choreography, ambient particle systems, an interactive cursor light, and a robust global color theming engine.

---

## Core Components

### 1. `DesktopScreen` (Main Scene)
**Path**: `res://scenes/ui/DesktopScreen.tscn`
**Script**: `res://scripts/ui/DesktopScreen.gd`

The root node is a `Control` that manages the overall layout, background effects, and global state (like the current color theme). 

**Key Features:**
- **Layout**: Divided into a `HeaderSection` (dynamic tagline), an `AppGrid` (container for app buttons), and a `BottomBar` (real-time clock and status text).
- **Entrance Choreography**: When initialized, `_play_entrance_animation()` fires, orchestrated via `Tween`s. The background fades in, header/footer slide into place, and the app buttons scale up in a staggered cascade.
- **Parallax & Cursor Lighting**: In `_process()`, the script tracks mouse movement relative to the screen center. It lerps the position of the `Background` and `AppGrid` in opposite directions to create a 3D depth effect. Simultaneously, a `Sprite2D` (`MouseGlow`) using a radial `GradientTexture2D` follows the mouse, casting a soft additive glow over the background.
- **Ambient Particles**: A `CPUParticles2D` node (`DataParticles`) constantly emits faint, slow-moving squares upward, simulating data streams and ensuring the screen never feels entirely static.
- **Real-time Clock**: A `Timer` triggers `_update_clock()` every second, fetching system time and updating the `Clock` label in the bottom bar.

### 2. `DesktopAppButton` (Modular Button)
**Path**: `res://scenes/ui/DesktopAppButton.tscn`
**Script**: `res://scripts/ui/DesktopAppButton.gd`

A reusable, interactive tile representing an app or module.

**Exported Variables:**
- `app_name` (String): The display name of the app.
- `target_scene` (String): The `.tscn` path to the scene that should open when clicked.
- `icon_texture` (Texture2D): The app's visual icon.
- `color_preset` (String): The global theme preset to apply when hovered.
- `hover_sound_stream` / `click_sound_stream` (AudioStream): Custom audio cues.

**Key Features:**
- **Hover & Press Tweens**: Smoothly scales up on hover, scales down on press, and triggers an elastic bounce upon release.
- **Traveling Border Shader**: Uses a custom GDShader (`res://assets/shaders/traveling_border.gdshader`) applied to a `BorderGlow` rect. The shader calculates a signed distance field to draw a perfectly crisp rounded border, and uses `atan` combined with `TIME` to animate a glowing "snake" tail that continuously travels around the perimeter. Hovering tweens the shader's `hover_intensity` parameter.
- **Dynamic Notification Badge**: A built-in badge system (a red '!' with an expanding, fading ripple animation). It includes hardcoded logic to dynamically check if the app is named "MESSENGER" and if `CutsceneMessenger` has unread messages, automatically toggling the badge visibility and animations.

---

## Global Color Theme System

The `DesktopScreen` features a powerful, modular theming engine that seamlessly shifts the color palette of the entire UI based on user interaction. 

### How it Works
1. **The Dictionary**: `DesktopScreen.gd` houses a `color_presets` dictionary. Each key (e.g., `"default"`, `"crimson"`, `"emerald"`) maps to a dictionary of 9 specific color targets covering everything from text labels to background modulation, particle colors, and button glow parameters.
2. **The Transition**: The `apply_theme(preset, animation_time)` function uses a single parallel `Tween`. It dynamically interpolates the current color of all 9 targets towards the new preset's values over the specified `animation_time`.
3. **The Trigger**: When a `DesktopAppButton` is hovered, it emits the `app_hovered(app_name, color_preset)` signal. The `DesktopScreen` catches this, updates the header tagline to `"◇ SELECTED: [APP]"`, and calls `apply_theme` with the button's requested preset. Moving the mouse away reverts to the `"default"` preset.

### Color Targets
The system transitions the following properties simultaneously:
1. `tagline_color`: Top-left header text.
2. `clock_color`: Bottom-left time text.
3. `status_color`: Bottom-right available modules text.
4. `background_modulate`: The base tint of the parallax wallpaper.
5. `mouse_glow_color`: The center color stop of the cursor light gradient.
6. `particle_color`: The tint of the floating data particles.
7. `border_glow_color`: The base color sent to the traveling border shader.
8. `button_bg_glow_color`: The inner hover glow color of the buttons.
9. `app_name_color`: The font color of the app names.

---

## How to Add a New App Module

1. Open `DesktopScreen.tscn`.
2. Locate the `AppGrid` (GridContainer) node.
3. Instantiate a new child scene (`Ctrl+Shift+A` or the chainlink icon) and select `DesktopAppButton.tscn`.
4. With the new button selected, go to the Inspector.
5. Set the **App Name**, select an **Icon Texture**, and assign the **Target Scene** path.
6. (Optional) Assign a **Color Preset** (e.g., `"crimson"`, `"emerald"`, or define a new one in `DesktopScreen.gd`) and drop in audio streams for hover/click.
7. The `DesktopScreen` script automatically connects signals for all children of `AppGrid` in `_ready()`, so no additional code wiring is required.
