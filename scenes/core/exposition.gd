extends Node

# ─── Font paths ───────────────────────────────────────────────────────────────
const _F_REG  := "res://assets/fonts/Chakra_Petch/ChakraPetch-Regular.ttf"
const _F_BOLD := "res://assets/fonts/Chakra_Petch/ChakraPetch-Bold.ttf"
const _F_SB   := "res://assets/fonts/Chakra_Petch/ChakraPetch-SemiBold.ttf"
const _F_LT   := "res://assets/fonts/Chakra_Petch/ChakraPetch-Light.ttf"
const _F_MED  := "res://assets/fonts/Chakra_Petch/ChakraPetch-Medium.ttf"

# ─── Palette ──────────────────────────────────────────────────────────────────
const _OFF_WHITE    := Color(0.918, 0.910, 0.894, 1.0)
const _BRIGHT_WHITE := Color(1.000, 1.000, 1.000, 1.0)
const _CYAN         := Color(0.376, 0.847, 0.937, 1.0)

# ─── Layout ───────────────────────────────────────────────────────────────────
const _ML  := 130.0
const _NW  := 1620.0
const _CX  := 0.0
const _CW  := 1920.0

# ─── State ────────────────────────────────────────────────────────────────────
var _canvas    : CanvasLayer   # story text
var _ui_canvas : CanvasLayer   # prompt — layer 10, always on top
var _pool      : Array[Control] = []

# Set by _unhandled_input on Space. Consumed by _continue().
# _type() reads it too (to skip the typewriter) but does NOT consume it —
# that way one press skips the current typewriter AND advances to next section.
var _advance_requested := false

var _prompt    : Label
var _prompt_bg : ColorRect
var _prompt_ln : ColorRect
var _prompt_tw : Tween

var _f_reg  : FontFile
var _f_bold : FontFile
var _f_sb   : FontFile
var _f_lt   : FontFile
var _f_med  : FontFile

# ═════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	if GameGlobal:
		GameGlobal.advance_story_state(GameGlobal.StoryState.PHASE1_EXPOSITION)

	_canvas = CanvasLayer.new()
	add_child(_canvas)

	# Separate layer so prompt always draws above all story text
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 10
	add_child(_ui_canvas)

	_f_reg  = _load_font(_F_REG)
	_f_bold = _load_font(_F_BOLD)
	_f_sb   = _load_font(_F_SB)
	_f_lt   = _load_font(_F_LT)
	_f_med  = _load_font(_F_MED)

	_make_prompt()
	_run.call_deferred()

func _load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	return null

# ─── Input ────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey \
			and event.keycode == KEY_SPACE \
			and event.pressed \
			and not event.echo:
		_advance_requested = true

# ─── Prompt ───────────────────────────────────────────────────────────────────
func _make_prompt() -> void:
	# Viewport is 1280×720 — prompt anchored to bottom-right with 20 px margin.
	_prompt_bg       = ColorRect.new()
	_prompt_bg.color = Color(0.02, 0.04, 0.08, 0.55)
	_prompt_bg.position = Vector2(930.0, 656.0)
	_prompt_bg.size     = Vector2(330.0,  44.0)
	_ui_canvas.add_child(_prompt_bg)

	_prompt_ln       = ColorRect.new()
	_prompt_ln.color = Color(0.376, 0.847, 0.937, 0.30)
	_prompt_ln.position = Vector2(930.0, 656.0)
	_prompt_ln.size     = Vector2(330.0,   1.0)
	_ui_canvas.add_child(_prompt_ln)

	_prompt          = Label.new()
	_prompt.text     = "  PRESS  SPACE  TO CONTINUE"
	_prompt.position = Vector2(934.0, 664.0)
	_prompt.size     = Vector2(322.0,  34.0)
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", _CYAN)
	if _f_lt:
		_prompt.add_theme_font_override("font", _f_lt)
	_ui_canvas.add_child(_prompt)

	_ui_canvas.visible = false

func _show_prompt() -> void:
	_ui_canvas.visible = true
	_prompt.modulate.a = 1.0
	if _prompt_tw:
		_prompt_tw.kill()
	_prompt_tw = create_tween()
	_prompt_tw.set_loops()
	_prompt_tw.tween_property(_prompt, "modulate:a", 1.0, 0.65)
	_prompt_tw.tween_property(_prompt, "modulate:a", 0.25, 0.65)

func _hide_prompt() -> void:
	if _prompt_tw:
		_prompt_tw.kill()
		_prompt_tw = null
	_ui_canvas.visible = false

# Shows prompt and waits for Space.
# If Space was already pressed during the preceding _type() the advance flag
# is still set, so this returns immediately (one press = skip type + advance).
func _continue() -> void:
	_show_prompt()
	while not _advance_requested:
		await get_tree().process_frame
	_advance_requested = false
	_hide_prompt()

# ═════════════════════════════════════════════════════════════════════════════
#  FACTORIES
# ═════════════════════════════════════════════════════════════════════════════

func _lbl(txt: String, sz: int, col: Color, pos: Vector2,
		  w: float = _NW,
		  align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		  font: FontFile = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = Vector2(w, 300.0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.visible_characters = 0
	l.modulate.a = 0.0
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	var f := font if font else _f_reg
	if f:
		l.add_theme_font_override("font", f)
	_canvas.add_child(l)
	_pool.append(l)
	return l

func _rtl(txt: String, sz: int, col: Color, pos: Vector2,
		  w: float = _NW) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = txt
	r.position = pos
	r.size = Vector2(w, 300.0)
	r.scroll_active = false
	r.visible_characters = 0
	r.modulate.a = 0.0
	r.add_theme_font_size_override("normal_font_size", sz)
	r.add_theme_font_size_override("bold_font_size", sz)
	r.add_theme_color_override("default_color", col)
	if _f_reg:  r.add_theme_font_override("normal_font", _f_reg)
	if _f_bold: r.add_theme_font_override("bold_font", _f_bold)
	_canvas.add_child(r)
	_pool.append(r)
	return r

# ═════════════════════════════════════════════════════════════════════════════
#  ANIMATION PRIMITIVES
# ═════════════════════════════════════════════════════════════════════════════

func _set_chars(n: Control, count: int) -> void:
	if n is Label:           (n as Label).visible_characters           = count
	elif n is RichTextLabel: (n as RichTextLabel).visible_characters   = count

func _get_total(n: Control) -> int:
	if n is Label:           return (n as Label).get_total_character_count()
	elif n is RichTextLabel: return (n as RichTextLabel).get_total_character_count()
	return 0

# Types text character by character.
# If Space is pressed mid-type, the typewriter is skipped instantly.
# The _advance_requested flag is NOT consumed here — _continue() consumes it,
# so one Space press both skips the typewriter and advances to the next section.
func _type(n: Control, speed: float = 0.016) -> void:
	n.modulate.a = 1.0
	var total := _get_total(n)
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

func _appear(n: Control, dur: float = 0.2) -> void:
	var t := create_tween()
	t.tween_property(n, "modulate:a", 1.0, dur)
	await t.finished

func _dim(n: Control, alpha: float = 0.35, dur: float = 0.35) -> void:
	if not is_instance_valid(n): return
	var t := create_tween()
	t.tween_property(n, "modulate:a", alpha, dur)

func _hold(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _clear(fade: float = 0.45, gap: float = 0.0) -> void:
	for n in _pool:
		if is_instance_valid(n) and n.modulate.a > 0.01:
			var t := create_tween()
			t.tween_property(n, "modulate:a", 0.0, fade)
	if not _pool.is_empty():
		await _hold(fade)
	for n in _pool:
		if is_instance_valid(n):
			n.queue_free()
	_pool.clear()
	if gap > 0.0:
		await _hold(gap)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 1 – Year card
# ═════════════════════════════════════════════════════════════════════════════
func _b1() -> void:
	var year := _lbl(
		"Y E A R    2 5 1 1",
		24, _CYAN,
		Vector2(80.0, 50.0), 640.0,
		HORIZONTAL_ALIGNMENT_LEFT, _f_lt
	)
	await _appear(year, 0.3)
	await _type(year, 0.032)
	await _continue()
	_dim(year, 0.22, 0.5)
	await _hold(0.15)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 2 – Tech advancement  (auto-flows between lines, Space at end)
# ═════════════════════════════════════════════════════════════════════════════
func _b2() -> void:
	const Y0  := 212.0
	const GAP := 70.0
	const SZ  := 22

	var l1 := _rtl("[color=#60D8EF]Technology[/color] has changed almost everything.",
				   SZ, _OFF_WHITE, Vector2(_ML, Y0))
	await _type(l1, 0.015)
	await _hold(0.28)
	_dim(l1, 0.38, 0.35)

	var l2 := _rtl("[color=#60D8EF]Artificial intelligence[/color] manages the cities.",
				   SZ, _OFF_WHITE, Vector2(_ML, Y0 + GAP))
	await _type(l2, 0.015)
	await _hold(0.28)
	_dim(l2, 0.38, 0.35)

	var l3 := _rtl("[color=#60D8EF]Holograms[/color] have replaced most handheld technologies.",
				   SZ, _OFF_WHITE, Vector2(_ML, Y0 + GAP * 2.0))
	await _type(l3, 0.015)
	await _hold(0.28)
	_dim(l3, 0.38, 0.35)

	var l4 := _rtl("Machines can [color=#60D8EF]preserve a human body[/color] long after it begins to fail.",
				   SZ, _OFF_WHITE, Vector2(_ML, Y0 + GAP * 3.0))
	await _type(l4, 0.016)

	await _continue()
	await _clear(0.45)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 3 – Contrast line
# ═════════════════════════════════════════════════════════════════════════════
func _b3() -> void:
	var contrast := _lbl(
		"But life has not become easier.",
		40, _BRIGHT_WHITE,
		Vector2(_CX, 432.0), _CW,
		HORIZONTAL_ALIGNMENT_CENTER, _f_bold
	)
	await _appear(contrast, 0.15)
	await _type(contrast, 0.016)
	await _continue()
	await _clear(0.40)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 4 – Economic reality  (auto-flows, Space at end)
# ═════════════════════════════════════════════════════════════════════════════
func _b4() -> void:
	const RY  := 240.0
	const RG  := 74.0
	const RSZ := 22

	var r1 := _lbl("Rent rises every year.", RSZ, _OFF_WHITE, Vector2(_ML, RY))
	await _type(r1, 0.018)
	await _hold(0.25)
	_dim(r1, 0.40, 0.35)

	var r2 := _rtl(
		"Food, power, and medical care are [b]luxuries[/b] sold to the [color=#60D8EF]highest bidder[/color].",
		RSZ, _OFF_WHITE, Vector2(_ML, RY + RG))
	await _type(r2, 0.015)
	await _hold(0.25)
	_dim(r2, 0.40, 0.35)

	var r3 := _rtl(
		"People work longer, live in smaller homes, and [b]owe more than they can ever repay[/b].",
		RSZ, _OFF_WHITE, Vector2(_ML, RY + RG * 2.0))
	await _type(r3, 0.015)

	await _continue()
	await _clear(0.45)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 5 – Virtual Pets reveal  (setup auto-flows into impact)
# ═════════════════════════════════════════════════════════════════════════════
func _b5() -> void:
	var setup := _rtl(
		"As real pets became too expensive for many households,\ncompanies created an alternative:",
		21, _OFF_WHITE, Vector2(_ML, 292.0))
	await _type(setup, 0.015)
	await _hold(0.30)
	await _clear(0.35)

	var vp := _lbl(
		"VIRTUAL PETS.",
		72, _BRIGHT_WHITE,
		Vector2(_CX, 386.0), _CW,
		HORIZONTAL_ALIGNMENT_CENTER, _f_bold
	)
	await _appear(vp, 0.10)
	await _type(vp, 0.034)

	await _continue()
	await _clear(0.45)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 6 – Evolution  (auto-flows, Space at end)
# ═════════════════════════════════════════════════════════════════════════════
func _b6() -> void:
	const EY  := 224.0
	const EG  := 74.0

	var e1 := _rtl("At first, they were simple programs designed to entertain.",
				   22, _OFF_WHITE, Vector2(_ML, EY))
	await _type(e1, 0.014)
	await _hold(0.25)
	_dim(e1, 0.38, 0.35)

	var e2 := _rtl("Then they began to [b]remember[/b].",
				   24, _OFF_WHITE, Vector2(_ML, EY + EG))
	await _type(e2, 0.016)
	await _hold(0.25)
	_dim(e2, 0.42, 0.35)

	await _hold(0.10)
	var e3 := _lbl("To learn.", 32, _BRIGHT_WHITE,
				   Vector2(_ML + 16.0, EY + EG * 2.0),
				   600.0, HORIZONTAL_ALIGNMENT_LEFT, _f_sb)
	await _appear(e3, 0.06)
	await _type(e3, 0.026)
	await _hold(0.20)
	_dim(e3, 0.42, 0.35)

	var e4 := _rtl("To [color=#60D8EF]develop personalities[/color] of their own.",
				   26, _OFF_WHITE, Vector2(_ML, EY + EG * 3.0))
	await _type(e4, 0.016)

	await _continue()
	await _clear(0.45)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 7 – "But to some..."  (neutral auto-flows into impact)
# ═════════════════════════════════════════════════════════════════════════════
func _b7() -> void:
	var neutral := _rtl("To most people, they are still only software to pass the time.",
						21, _OFF_WHITE, Vector2(_ML, 312.0))
	await _type(neutral, 0.013)
	await _hold(0.28)
	await _clear(0.35)

	var but := _lbl(
		"But to some...",
		28, _OFF_WHITE,
		Vector2(_CX, 498.0), _CW,
		HORIZONTAL_ALIGNMENT_CENTER, _f_med
	)
	await _appear(but, 0.18)
	await _type(but, 0.030)

	await _continue()
	await _clear(0.40)

# ═════════════════════════════════════════════════════════════════════════════
#  BEAT 8 – "They are family."
# ═════════════════════════════════════════════════════════════════════════════
func _b8() -> void:
	var family := _lbl(
		"They are family.",
		54, _BRIGHT_WHITE,
		Vector2(_CX, 416.0), _CW,
		HORIZONTAL_ALIGNMENT_CENTER, _f_sb
	)
	await _appear(family, 0.35)
	await _type(family, 0.030)

	await _continue()
	await _clear(0.60)

# ═════════════════════════════════════════════════════════════════════════════
#  MAIN SEQUENCE
# ═════════════════════════════════════════════════════════════════════════════
func _run() -> void:
	await _b1()
	await _b2()
	await _b3()
	await _b4()
	await _b5()
	await _b6()
	await _b7()
	await _b8()

	if GameGlobal:
		GameGlobal.advance_story_state(GameGlobal.StoryState.PHASE1_APARTMENT)
	if SceneManager:
		SceneManager.change_scene_to_file("res://scenes/scifi_home/the_home/map.tscn", 1.0)
