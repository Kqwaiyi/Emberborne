extends Node

# ─── Ending score thresholds — edit here or in the Inspector ─────────────────
@export_category("Ending Point Requirements")
@export var ending_1_min_points : int = 0
@export var ending_2_min_points : int = 10000
@export var ending_3_min_points : int = 15000

# ─── Timing — edit here or in the Inspector ──────────────────────────────────
@export_category("Timing")
@export var image_fade_in  : float = 1.2
@export var image_hold     : float = 4.0
@export var image_hold_final : float = 5.5   # longer hold for last image
@export var image_fade_out : float = 1.0
@export var title_hold     : float = 2.5
@export var thanks_fade_in : float = 1.2
@export var text_speed     : float = 0.028   # seconds per character (narration)
@export var slow_speed     : float = 0.040   # seconds per character (emotional)

# ─── Audio — assign AudioStreams in the Inspector ────────────────────────────
@export_category("Audio")
@export var music_ending_1 : AudioStream   # bleak / bittersweet
@export var music_ending_2 : AudioStream   # restrained / hopeful
@export var music_ending_3 : AudioStream   # warm / triumphant

# ─── Return scene — change if your hub scene moves ───────────────────────────
@export_category("Scene")
@export var return_scene_path : String = "res://scenes/scifi_home/the_home/map.tscn"

# ─── Debug — set to 1, 2, or 3 to force a specific ending; 0 = use score ─────
@export_category("Debug")
@export_range(0, 3) var debug_force_ending : int = 0

# ─── Font paths ───────────────────────────────────────────────────────────────
const _F_BOLD := "res://assets/fonts/Chakra_Petch/ChakraPetch-Bold.ttf"
const _F_SB   := "res://assets/fonts/Chakra_Petch/ChakraPetch-SemiBold.ttf"
const _F_MED  := "res://assets/fonts/Chakra_Petch/ChakraPetch-Medium.ttf"
const _F_REG  := "res://assets/fonts/Chakra_Petch/ChakraPetch-Regular.ttf"
const _F_LT   := "res://assets/fonts/Chakra_Petch/ChakraPetch-Light.ttf"

# ─── Palette ──────────────────────────────────────────────────────────────────
const _BG_COL   := Color(0.012, 0.016, 0.020, 1.0)  # ~#030405
const _OFF_W    := Color(0.906, 0.914, 0.925, 1.0)  # ~#E7E9EC
const _BRIGHT_W := Color(1.000, 1.000, 1.000, 1.0)
# Accent colours — change here to restyle each ending
const _ACC_E1   := Color(0.769, 0.443, 0.478, 1.0)  # dusty rose
const _ACC_E2   := Color(0.376, 0.847, 0.937, 1.0)  # soft cyan
const _ACC_E3   := Color(0.831, 0.659, 0.278, 1.0)  # warm gold

# ─── Layout constants (1280 × 720 viewport) ───────────────────────────────────
const _TX_L  := 90.0    # left text margin
const _TW    := 860.0   # narration max width
const _TW_C  := 1280.0  # full-screen width (use for centred labels)
const _CX    := 0.0     # x origin for centred labels
const _TG    := 82.0    # vertical gap between stacked lines
const _TY_T  := 148.0   # top of text area (multi-line blocks)
const _TY_M  := 305.0   # near vertical centre (standalone impact lines)

# ─── Runtime ──────────────────────────────────────────────────────────────────
var _canvas    : CanvasLayer   # layer 1 — bg, image, story text
var _ui_canvas : CanvasLayer   # layer 10 — "PRESS SPACE" prompt
var _bg        : ColorRect
var _img       : Sprite2D
var _pool      : Array[Control] = []
var _advance_requested := false
var _already_running   := false

var _prompt    : Label
var _prompt_bg : ColorRect
var _prompt_ln : ColorRect
var _prompt_tw : Tween

var _music_player : AudioStreamPlayer

var _f_bold : FontFile
var _f_sb   : FontFile
var _f_med  : FontFile
var _f_reg  : FontFile
var _f_lt   : FontFile

# ═════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_validate_thresholds()
	_build_nodes()
	_load_fonts()
	_make_prompt()
	_run.call_deferred()

func _validate_thresholds() -> void:
	if ending_2_min_points <= ending_1_min_points or \
			ending_3_min_points <= ending_2_min_points:
		push_warning("EndingSequence: score thresholds are out of order — check @export values.")

func _load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	return null

func _load_fonts() -> void:
	_f_bold = _load_font(_F_BOLD)
	_f_sb   = _load_font(_F_SB)
	_f_med  = _load_font(_F_MED)
	_f_reg  = _load_font(_F_REG)
	_f_lt   = _load_font(_F_LT)

func _build_nodes() -> void:
	_canvas       = CanvasLayer.new()
	_canvas.layer = 1
	add_child(_canvas)

	_bg         = ColorRect.new()
	_bg.color   = _BG_COL
	_bg.size    = Vector2(1280.0, 720.0)
	_canvas.add_child(_bg)

	# Sprite2D: manually fit to screen — works correctly at any source resolution.
	_img            = Sprite2D.new()
	_img.position   = Vector2(640.0, 360.0)   # centre of 1280 × 720
	_img.centered   = true
	_img.modulate.a = 0.0
	_canvas.add_child(_img)

	_ui_canvas       = CanvasLayer.new()
	_ui_canvas.layer = 10
	add_child(_ui_canvas)

	_music_player     = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

# ─── Input ────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if _advance_requested:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance_requested = true
	elif event is InputEventMouseButton and event.pressed:
		if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_advance_requested = true

# ─── Prompt ───────────────────────────────────────────────────────────────────
func _make_prompt() -> void:
	_prompt_bg          = ColorRect.new()
	_prompt_bg.color    = Color(0.02, 0.04, 0.08, 0.55)
	_prompt_bg.position = Vector2(930.0, 656.0)
	_prompt_bg.size     = Vector2(330.0,  44.0)
	_ui_canvas.add_child(_prompt_bg)

	_prompt_ln          = ColorRect.new()
	_prompt_ln.color    = Color(0.376, 0.847, 0.937, 0.30)
	_prompt_ln.position = Vector2(930.0, 656.0)
	_prompt_ln.size     = Vector2(330.0,   1.0)
	_ui_canvas.add_child(_prompt_ln)

	_prompt          = Label.new()
	_prompt.text     = "  PRESS  SPACE  TO CONTINUE"
	_prompt.position = Vector2(934.0, 664.0)
	_prompt.size     = Vector2(322.0,  34.0)
	_prompt.add_theme_font_size_override("font_size", 15)
	_prompt.add_theme_color_override("font_color", _ACC_E2)
	if _f_lt:
		_prompt.add_theme_font_override("font", _f_lt)
	_ui_canvas.add_child(_prompt)

	_ui_canvas.visible = false

func _show_prompt() -> void:
	_ui_canvas.visible = true
	_prompt.modulate.a = 1.0
	if _prompt_tw:
		_prompt_tw.kill()
	_prompt_tw = create_tween().set_loops()
	_prompt_tw.tween_property(_prompt, "modulate:a", 1.0, 0.65)
	_prompt_tw.tween_property(_prompt, "modulate:a", 0.25, 0.65)

func _hide_prompt() -> void:
	if _prompt_tw:
		_prompt_tw.kill()
		_prompt_tw = null
	_ui_canvas.visible = false

# Waits for Space / Enter / click.  If already set from a skip, returns immediately.
func _continue() -> void:
	_show_prompt()
	while not _advance_requested:
		await get_tree().process_frame
	_advance_requested = false
	_hide_prompt()

# ═════════════════════════════════════════════════════════════════════════════
#  LABEL FACTORIES
# ═════════════════════════════════════════════════════════════════════════════
func _lbl(txt: String, sz: int, col: Color, pos: Vector2,
		  w: float = _TW,
		  align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		  font: FontFile = null) -> Label:
	var l := Label.new()
	l.text                  = txt
	l.position              = pos
	l.size                  = Vector2(w, 400.0)
	l.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment  = align
	l.visible_characters    = 0
	l.modulate.a            = 0.0
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	var f := font if font else _f_med
	if f:
		l.add_theme_font_override("font", f)
	_canvas.add_child(l)
	_pool.append(l)
	return l

func _rtl(txt: String, sz: int, col: Color, pos: Vector2,
		  w: float = _TW) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled         = true
	r.text                   = txt
	r.position               = pos
	r.size                   = Vector2(w, 400.0)
	r.scroll_active          = false
	r.visible_characters     = 0
	r.modulate.a             = 0.0
	r.add_theme_font_size_override("normal_font_size", sz)
	r.add_theme_font_size_override("bold_font_size",   sz)
	r.add_theme_color_override("default_color", col)
	if _f_med:  r.add_theme_font_override("normal_font", _f_med)
	if _f_bold: r.add_theme_font_override("bold_font",   _f_bold)
	_canvas.add_child(r)
	_pool.append(r)
	return r

# ═════════════════════════════════════════════════════════════════════════════
#  ANIMATION PRIMITIVES  (same contract as exposition.gd)
# ═════════════════════════════════════════════════════════════════════════════
func _set_chars(n: Control, count: int) -> void:
	if n is Label:           (n as Label).visible_characters         = count
	elif n is RichTextLabel: (n as RichTextLabel).visible_characters = count

func _get_total(n: Control) -> int:
	if n is Label:           return (n as Label).get_total_character_count()
	elif n is RichTextLabel: return (n as RichTextLabel).get_total_character_count()
	return 0

# Typewriter — skips instantly if Space was pressed; does NOT consume the flag.
func _type(n: Control, speed: float = 0.028) -> void:
	n.modulate.a = 1.0
	var total    := _get_total(n)
	if total <= 0:
		return
	_set_chars(n, 0)
	var t := create_tween()
	t.tween_property(n, "visible_characters", total, total * speed)
	while t.is_running():
		if _advance_requested:
			t.kill()
			_set_chars(n, total)
			return
		await get_tree().process_frame

func _appear(n: Control, dur: float = 0.25) -> void:
	var t := create_tween()
	t.tween_property(n, "modulate:a", 1.0, dur)
	await t.finished

# Like _appear() but reveals all characters first — use for labels that fade in
# without a following _type() call (title cards, thanks screen, etc.).
func _appear_full(n: Control, dur: float = 0.25) -> void:
	_set_chars(n, -1)
	var t := create_tween()
	t.tween_property(n, "modulate:a", 1.0, dur)
	await t.finished

func _dim(n: Control, alpha: float = 0.35, dur: float = 0.35) -> void:
	if not is_instance_valid(n): return
	create_tween().tween_property(n, "modulate:a", alpha, dur)

func _hold(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _clear(fade: float = 0.4, gap: float = 0.0) -> void:
	for n in _pool:
		if is_instance_valid(n) and n.modulate.a > 0.01:
			create_tween().tween_property(n, "modulate:a", 0.0, fade)
	if not _pool.is_empty():
		await _hold(fade)
	for n in _pool:
		if is_instance_valid(n):
			n.queue_free()
	_pool.clear()
	if gap > 0.0:
		await _hold(gap)

# ═════════════════════════════════════════════════════════════════════════════
#  IMAGE BEAT
# ═════════════════════════════════════════════════════════════════════════════
func _show_image(path: String, hold_override: float = -1.0, do_zoom: bool = true) -> void:
	var hold_time := hold_override if hold_override > 0.0 else image_hold

	if not ResourceLoader.exists(path):
		push_warning("EndingSequence: image not found — " + path)
		await _hold(hold_time)
		return

	var tex := load(path) as Texture2D
	if not tex:
		await _hold(hold_time)
		return

	_img.texture   = tex
	_img.modulate.a = 0.0

	# Scale image to fit entirely within 1280 × 720, centred, aspect-preserved.
	var img_size   := tex.get_size()
	var fit_scale  : float = min(1280.0 / img_size.x, 720.0 / img_size.y)
	_img.scale     = Vector2(fit_scale, fit_scale)

	# Subtle Ken Burns: scale grows by 3 % over the full visible duration.
	if do_zoom:
		var zoom_end  := Vector2(fit_scale * 1.03, fit_scale * 1.03)
		var total_dur := image_fade_in + hold_time + image_fade_out
		create_tween().tween_property(_img, "scale", zoom_end, total_dur)

	var tw := create_tween()
	tw.tween_property(_img, "modulate:a", 1.0, image_fade_in)
	await tw.finished

	# Skippable hold — show prompt and wait for either the timer or player input.
	_show_prompt()
	var start_ms : int = Time.get_ticks_msec()
	var hold_ms  : int = int(hold_time * 1000.0)
	while Time.get_ticks_msec() - start_ms < hold_ms and not _advance_requested:
		await get_tree().process_frame
	_advance_requested = false   # consume here so the next text page isn't skipped too
	_hide_prompt()

	tw = create_tween()
	tw.tween_property(_img, "modulate:a", 0.0, image_fade_out)
	await tw.finished

	_img.texture = null
	_img.scale   = Vector2.ONE
	await _hold(0.4)

# ═════════════════════════════════════════════════════════════════════════════
#  TITLE CARD
# ═════════════════════════════════════════════════════════════════════════════
func _show_title_card(number: String, title: String, accent: Color) -> void:
	var dim_accent := Color(accent.r, accent.g, accent.b, 0.5)

	var num_lbl := _lbl(number, 14, dim_accent,
						Vector2(_CX, 268.0), _TW_C,
						HORIZONTAL_ALIGNMENT_CENTER, _f_lt)
	await _appear_full(num_lbl, 0.5)
	await _hold(0.2)

	var title_lbl := _lbl(title, 52, accent,
						  Vector2(_CX, 308.0), _TW_C,
						  HORIZONTAL_ALIGNMENT_CENTER, _f_sb)
	await _appear_full(title_lbl, 0.8)
	await _hold(title_hold)
	await _clear(0.7)
	await _hold(0.3)

# ═════════════════════════════════════════════════════════════════════════════
#  THANKS SCREEN
# ═════════════════════════════════════════════════════════════════════════════
func _show_thanks(accent: Color) -> void:
	await _hold(0.5)

	var thanks := _lbl("THANKS FOR PLAYING", 44, _OFF_W,
						Vector2(_CX, 255.0), _TW_C,
						HORIZONTAL_ALIGNMENT_CENTER, _f_sb)
	await _appear_full(thanks, thanks_fade_in)

	var game := _lbl("EMBERBORNE", 17,
					 Color(accent.r, accent.g, accent.b, 0.55),
					 Vector2(_CX, 322.0), _TW_C,
					 HORIZONTAL_ALIGNMENT_CENTER, _f_lt)
	await _appear_full(game, 0.9)

	await _hold(1.0)

	var hint := _lbl("Press any key to continue", 13,
					 Color(_OFF_W.r, _OFF_W.g, _OFF_W.b, 0.38),
					 Vector2(_CX, 412.0), _TW_C,
					 HORIZONTAL_ALIGNMENT_CENTER, _f_lt)
	await _appear_full(hint, 0.6)

	await _continue()

# ─── Music helpers ────────────────────────────────────────────────────────────
func _start_music(stream: AudioStream) -> void:
	if not stream:
		return
	_music_player.stream    = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	create_tween().tween_property(_music_player, "volume_db", -14.0, 2.5)

func _fade_music(to_db: float = -80.0, dur: float = 2.0) -> void:
	if not _music_player.playing:
		return
	create_tween().tween_property(_music_player, "volume_db", to_db, dur)

# ═════════════════════════════════════════════════════════════════════════════
#  ENDING SELECTION
# ═════════════════════════════════════════════════════════════════════════════
func _determine_ending() -> int:
	if debug_force_ending in [1, 2, 3]:
		return debug_force_ending
	var score := GameState.total_score if GameState else 0
	if score >= ending_3_min_points:
		return 3
	elif score >= ending_2_min_points:
		return 2
	return 1

# ═════════════════════════════════════════════════════════════════════════════
#  MAIN RUNNER
# ═════════════════════════════════════════════════════════════════════════════
func _run() -> void:
	if _already_running:
		return
	_already_running = true

	if MusicManager:
		MusicManager.stop_music()
	await _hold(0.4)

	var ending := _determine_ending()

	match ending:
		1: await _run_ending_1()
		2: await _run_ending_2()
		3: await _run_ending_3()

	_fade_music(-80.0, 2.5)

	await _show_thanks(
		_ACC_E1 if ending == 1 else (_ACC_E2 if ending == 2 else _ACC_E3)
	)

	# Fade to black, then quit. Change return_scene_path in the Inspector
	# if you'd prefer to return to a hub scene instead of quitting.
	await _clear(0.6)
	await _hold(0.5)

	if return_scene_path != "":
		if SceneManager:
			SceneManager.change_scene_to_file(return_scene_path, 1.2)
		else:
			get_tree().change_scene_to_file(return_scene_path)
	else:
		get_tree().quit()

# ═════════════════════════════════════════════════════════════════════════════
#  ENDING 1 — LIFE CONTRACT  (dusty rose, bleak → bittersweet)
#  Images: ending 1.png  /  ending 1_2.png
#  Accent hex for BBCode: #C4717A
# ═════════════════════════════════════════════════════════════════════════════
func _run_ending_1() -> void:
	_start_music(music_ending_1)

	await _show_title_card("ENDING  01", "LIFE  CONTRACT", _ACC_E1)

	# ── First image ──
	await _show_image("res://assets/ending pictures/ending 1.png")

	# ── Page 1 — standalone impact ──
	var p1 := _rtl(
		"You did everything you could,\nbut it still [b]wasn't enough[/b].",
		34, _OFF_W, Vector2(_CX, _TY_M), _TW_C)
	p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await _type(p1, slow_speed)
	await _hold(1.8)
	await _continue()
	await _clear(0.45)

	# ── Page 2 — narration ──
	var p2 := _rtl(
		"The prize money fell short. With your mother's remaining time running out "
		+ "and the debt already breathing down your neck, there was only [b]one choice left:[/b]",
		28, _OFF_W, Vector2(_TX_L, _TY_T))
	await _type(p2, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 3 — short centred statement ──
	var p3 := _rtl(
		"Sign the [color=#C4717A]life contract[/color].",
		42, _OFF_W, Vector2(_CX, _TY_M - 20.0), _TW_C)
	p3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await _appear(p3, 0.18)
	await _type(p3, slow_speed)
	await _hold(1.2)
	await _continue()
	await _clear(0.5)

	# ── Page 4 — two-part reveal ──
	var p4a := _lbl("The surgery was paid for.", 28, _OFF_W,
					Vector2(_TX_L, 278.0))
	await _type(p4a, text_speed)
	await _hold(1.4)

	var p4b := _lbl("Your mother lived.", 36, _BRIGHT_W,
					Vector2(_TX_L, 368.0), _TW, HORIZONTAL_ALIGNMENT_LEFT, _f_sb)
	await _type(p4b, slow_speed)
	await _hold(2.0)
	await _continue()
	await _clear(0.45)

	# ── Page 5 — tonal reversal ──
	var p5 := _rtl(
		"But in exchange, your future [b]no longer belonged to you[/b].",
		30, _OFF_W, Vector2(_TX_L, _TY_M))
	await _type(p5, text_speed)
	await _hold(1.2)
	await _continue()
	await _clear(0.4)

	# ── Page 6 — narration ──
	var p6 := _lbl(
		"From that day on, your life was sold to the same system\nthat had already taken so much.",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 40.0))
	await _type(p6, slow_speed)
	await _hold(1.5)
	await _continue()
	await _clear(0.4)

	# ── Page 7 — stacked "Endless" lines ──
	var e1 := _rtl("[b]Endless[/b] shifts.",   28, _OFF_W, Vector2(_TX_L, 165.0))
	await _type(e1, text_speed)
	await _hold(0.5)

	var e2 := _rtl("[b]Endless[/b] orders.",   28, _OFF_W, Vector2(_TX_L, 255.0))
	await _type(e2, text_speed)
	await _hold(0.5)

	var e3 := _rtl(
		"[b]Endless[/b] years in a job that drained what little was left of you.",
		28, _OFF_W, Vector2(_TX_L, 345.0))
	await _type(e3, slow_speed)
	await _hold(2.0)
	await _continue()
	await _clear(0.5)

	# ── Second image (longer hold — emotional resolution) ──
	await _show_image("res://assets/ending pictures/ending 1_2.png", image_hold_final)

	# ── Final page ──
	var final := _rtl(
		"And yet, each night, when you returned home,\nyour pets were [b]still there waiting...[/b]",
		32, _OFF_W, Vector2(_CX, _TY_M), _TW_C)
	final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await _appear(final, 0.4)
	await _type(final, slow_speed)
	await _hold(3.0)
	await _continue()
	await _clear(0.6)

# ═════════════════════════════════════════════════════════════════════════════
#  ENDING 2 — A NEW START  (soft cyan, relieved → hopeful)
#  Images: ending 2.jpg  /  ending 2_2.png
#  Accent hex for BBCode: #60D8EF
# ═════════════════════════════════════════════════════════════════════════════
func _run_ending_2() -> void:
	_start_music(music_ending_2)

	await _show_title_card("ENDING  02", "A  NEW  START", _ACC_E2)

	# ── First image ──
	await _show_image("res://assets/ending pictures/ending 2.jpg")

	# ── Page 1 — "You made it." ──
	var p1 := _lbl("You made it.", 46, _BRIGHT_W,
				   Vector2(_CX, _TY_M - 10.0), _TW_C,
				   HORIZONTAL_ALIGNMENT_CENTER, _f_sb)
	await _appear(p1, 0.35)
	await _type(p1, slow_speed)
	await _hold(2.5)
	await _continue()
	await _clear(0.45)

	# ── Page 2 — narration ──
	var p2 := _rtl(
		"The winnings were enough to [b]repay the loan[/b] and pay for "
		+ "your mother's surgery.",
		28, _OFF_W, Vector2(_TX_L, _TY_T))
	await _type(p2, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 3 — warmer, brighter ──
	var p3 := _rtl(
		"Before long, she was finally able to [color=#60D8EF]come home[/color].",
		30, _OFF_W, Vector2(_TX_L, _TY_M))
	await _type(p3, text_speed)
	await _hold(1.5)
	await _continue()
	await _clear(0.45)

	# ── Page 4 — grounded ──
	var p4 := _rtl(
		"You couldn't afford to leave your job yet, but the competition "
		+ "had [b]changed something[/b].",
		28, _OFF_W, Vector2(_TX_L, _TY_M - 20.0))
	await _type(p4, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 5 — two-part reveal ──
	var p5a := _lbl(
		"You and your pets had done more than survive.",
		28, _OFF_W, Vector2(_TX_L, 268.0))
	await _type(p5a, text_speed)
	await _hold(1.0)

	var p5b := _rtl(
		"[color=#60D8EF]Together[/color], you had found something you were actually good at.",
		30, _OFF_W, Vector2(_TX_L, 360.0))
	await _type(p5b, slow_speed)
	await _hold(2.2)
	await _continue()
	await _clear(0.5)

	# ── Second image ──
	await _show_image("res://assets/ending pictures/ending 2_2.png")

	# ── Page 6 — narration ──
	var p6 := _lbl(
		"Over the following months, you continued training and entered\nsmaller tournaments whenever you could.",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 30.0))
	await _type(p6, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 7 ──
	var p7 := _rtl(
		"You weren't famous, but people were beginning to [b]recognise your name[/b].",
		28, _OFF_W, Vector2(_TX_L, _TY_M - 10.0))
	await _type(p7, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 8 — slight centre pull ──
	await _hold(0.4)
	var p8 := _rtl(
		"Maybe this pet thing could become [b]more than a desperate gamble[/b].",
		30, _OFF_W, Vector2(_TX_L + 60.0, _TY_M))
	await _type(p8, text_speed)
	await _hold(1.2)
	await _continue()
	await _clear(0.45)

	# ── Final page ──
	var final := _rtl(
		"Your future was still uncertain, but now,\nyou had [color=#60D8EF]the time to choose it[/color].",
		32, _OFF_W, Vector2(_CX, _TY_M), _TW_C)
	final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await _appear(final, 0.35)
	await _type(final, slow_speed)
	await _hold(3.0)
	await _continue()
	await _clear(0.6)

# ═════════════════════════════════════════════════════════════════════════════
#  ENDING 3 — MADE FOR THIS  (warm gold, triumphant → wholesome)
#  Images: ending 3.jpg  /  ending 3_2.png
#  Accent hex for BBCode: #D4A847
# ═════════════════════════════════════════════════════════════════════════════
func _run_ending_3() -> void:
	_start_music(music_ending_3)

	await _show_title_card("ENDING  03", "MADE  FOR  THIS", _ACC_E3)

	# ── First image (stronger but still restrained) ──
	await _show_image("res://assets/ending pictures/ending 3.jpg", image_hold + 1.0)

	# ── Page 1 — two-part triumphant reveal ──
	var p1a := _lbl("You didn't just survive.", 30, _OFF_W,
					Vector2(_TX_L, 265.0))
	await _type(p1a, text_speed)
	await _hold(0.8)

	var p1b := _lbl("You won.", 50, _BRIGHT_W,
					Vector2(_CX, 355.0), _TW_C,
					HORIZONTAL_ALIGNMENT_CENTER, _f_bold)
	await _appear(p1b, 0.12)
	await _type(p1b, slow_speed)
	await _hold(2.2)
	await _continue()
	await _clear(0.45)

	# ── Page 2 — narration ──
	var p2 := _rtl(
		"With your tournament success, you [b]paid for your mother's surgery[/b], "
		+ "[b]cleared the loan[/b], and still had enough left to do something "
		+ "you had almost forgotten was possible:",
		28, _OFF_W, Vector2(_TX_L, _TY_T))
	await _type(p2, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 3 — centred, largest, gold (most important line after final) ──
	var p3 := _lbl("Choose your own future.", 46, _ACC_E3,
				   Vector2(_CX, _TY_M - 10.0), _TW_C,
				   HORIZONTAL_ALIGNMENT_CENTER, _f_sb)
	await _appear(p3, 0.25)
	await _type(p3, slow_speed)
	await _hold(3.5)
	await _continue()
	await _clear(0.5)

	# ── Page 4 ──
	var p4 := _rtl(
		"[color=#D4A847]For once[/color], you didn't return to the life waiting to swallow you whole.",
		29, _OFF_W, Vector2(_TX_L, _TY_M - 10.0))
	await _type(p4, slow_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 5 ──
	var p5 := _rtl(
		"You walked away from the job, away from the fear,\nand toward something uncertain but [b]truly yours[/b].",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 40.0))
	await _type(p5, text_speed)
	await _hold(1.2)
	await _continue()
	await _clear(0.4)

	# ── Page 6 — bridge into second image ──
	var p6 := _lbl("What began with two pets had become something much bigger.",
				   33, _OFF_W, Vector2(_CX, _TY_M - 5.0), _TW_C,
				   HORIZONTAL_ALIGNMENT_CENTER, _f_med)
	await _appear(p6, 0.3)
	await _type(p6, text_speed)
	await _hold(2.0)
	await _continue()
	await _clear(0.5)

	# ── Second image (longest hold) ──
	await _show_image("res://assets/ending pictures/ending 3_2.png", image_hold_final + 1.0)

	# ── Page 7 ──
	var p7 := _rtl(
		"You kept competing, and [b]victory after victory[/b] carried your name further across the city.",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 30.0))
	await _type(p7, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 8 ──
	var p8 := _rtl(
		"Before long, crowds came just to watch you, [color=#D4A847]Cat[/color], [color=#D4A847]Snake[/color],\n"
		+ "and the strange bond you had built together.",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 40.0))
	await _type(p8, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 9 ──
	var p9 := _rtl(
		"Back home, several eggs now rested quietly in your apartment,\n"
		+ "each one holding [b]the promise of a new companion[/b].",
		28, _OFF_W, Vector2(_TX_L, _TY_T + 40.0))
	await _type(p9, text_speed)
	await _continue()
	await _clear(0.4)

	# ── Page 10 ──
	var p10 := _rtl(
		"Your [color=#D4A847]little family[/color] was still small,\nbut it would not stay that way forever.",
		30, _OFF_W, Vector2(_TX_L + 60.0, _TY_M))
	await _type(p10, text_speed)
	await _hold(1.2)
	await _continue()
	await _clear(0.4)

	# ── Page 11 — confident promise ──
	var p11 := _rtl(
		"One day, [b]the whole world would know your name[/b]\nas [b]one of the greatest digital pet trainers[/b] who ever lived.",
		30, _OFF_W, Vector2(_TX_L, _TY_T + 40.0))
	await _type(p11, text_speed)
	await _hold(2.0)
	await _continue()
	await _clear(0.45)

	# ── Final page — return to family ──
	var final := _rtl(
		"But for now, you were happy [b]simply being home[/b],\n"
		+ "surrounded by your mother, your pets,\nand [b]the future waiting to hatch[/b].",
		32, _OFF_W, Vector2(_CX, _TY_M - 30.0), _TW_C)
	final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await _appear(final, 0.4)
	await _type(final, slow_speed)
	await _hold(4.0)
	await _continue()
	await _clear(0.7)
