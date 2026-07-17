class_name EndScreen
extends Control

const _SHUFFLE: String = "0123456789"

const _RED: Color = Color(0.90, 0.15, 0.10, 1.0)
const _ORANGE: Color = Color(1.00, 0.55, 0.10, 1.0)
const _YELLOW: Color = Color(0.95, 0.88, 0.15, 1.0)
const _GREEN: Color = Color(0.18, 0.88, 0.28, 1.0)
const _GOLD: Color = Color(0.96, 0.80, 0.25, 1.0)

var _total: int = 0
var _digit_vals: Array[int] = []
var _digit_labels: Array[Label] = []

var _rainbow_active: bool = false
var _rainbow_hue: float = 0.0

@onready var _score_row: HBoxContainer = $Panel/VBox/ScoreCenter/ScoreRow
@onready var _bracket_label: Label = $Panel/VBox/BracketLabel


func _ready() -> void:
	_total = GameState.total_score

	var score_text: String = str(maxi(0, _total))

	for character: String in score_text:
		_digit_vals.append(int(character))

	_build_digits()
	_animate()


func _build_digits() -> void:
	for _i: int in range(_digit_vals.size()):
		var label: Label = Label.new()

		label.text = "0"
		label.add_theme_font_size_override("font_size", 68)
		label.add_theme_color_override(
			"font_color",
			Color(0.40, 0.30, 0.20, 1.0)
		)
		label.add_theme_color_override(
			"font_outline_color",
			Color(0.0, 0.0, 0.0, 0.75)
		)
		label.add_theme_constant_override("outline_size", 5)

		_score_row.add_child(label)
		_digit_labels.append(label)


func _animate() -> void:
	await get_tree().create_timer(0.7).timeout

	# Shuffle all digits together.
	for _shuffle_step: int in range(22):
		for label: Label in _digit_labels:
			var random_index: int = randi() % 10
			label.text = _SHUFFLE[random_index]

		await get_tree().create_timer(0.055).timeout

	# Reveal digits one at a time from left to right.
	for i: int in range(_digit_vals.size()):
		var spins: int = maxi(5, 13 - i * 3)

		for _spin_step: int in range(spins):
			for j: int in range(i, _digit_labels.size()):
				var random_index: int = randi() % 10
				_digit_labels[j].text = _SHUFFLE[random_index]

			await get_tree().create_timer(0.055).timeout

		_digit_labels[i].text = str(_digit_vals[i])
		_digit_labels[i].add_theme_color_override(
			"font_color",
			_GOLD
		)

		await get_tree().create_timer(0.30).timeout

	await get_tree().create_timer(0.55).timeout
	_apply_color()


func _apply_color() -> void:
	if _total >= 10000:
		_rainbow_active = true
		return

	var score_color: Color

	if _total >= 15000:
		score_color = _GREEN
	elif _total >= 13000:
		score_color = _YELLOW
	elif _total >= 11000:
		score_color = _ORANGE
	else:
		score_color = _RED

	for label: Label in _digit_labels:
		label.add_theme_color_override(
			"font_color",
			score_color
		)


func _process(delta: float) -> void:
	if not _rainbow_active:
		return

	_rainbow_hue = fmod(_rainbow_hue + delta * 2.0, 1.0)

	var digit_count: int = maxi(1, _digit_labels.size())

	for i: int in range(_digit_labels.size()):
		var hue_offset: float = (
			float(i) * 0.25 / float(digit_count)
		)
		var hue: float = fmod(
			_rainbow_hue + hue_offset,
			1.0
		)

		var rainbow_color: Color = Color.from_hsv(
			hue,
			1.0,
			1.0
		)

		_digit_labels[i].add_theme_color_override(
			"font_color",
			rainbow_color
		)
