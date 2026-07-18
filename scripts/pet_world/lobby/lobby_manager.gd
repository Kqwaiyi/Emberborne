extends Node2D

signal scene_opened

const FloatingHeart = preload("res://scripts/pet_world/lobby/floating_heart.gd")

const PET_DATA := {
	"cat": {
		"name":        "Mochi",
		"species":     "Cat",
		"icon":        "🐱",
		"description": "A sleepy but affectionate cat\nwho loves warm spots and snacks.",
		"level":       3,
		"happiness":   72,
		"icon_color":  Color(0.96, 0.80, 0.52),
	},
	"snake": {
		"name":        "Noodle",
		"species":     "Snake",
		"icon":        "🐍",
		"description": "A curious and gentle snake\nwho enjoys quiet, sunny afternoons.",
		"level":       2,
		"happiness":   60,
		"icon_color":  Color(0.58, 0.82, 0.50),
	},
}

const CLICK_RADIUS := 28.0

@onready var _cat             : Node              = $Cat
@onready var _snake           : Node              = $Snake
@onready var _panel           : PetInfoPanel      = $PetInfoPanel
@onready var _cat_pet_audio   : AudioStreamPlayer = $CatPetAudio
@onready var _snake_hiss_audio: AudioStreamPlayer = $SnakeHissAudio

var _selected_key    := ""
var _selected_sprite : AnimatedSprite2D = null
var _glow_sprite     : AnimatedSprite2D = null
var _pulse_t         := 0.0

func _ready() -> void:
	if GameGlobal and GameGlobal.has_method("_on_lobby_scene_opened"):
		scene_opened.connect(GameGlobal._on_lobby_scene_opened)
	scene_opened.emit()
	MusicManager.play_music("pet_world")
	_panel.pet_action_requested.connect(_on_pet_action)

func _process(delta: float) -> void:
	_pulse_t += delta * 2.2
	if is_instance_valid(_glow_sprite) and _selected_sprite:
		_glow_sprite.animation = _selected_sprite.animation
		_glow_sprite.frame     = _selected_sprite.frame
		_glow_sprite.flip_h    = _selected_sprite.flip_h
		_glow_sprite.modulate.a = 0.48 + 0.28 * sin(_pulse_t)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mpos := get_global_mouse_position()

	if mpos.distance_to(_cat.global_position) <= CLICK_RADIUS:
		_select("cat", _cat)
		get_viewport().set_input_as_handled()
	elif mpos.distance_to(_snake.global_position) <= CLICK_RADIUS:
		_select("snake", _snake)
		get_viewport().set_input_as_handled()
	else:
		_deselect()

func _select(key: String, pet: Node) -> void:
	if _selected_key == key:
		return
	_selected_key = key
	_apply_glow(pet)
	_panel.show_pet(PET_DATA[key], pet)

func _deselect() -> void:
	if _selected_key == "":
		return
	_selected_key = ""
	_remove_glow()
	_panel.hide_panel()

func _apply_glow(pet: Node) -> void:
	_remove_glow()
	_selected_sprite = pet.get_node_or_null("AnimatedSprite2D")
	if not _selected_sprite:
		return
	_glow_sprite = AnimatedSprite2D.new()
	_glow_sprite.name          = "_SelectionGlow"
	_glow_sprite.sprite_frames = _selected_sprite.sprite_frames
	_glow_sprite.position      = _selected_sprite.position
	_glow_sprite.scale         = _selected_sprite.scale * 1.10
	_glow_sprite.modulate      = Color(1.0, 0.86, 0.30, 0.58)
	_glow_sprite.z_index       = _selected_sprite.z_index - 1
	_glow_sprite.play(_selected_sprite.animation)
	pet.add_child(_glow_sprite)

func _remove_glow() -> void:
	if is_instance_valid(_glow_sprite):
		_glow_sprite.queue_free()
	_glow_sprite     = null
	_selected_sprite = null

func _on_pet_action(pet_node: Node) -> void:
	var heart := FloatingHeart.new()
	heart.position = pet_node.global_position + Vector2(0.0, -32.0)
	add_child(heart)
	match _selected_key:
		"cat":   _cat_pet_audio.play()
		"snake": _snake_hiss_audio.play()
