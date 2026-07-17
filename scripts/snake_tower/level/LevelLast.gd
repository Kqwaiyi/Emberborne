extends Control

@onready var time_label = $CenterContainer/VBoxContainer/TimeLabel

func _ready():
	var time = Globals.total_time_elapsed
	var mins = int(time) / 60
	var secs = int(time) % 60
	var millis = int((time - int(time)) * 100)
	time_label.text = "Your Time: %02d:%02d.%02d" % [mins, secs, millis]
	
	Globals.pause_time()
