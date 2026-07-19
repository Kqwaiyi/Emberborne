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
var _place: int = 0
var _is_transitioning: bool = false

var dummy_names: Array[String] = ["CatLover99", "PawMaster", "PixelCat", "SpeedyPaws", "ScratchKing", "Meowz", "NyanNyan", "FelineGood", "KittyKat", "Purrfect", "NineLives", "MeowMaster", "WhiskerWizard", "TailChaser", "PurrMachine"]

@onready var _score_row: HBoxContainer = $Panel/VBox/ScoreCenter/ScoreRow
@onready var _bracket_label: Label = $Panel/VBox/BracketLabel
@onready var _leaderboard_list: VBoxContainer = $Panel/VBox/LeaderboardList


func _ready() -> void:
	_total = GameState.total_score
	_place = _calculate_place(_total)
	
	GameGlobal.cat_game_final_place = _place
	GameGlobal.set_minigame_finish_place("cat_game", _place)
	
	_bracket_label.hide()
	_leaderboard_list.hide()

	var score_text: String = str(maxi(0, _total))

	for character: String in score_text:
		_digit_vals.append(int(character))

	_build_digits()
	_animate()

func _calculate_place(score: int) -> int:
	if score >= 15000:
		return 1
	elif score >= 13000:
		return 2
	elif score >= 10000:
		return 3
	elif score >= 8000:
		return 4
	else:
		var place = 4 + floor(pow((8000.0 - float(score)) / 80.0, 2.0))
		return clampi(int(place), 5, 10000)


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
	await get_tree().create_timer(0.3).timeout
	
	var total_steps: int = 12
	var temp_idx: int = 0
	for i in range(_digit_vals.size()):
		total_steps += maxi(4, 10 - temp_idx * 2)
		temp_idx += 1
		
	var step_delay: float = 3.0 / float(total_steps)

	# Shuffle all digits together.
	for _shuffle_step: int in range(12):
		for label: Label in _digit_labels:
			var random_index: int = randi() % 10
			label.text = _SHUFFLE[random_index]

		await get_tree().create_timer(step_delay).timeout

	# Reveal digits one at a time from left to right.
	var digit_idx = 0
	for i: int in range(_digit_vals.size()):
		var spins: int = maxi(4, 10 - digit_idx * 2)

		for _spin_step: int in range(spins):
			for j: int in range(digit_idx, _digit_labels.size()):
				var random_index: int = randi() % 10
				_digit_labels[j].text = _SHUFFLE[random_index]

			await get_tree().create_timer(step_delay).timeout

		_digit_labels[digit_idx].text = str(_digit_vals[i])
		_digit_labels[digit_idx].add_theme_color_override(
			"font_color",
			_GOLD
		)
		digit_idx += 1

	await get_tree().create_timer(0.3).timeout
	_apply_color()

	_bracket_label.text = "You have placed  # " + str(_place)
	_bracket_label.show()

	_generate_leaderboard(_place, _total)
	_leaderboard_list.show()

	await get_tree().create_timer(0.9).timeout
	_show_continue_button()


func _apply_color() -> void:
	if _total >= 15000:
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

func _show_continue_button() -> void:
	var btn := Button.new()
	btn.text = "Continue to Ending  ▶"
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color",         Color(0.18, 0.12, 0.07, 1.0))
	btn.add_theme_color_override("font_hover_color",   Color(0.18, 0.12, 0.07, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.18, 0.12, 0.07, 1.0))

	var style := StyleBoxFlat.new()
	style.bg_color            = Color(0.898, 0.816, 0.663, 1.0)
	style.border_color        = Color(0.216, 0.149, 0.086, 1.0)
	style.border_width_left   = 3
	style.border_width_top    = 3
	style.border_width_right  = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left  = 4
	style.content_margin_left   = 16.0
	style.content_margin_top    = 10.0
	style.content_margin_right  = 16.0
	style.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", style)

	btn.modulate.a = 0.0
	$Panel/VBox.add_child(btn)
	btn.pressed.connect(_on_continue_pressed)

	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 1.0, 0.5)

func _on_continue_pressed() -> void:
	# Transition to the cinematic ending sequence.
	# Score is read directly from GameState inside ending_sequence.gd.
	if SceneManager:
		SceneManager.change_scene_to_file("res://scenes/core/ending_sequence.tscn", 1.0)
	else:
		get_tree().change_scene_to_file("res://scenes/core/ending_sequence.tscn")

func _create_entry(rank: String, username: String, score_val: int, is_player: bool = false) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	var rank_label: Label = Label.new()
	rank_label.text = rank
	rank_label.custom_minimum_size = Vector2(100, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	var name_label: Label = Label.new()
	name_label.text = username
	name_label.custom_minimum_size = Vector2(200, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	var score_lbl: Label = Label.new()
	score_lbl.text = str(score_val)
	score_lbl.custom_minimum_size = Vector2(100, 0)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.add_theme_font_size_override("font_size", 20)
	score_lbl.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	if is_player:
		var color: Color = Color(0.7, 0.4, 0.05, 1) # Darker gold/orange
		rank_label.add_theme_color_override("font_color", color)
		name_label.add_theme_color_override("font_color", color)
		score_lbl.add_theme_color_override("font_color", color)
	
	hbox.add_child(rank_label)
	hbox.add_child(name_label)
	hbox.add_child(score_lbl)
	
	_leaderboard_list.add_child(hbox)

func _create_separator() -> void:
	var label: Label = Label.new()
	label.text = "..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	_leaderboard_list.add_child(label)

func _generate_leaderboard(player_place: int, player_score: int) -> void:
	dummy_names.shuffle()
	var name_idx: int = 0
	
	var top3_scores: Array[int] = []
	if player_place == 1:
		top3_scores = [
			player_score,
			maxi(player_score - randi_range(50, 500), 13500),
			maxi(player_score - randi_range(600, 1500), 12500)
		]
	elif player_place == 2:
		top3_scores = [
			player_score + randi_range(50, 1500),
			player_score,
			maxi(player_score - randi_range(50, 500), 10500)
		]
	else:
		top3_scores = [
			15500 + randi_range(50, 2000),
			14500 + randi_range(50, 1000),
			13500 + randi_range(50, 800)
		]
		if player_place == 3:
			top3_scores[2] = player_score
	
	# Output Top 3
	for i in range(1, 4):
		if i == player_place:
			_create_entry(str(i) + ".", "You", player_score, true)
		else:
			_create_entry(str(i) + ".", dummy_names[name_idx], top3_scores[i-1])
			name_idx += 1
			
	if player_place <= 9:
		var last_score: int = top3_scores[2]
		for i in range(4, 10):
			if i == player_place:
				_create_entry(str(i) + ".", "You", player_score, true)
				last_score = player_score
			else:
				var s: int
				if i < player_place:
					var gap: int = last_score - player_score
					var steps_left: int = player_place - i + 1
					s = last_score - maxi(1, gap / steps_left) - randi_range(0, 50)
					s = maxi(s, player_score + 1)
				else:
					s = last_score - randi_range(50, 200)
					
				_create_entry(str(i) + ".", dummy_names[name_idx], maxi(s, 0))
				last_score = maxi(s, 0)
				name_idx += 1
		
		if player_place < 9991:
			_create_separator()
		return
		
	# Player is > 9
	_create_separator()
	
	var above_score: int = player_score + randi_range(50, 200) * 2
	for i in range(player_place - 2, player_place):
		_create_entry(str(i) + ".", dummy_names[name_idx], above_score)
		above_score -= randi_range(20, 100)
		above_score = maxi(above_score, player_score + 1)
		name_idx += 1
		
	_create_entry(str(player_place) + ".", "You", player_score, true)
	
	var below_score: int = player_score
	for i in range(player_place + 1, mini(player_place + 4, 10001)):
		below_score -= randi_range(20, 100)
		_create_entry(str(i) + ".", dummy_names[name_idx], maxi(below_score, 0))
		name_idx += 1
		
	if player_place < 9997:
		_create_separator()

func _on_back_button_pressed() -> void:
	if _is_transitioning: return
	_is_transitioning = true
	
	MusicManager.play_music("pet_world", true)
	
	var laptops = get_tree().get_nodes_in_group("laptop_ui")
	if laptops.size() > 0:
		laptops[0].change_scene("res://scenes/pet_world/lobby/mainlobby.tscn", 0.5)
	else:
		get_tree().paused = false
		SceneManager.change_scene_to_file("res://scenes/pet_world/lobby/mainlobby.tscn")
