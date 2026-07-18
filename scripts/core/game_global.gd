extends Node


## USER DEFINED GAMESTATE. DO NOT TOUCH
enum StoryState {
	NONE,
	PHASE1_EXPOSITION, # Black screen exposition
	PHASE1_APARTMENT, # Dialogue: "Finally... 12 hours..."
	PHASE1_TASK_CHECK_HOLOGRAM, # Task: "Use the S62 Hologram..."
	PHASE1_IRSMAIN1, # Chat with Immediate Response System
	PHASE1_IRSDIALOGUE1,
	PHASE1_IRSMAIN2,
	PHASE1_IRSDIALOGUE2,
	PHASE1_IRSMAIN3,
	PHASE1_IRSDIALOGUE3,
	PHASE1_IRSMAIN4,
	PHASE1_IRSDIALOGUE4,
	PHASE1_TASK_GO_TO_PET_WORLD, # Prompts player to check petworld

	PHASE2_PETWORLD_ENTRY, # Enters the petworld
	PHASE2_TASK_GO_TO_MESSENGER, # Prompts player to check messenger

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

func _handle_state_entry(state: StoryState) -> void:
	match state:
		StoryState.TASK_CHECK_HOLOGRAM:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Use the S62 Hologram to send her a message.")
		StoryState.CUTSCENE_ARS_EMERGENCY:
			CutsceneMessenger.queue_cutscene("ars_emergency")
		StoryState.TASK_GO_TO_PET_WORLD:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Terminate the conversation and go to the pet world.")
		StoryState.TASK_CHECK_MESSENGER:
			if TaskManager: TaskManager.show_task("NEW NOTIFICATION", "Go to messenger to check your loan.")
			CutsceneMessenger.queue_cutscene("loan_bot")
		StoryState.TASK_GO_TO_PET_WORLD_2:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Open your hologram and head to the pet world.")
		StoryState.TASK_JOIN_TOURNAMENT:
			if TaskManager: TaskManager.show_task("NEW DIRECTIVE", "Choose a pet and 'join tournament'.")

func _on_dialogue_finished(file_path: String) -> void:
	match current_story_state:
		StoryState.SCENE_1_APARTMENT_INTRO:
			advance_story_state(StoryState.TASK_CHECK_HOLOGRAM)
		StoryState.SCENE_1_PET_WORLD_DIALOGUE:
			advance_story_state(StoryState.TASK_CHECK_MESSENGER)
		StoryState.SCENE_2_DOOR:
			advance_story_state(StoryState.TASK_GO_TO_PET_WORLD_2)

func _on_cutscene_completed(key: String) -> void:
	match current_story_state:
		StoryState.CUTSCENE_ARS_EMERGENCY:
			if key == "ars_emergency":
				advance_story_state(StoryState.TASK_GO_TO_PET_WORLD)
		StoryState.CUTSCENE_LOAN_BOT:
			if key == "loan_bot":
				advance_story_state(StoryState.SCENE_2_DOOR)

func _on_task_acknowledged() -> void:
	pass
