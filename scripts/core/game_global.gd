extends Node


## USER DEFINED GAMESTATE. DO NOT TOUCH
enum StoryState {
	NONE,
	PHASE1_EXPOSITION,
	PHASE1_APARTMENT,
	PHASE1_TASK_CHECK_HOLOGRAM,
	PHASE1_IRSMAIN1,
	PHASE1_IRSDIALOGUE1,
	PHASE1_IRSMAIN2,
	PHASE1_IRSDIALOGUE2,
	PHASE1_IRSMAIN3,
	PHASE1_IRSDIALOGUE3,
	PHASE1_IRSMAIN4,
	PHASE1_IRSDIALOGUE4,
	PHASE1_TASK_GO_TO_PET_WORLD,

	PHASE2_PETWORLD_ENTRY,
	PHASE2_TASK_GO_TO_MESSENGER,

	PHASE3_LOANCHAT1,
	PHASE3_LOANDIALOGUE1,
	PHASE3_LOANCHAT2,
	PHASE3_LOANDIALOGUE2,

	PHASE4_DOOR,
	PHASE4_TASK_GO_TO_PET_WORLD_,
	PHASE4_TASK_JOIN_TOURNAMENT
}

var current_story_state: StoryState = StoryState.NONE
signal story_state_changed(new_state: StoryState)

var minigame_finishes: Dictionary = {}
var snaketower_final_place: int = 0
var cat_game_final_place: int = 0

func _ready() -> void:
	if DialogueManager:
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	if TaskManager:
		TaskManager.task_acknowledged.connect(_on_task_acknowledged)
	# CutsceneMessenger signal is handled by calling GameGlobal._on_cutscene_completed directly

func set_minigame_finish_place(minigame_name: String, place: int) -> void:
	minigame_finishes[minigame_name] = place

func get_minigame_finish_place(minigame_name: String) -> int:
	return minigame_finishes.get(minigame_name, 0)

# --- Story Orchestration ---

func advance_story_state(new_state: StoryState) -> void:
	if current_story_state == new_state:
		return
	
	current_story_state = new_state
	story_state_changed.emit(new_state)
	_handle_state_entry(new_state)

func _on_lobby_scene_opened() -> void:
	if current_story_state == StoryState.PHASE1_TASK_GO_TO_PET_WORLD:
		_advance_with_delay(StoryState.PHASE2_PETWORLD_ENTRY)
	elif current_story_state == StoryState.PHASE4_TASK_GO_TO_PET_WORLD_:
		_advance_with_delay(StoryState.PHASE4_TASK_JOIN_TOURNAMENT)

func _advance_with_delay(new_state: StoryState, delay: float = 0.8) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	advance_story_state(new_state)

func _handle_state_entry(state: StoryState) -> void:
	match state:
		StoryState.PHASE1_APARTMENT:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase1_apartment.gd")
		StoryState.PHASE1_TASK_CHECK_HOLOGRAM:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Use the S62 Hologram to send her a message.")
		StoryState.PHASE1_IRSMAIN1:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase1_irschat1")
		StoryState.PHASE1_IRSDIALOGUE1:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase1_irsdialogue1.gd")
		StoryState.PHASE1_IRSMAIN2:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase1_irschat2")
		StoryState.PHASE1_IRSDIALOGUE2:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase1_irsdialogue2.gd")
		StoryState.PHASE1_IRSMAIN3:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase1_irschat3")
		StoryState.PHASE1_IRSDIALOGUE3:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase1_irsdialogue3.gd")
		StoryState.PHASE1_IRSMAIN4:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase1_irschat4")
		StoryState.PHASE1_IRSDIALOGUE4:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase1_irsdialogue4.gd")
		StoryState.PHASE1_TASK_GO_TO_PET_WORLD:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Click X at the top right corner, reopen the hologram display, and go to the pet world.")
		StoryState.PHASE2_PETWORLD_ENTRY:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase2_petworlddialogue.gd")
		StoryState.PHASE2_TASK_GO_TO_MESSENGER:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Go to messenger")
		StoryState.PHASE3_LOANCHAT1:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase3_loanchat1")
		StoryState.PHASE3_LOANDIALOGUE1:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase3_loandialogue1.gd")
		StoryState.PHASE3_LOANCHAT2:
			if CutsceneMessenger: CutsceneMessenger.queue_cutscene("phase3_loanchat2")
		StoryState.PHASE3_LOANDIALOGUE2:
			if DialogueManager: DialogueManager.start_dialogue("res://scenes/ui/dialogues/phase3_loandialogue2.gd")
		StoryState.PHASE4_DOOR:
			if SceneManager:
				SceneManager.change_scene_to_file("res://scenes/scifi_home/the_home/map.tscn", 2.0)
				await SceneManager.transition_finished
				await get_tree().create_timer(1.0).timeout
				advance_story_state(StoryState.PHASE4_TASK_GO_TO_PET_WORLD_)
		StoryState.PHASE4_TASK_GO_TO_PET_WORLD_:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Open your hologram and head to the pet world")
		StoryState.PHASE4_TASK_JOIN_TOURNAMENT:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Choose (click on) a pet and click join tournament")

func _on_dialogue_finished(_file_path: String) -> void:
	match current_story_state:
		StoryState.PHASE1_APARTMENT:
			_advance_with_delay(StoryState.PHASE1_TASK_CHECK_HOLOGRAM)
		StoryState.PHASE1_IRSDIALOGUE1:
			_advance_with_delay(StoryState.PHASE1_IRSMAIN2)
		StoryState.PHASE1_IRSDIALOGUE2:
			_advance_with_delay(StoryState.PHASE1_IRSMAIN3)
		StoryState.PHASE1_IRSDIALOGUE3:
			_advance_with_delay(StoryState.PHASE1_IRSMAIN4)
		StoryState.PHASE1_IRSDIALOGUE4:
			_advance_with_delay(StoryState.PHASE1_TASK_GO_TO_PET_WORLD)
		StoryState.PHASE2_PETWORLD_ENTRY:
			_advance_with_delay(StoryState.PHASE2_TASK_GO_TO_MESSENGER)
		StoryState.PHASE3_LOANDIALOGUE1:
			_advance_with_delay(StoryState.PHASE3_LOANCHAT2)
		StoryState.PHASE3_LOANDIALOGUE2:
			_advance_with_delay(StoryState.PHASE4_DOOR)

func _on_cutscene_completed(key: String) -> void:
	match current_story_state:
		StoryState.PHASE1_IRSMAIN1:
			if key == "phase1_irschat1":
				_advance_with_delay(StoryState.PHASE1_IRSDIALOGUE1)
		StoryState.PHASE1_IRSMAIN2:
			if key == "phase1_irschat2":
				_advance_with_delay(StoryState.PHASE1_IRSDIALOGUE2, 1.5)
		StoryState.PHASE1_IRSMAIN3:
			if key == "phase1_irschat3":
				_advance_with_delay(StoryState.PHASE1_IRSDIALOGUE3, 1.5)
		StoryState.PHASE1_IRSMAIN4:
			if key == "phase1_irschat4":
				_advance_with_delay(StoryState.PHASE1_IRSDIALOGUE4, 1.5)
		StoryState.PHASE3_LOANCHAT1:
			if key == "phase3_loanchat1":
				_advance_with_delay(StoryState.PHASE3_LOANDIALOGUE1)
		StoryState.PHASE3_LOANCHAT2:
			if key == "phase3_loanchat2":
				_advance_with_delay(StoryState.PHASE3_LOANDIALOGUE2)

func _on_task_acknowledged() -> void:
	match current_story_state:
		StoryState.PHASE1_TASK_CHECK_HOLOGRAM:
			_advance_with_delay(StoryState.PHASE1_IRSMAIN1)
		StoryState.PHASE2_TASK_GO_TO_MESSENGER:
			_advance_with_delay(StoryState.PHASE3_LOANCHAT1)
