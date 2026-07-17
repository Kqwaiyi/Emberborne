extends Control

@onready var time_label = $CenterContainer/VBoxContainer/TimeLabel
@onready var leaderboard_list = $CenterContainer/VBoxContainer/LeaderboardList

var dummy_names = ["GamerPro99", "SnakeKing", "EmberSnek", "FastBoi", "SpeedRunner", "SnekMaster", "SlipperySnek", "Venom", "Ouroboros", "GridWalker", "LongSnek", "PixelSnake", "AppleEater", "TombRaider", "GhostSnek"]

func _ready():
	var time = GlobalSnaketower.total_time_elapsed
	var mins = int(time) / 60
	var secs = int(time) % 60
	var millis = int((time - int(time)) * 100)
	time_label.text = "Your Time: %02d:%02d.%02d" % [mins, secs, millis]
	
	GlobalSnaketower.pause_time()
	
	var place = _calculate_place(time)
	GameGlobal.set_minigame_finish_place("snake_tower", place)
	
	_generate_leaderboard(place, time)

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

func _create_entry(rank: String, username: String, time_str: String, is_player: bool = false):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	
	var rank_label = Label.new()
	rank_label.text = rank
	rank_label.custom_minimum_size = Vector2(60, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	var name_label = Label.new()
	name_label.text = username
	name_label.custom_minimum_size = Vector2(200, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var time_lbl = Label.new()
	time_lbl.text = time_str
	time_lbl.custom_minimum_size = Vector2(100, 0)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	if is_player:
		var color = Color(1.0, 0.8, 0.2) # Gold for player
		rank_label.add_theme_color_override("font_color", color)
		name_label.add_theme_color_override("font_color", color)
		time_lbl.add_theme_color_override("font_color", color)
	
	hbox.add_child(rank_label)
	hbox.add_child(name_label)
	hbox.add_child(time_lbl)
	
	leaderboard_list.add_child(hbox)

func _create_separator():
	var label = Label.new()
	label.text = "..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_list.add_child(label)

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
	
	for i in range(player_place + 1, player_place + 4):
		var t = player_time + randf_range(5.0, 20.0) * (i - player_place)
		_create_entry(str(i) + ".", dummy_names[name_idx], _format_time(t))
		name_idx += 1
		
	if player_place < 9997:
		_create_separator()
