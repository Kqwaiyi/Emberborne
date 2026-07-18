extends Node

var time_elapsed: float = 0.0
var duration: float = 2.0
var transitioned: bool = false

func _ready() -> void:
	if GameGlobal:
		GameGlobal.advance_story_state(GameGlobal.StoryState.PHASE1_EXPOSITION)

func _process(delta: float) -> void:
	if transitioned:
		return
	
	time_elapsed += delta
	if time_elapsed >= duration:
		transitioned = true
		if GameGlobal:
			GameGlobal.advance_story_state(GameGlobal.StoryState.PHASE1_APARTMENT)
		if SceneManager:
			SceneManager.change_scene_to_file("res://scenes/scifi_home/the_home/map.tscn", 1.0)
