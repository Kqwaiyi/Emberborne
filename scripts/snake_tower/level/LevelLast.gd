extends Control

const _SHUFFLE: String = "0123456789"

const _RED: Color = Color(0.90, 0.15, 0.10, 1.0)
const _GREEN: Color = Color(0.18, 0.88, 0.28, 1.0)
const _GOLD: Color = Color(0.96, 0.80, 0.25, 1.0)

var _time_str: String = ""
var _digit_chars: Array[String] = []
var _digit_labels: Array[Label] = []
var _place: int = 0
var _time: float = 0.0

var _rainbow_active: bool = false
var _rainbow_hue: float = 0.0

@onready var _score_row = $Panel/VBox/ScoreCenter/ScoreRow
@onready var _bracket_label = $Panel/VBox/BracketLabel
@onready var _leaderboard_list = $Panel/VBox/LeaderboardList
@onready var _bot_div = $Panel/VBox/BotDiv
@onready var _panel = $Panel

var dummy_names = ["GamerPro99", "SnakeKing", "EmberSnek", "FastBoi", "SpeedRunner", "SnekMaster", "SlipperySnek", "Venom", "Ouroboros", "GridWalker", "LongSnek", "PixelSnake", "AppleEater", "TombRaider", "GhostSnek"]

func _ready():
	_time = GlobalSnaketower.total_time_elapsed
	_time_str = _format_time(_time)
	
	GlobalSnaketower.pause_time()
	
	_place = _calculate_place(_time)
	GameGlobal.set_minigame_finish_place("snake_tower", _place)
	
	_bracket_label.hide()
	_leaderboard_list.hide()
	_bot_div.hide()
	
	for character in _time_str:
		_digit_chars.append(character)
		
	_build_digits()
	_animate()

func _calculate_place(time: float) -> int:
	if time <= 480.0: # 8 mins
		return 1
	elif time <= 600.0: # 10 mins
		return 2
	elif time <= 720.0: # 12 mins
		return 3
	elif time <= 900.0: # 15 mins
		return 4
	else:
		var place = 4 + floor(pow((time - 900.0) / 60.0, 2.0) * 5.0)
		return clampi(int(place), 5, 10000)

func _format_time(t: float) -> String:
	var mins = int(t) / 60
	var secs = int(t) % 60
	var millis = int((t - int(t)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, millis]

func _build_digits() -> void:
	for i in range(_digit_chars.size()):
		var char_val = _digit_chars[i]
		var label = Label.new()
		
		if char_val == ":" or char_val == ".":
			label.text = char_val
			label.add_theme_font_size_override("font_size", 68)
			label.add_theme_color_override("font_color", Color(0.40, 0.30, 0.20, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
			label.add_theme_constant_override("outline_size", 5)
			_score_row.add_child(label)
		else:
			label.text = "0"
			label.add_theme_font_size_override("font_size", 68)
			label.add_theme_color_override("font_color", Color(0.40, 0.30, 0.20, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
			label.add_theme_constant_override("outline_size", 5)
			_score_row.add_child(label)
			_digit_labels.append(label)

func _animate() -> void:
	await get_tree().create_timer(0.3).timeout
	
	var total_steps: int = 12
	var temp_idx: int = 0
	for i in range(_digit_chars.size()):
		if _digit_chars[i] == ":" or _digit_chars[i] == ".":
			continue
		total_steps += maxi(4, 10 - temp_idx * 2)
		temp_idx += 1
		
	var step_delay: float = 3.0 / float(total_steps)

	# Shuffle all digits together.
	for _shuffle_step in range(12):
		for label in _digit_labels:
			var random_index = randi() % 10
			label.text = _SHUFFLE[random_index]
		await get_tree().create_timer(step_delay).timeout

	# Reveal digits one at a time from left to right.
	var digit_idx = 0
	for i in range(_digit_chars.size()):
		var actual_char = _digit_chars[i]
		if actual_char == ":" or actual_char == ".":
			continue
			
		var spins = maxi(4, 10 - digit_idx * 2)
		for _spin_step in range(spins):
			for j in range(digit_idx, _digit_labels.size()):
				var random_index = randi() % 10
				_digit_labels[j].text = _SHUFFLE[random_index]
			await get_tree().create_timer(step_delay).timeout

		_digit_labels[digit_idx].text = actual_char
		_digit_labels[digit_idx].add_theme_color_override("font_color", _GOLD)
		digit_idx += 1

	await get_tree().create_timer(0.3).timeout
	_apply_color()
	
	_bracket_label.text = "You have placed  # " + str(_place)
	_bot_div.show()
	_bracket_label.show()
	
	_generate_leaderboard(_place, _time)
	_leaderboard_list.show()

func _apply_color() -> void:
	if _place == 1:
		_rainbow_active = true
		return

	var time_color: Color

	if _place <= 3:
		time_color = _GOLD
	elif _place <= 10:
		time_color = _GREEN
	else:
		time_color = _RED

	for label in _digit_labels:
		label.add_theme_color_override("font_color", time_color)

func _process(delta: float) -> void:
	if not _rainbow_active:
		return

	_rainbow_hue = fmod(_rainbow_hue + delta * 2.0, 1.0)

	var digit_count: int = maxi(1, _digit_labels.size())

	for i in range(_digit_labels.size()):
		var hue_offset: float = float(i) * 0.25 / float(digit_count)
		var hue: float = fmod(_rainbow_hue + hue_offset, 1.0)
		var rainbow_color: Color = Color.from_hsv(hue, 1.0, 1.0)
		_digit_labels[i].add_theme_color_override("font_color", rainbow_color)

func _create_entry(rank: String, username: String, time_str: String, is_player: bool = false):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	var rank_label = Label.new()
	rank_label.text = rank
	rank_label.custom_minimum_size = Vector2(100, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	var name_label = Label.new()
	name_label.text = username
	name_label.custom_minimum_size = Vector2(200, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	var time_lbl = Label.new()
	time_lbl.text = time_str
	time_lbl.custom_minimum_size = Vector2(100, 0)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_font_size_override("font_size", 20)
	time_lbl.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	
	if is_player:
		var color = Color(0.7, 0.4, 0.05, 1) # A darker gold/orange for player to stand out on cream bg
		rank_label.add_theme_color_override("font_color", color)
		name_label.add_theme_color_override("font_color", color)
		time_lbl.add_theme_color_override("font_color", color)
	
	hbox.add_child(rank_label)
	hbox.add_child(name_label)
	hbox.add_child(time_lbl)
	
	_leaderboard_list.add_child(hbox)

func _create_separator():
	var label = Label.new()
	label.text = "..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1))
	_leaderboard_list.add_child(label)

func _generate_leaderboard(player_place: int, player_time: float):
	dummy_names.shuffle()
	var name_idx = 0
	
	var top3_times = []
	if player_place == 1:
		top3_times = [
			player_time,
			max(player_time + randf_range(5.0, 15.0), 485.0),
			max(player_time + randf_range(16.0, 30.0), 495.0)
		]
	elif player_place == 2:
		top3_times = [
			min(player_time - randf_range(5.0, 20.0), 479.0),
			player_time,
			max(player_time + randf_range(5.0, 15.0), 485.0)
		]
	else:
		top3_times = [
			randf_range(450.0, 479.0),
			randf_range(485.0, 500.0),
			randf_range(510.0, 540.0)
		]
		if player_place == 3:
			top3_times[2] = player_time
	
	# Output Top 3
	for i in range(1, 4):
		if i == player_place:
			_create_entry(str(i) + ".", "You", _format_time(player_time), true)
		else:
			_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(top3_times[i-1]))
			name_idx += 1
			
	if player_place <= 3:
		for i in range(4, 10):
			var t = top3_times[2] + randf_range(10.0, 30.0) * (i - 3)
			_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(t))
			name_idx += 1
		_create_separator()
		return
	
	if player_place <= 7:
		for i in range(4, player_place + 4):
			if i == player_place:
				_create_entry(str(i) + ".", "You", _format_time(player_time), true)
			else:
				var t = player_time + randf_range(2.0, 10.0) * (i - player_place)
				if i < player_place:
					t = player_time - randf_range(2.0, 10.0) * (player_place - i)
				_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(t))
				name_idx += 1
		_create_separator()
		return
		
	# Player is > 7
	_create_separator()
	
	for i in range(player_place - 3, player_place):
		var t = player_time - randf_range(5.0, 20.0) * (player_place - i)
		_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(t))
		name_idx += 1
		
	_create_entry(str(player_place) + ".", "You", _format_time(player_time), true)
	
	for i in range(player_place + 1, mini(player_place + 4, 10001)):
		var t = player_time + randf_range(5.0, 20.0) * (i - player_place)
		_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(t))
		name_idx += 1
		
	if player_place < 9997:
		_create_separator()
