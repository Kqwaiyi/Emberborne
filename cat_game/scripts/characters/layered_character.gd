## scripts/characters/layered_character.gd
## Attach to the Visual node INSTEAD of cat_visual.gd when you have real sprite art.
## Exposes the same update_direction() and set_outline() interface so cat.gd and
## enemy_base.gd need zero changes.
##
## Required child AnimatedSprite2D nodes (add them in the editor under Visual):
##   LayerBase   — base body, always visible
##   LayerOutfit — clothing layer (hidden if no outfit_variants)
##   LayerHair   — hair layer
##   LayerHat    — hat layer (hidden when hat_index is -1)
##
## All SpriteFrames resources used here MUST share these animation names:
##   walk_left  walk_right  run_left  run_right
## Same frame count + FPS per animation across all layers so they stay in sync.
class_name LayeredCharacter
extends Node2D

# ── Variant arrays ─────────────────────────────────────────────────────────────
@export var outfit_variants: Array[SpriteFrames] = []
@export var hair_variants:   Array[SpriteFrames] = []
## Index -1 = no hat (layer hidden).
@export var hat_variants:    Array[SpriteFrames] = []

# ── Starting choices ───────────────────────────────────────────────────────────
@export var starting_outfit: int = 0
@export var starting_hair:   int = 0
@export var starting_hat:    int = -1

## Speed at or above this value switches from walk to run animations.
## Tune this to match your cat's normal vs boosted speed.
@export var run_threshold: float = 160.0

# ── Layer node references ──────────────────────────────────────────────────────
@onready var _base:   AnimatedSprite2D = $LayerBase
@onready var _outfit: AnimatedSprite2D = $LayerOutfit
@onready var _hair:   AnimatedSprite2D = $LayerHair
@onready var _hat:    AnimatedSprite2D = $LayerHat

var _current_anim: String = ""
var _last_h_dir: String = "right"   # last known horizontal direction

func _ready() -> void:
	set_outfit(starting_outfit)
	set_hair(starting_hair)
	set_hat(starting_hat)
	_stop_all()   # hold first frame; no idle animation exists

# ── Public interface ───────────────────────────────────────────────────────────

## Called every physics frame by cat.gd / enemy_base.gd.
func update_direction(vel: Vector2) -> void:
	if vel.length_squared() < 100.0:
		# Standing still — freeze on last frame, don't loop.
		if _current_anim != "":
			_current_anim = ""
			_stop_all()
		return

	# Determine left/right.
	# When moving mostly vertically keep the last known horizontal direction
	# so the character doesn't snap to a default.
	if abs(vel.x) > 10.0:
		_last_h_dir = "right" if vel.x > 0.0 else "left"

	var prefix: String = "run_" if vel.length() >= run_threshold else "walk_"
	var anim: String   = prefix + _last_h_dir

	if anim != _current_anim:
		_current_anim = anim
		_play_all(anim)

## Called by cat.gd — tints all layers red during invulnerability, white after.
func set_outline(is_active: bool) -> void:
	var c: Color = Color(1.0, 0.3, 0.3) if is_active else Color.WHITE
	_base.modulate   = c
	_outfit.modulate = c
	_hair.modulate   = c
	_hat.modulate    = c

# ── Variant setters ────────────────────────────────────────────────────────────

func set_outfit(index: int) -> void:
	if index >= 0 and index < outfit_variants.size():
		_outfit.sprite_frames = outfit_variants[index]
		_outfit.visible = true
		_sync_layer_to_base(_outfit)
	else:
		_outfit.visible = false

func set_hair(index: int) -> void:
	if index >= 0 and index < hair_variants.size():
		_hair.sprite_frames = hair_variants[index]
		_hair.visible = true
		_sync_layer_to_base(_hair)
	else:
		_hair.visible = false

func set_hat(index: int) -> void:
	if index < 0 or index >= hat_variants.size():
		_hat.visible = false
		return
	_hat.sprite_frames = hat_variants[index]
	_hat.visible = true
	_sync_layer_to_base(_hat)

## Apply a CharacterAppearance resource in one call.
func apply_appearance(appearance: CharacterAppearance) -> void:
	set_outfit(appearance.outfit_index)
	set_hair(appearance.hair_index)
	set_hat(appearance.hat_index)

# ── Helpers ────────────────────────────────────────────────────────────────────

func _play_all(anim: String) -> void:
	_play_layer(_base,   anim)
	_play_layer(_outfit, anim)
	_play_layer(_hair,   anim)
	_play_layer(_hat,    anim)

func _stop_all() -> void:
	for layer: AnimatedSprite2D in [_base, _outfit, _hair, _hat]:
		if layer.sprite_frames != null:
			layer.stop()

func _play_layer(layer: AnimatedSprite2D, anim: String) -> void:
	if not layer.visible:
		return
	if layer.sprite_frames == null:
		return
	if not layer.sprite_frames.has_animation(anim):
		return
	layer.play(anim)

## Snap a newly-swapped layer to the base layer's current frame immediately.
func _sync_layer_to_base(layer: AnimatedSprite2D) -> void:
	if layer.sprite_frames == null or _current_anim == "":
		return
	if not layer.sprite_frames.has_animation(_current_anim):
		return
	layer.animation = _current_anim
	layer.frame     = _base.frame
	if _base.is_playing():
		layer.play(_current_anim)
	else:
		layer.stop()
