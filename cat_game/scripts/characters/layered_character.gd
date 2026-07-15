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
## Cat layers also need: idle_1  idle_2  (enemies can omit these)
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

## Speed at or above this switches walk → run (only applies when set_force_run
## has NOT been called with true — force_run overrides this threshold).
@export var run_threshold: float = 160.0

## Seconds of stillness before a random idle animation plays.
## Set to 0 to disable idle entirely (useful for enemies).
@export var idle_delay: float = 1.0

# ── Layer node references ──────────────────────────────────────────────────────
@onready var _base:   AnimatedSprite2D = $LayerBase
@onready var _outfit: AnimatedSprite2D = $LayerOutfit
@onready var _hair:   AnimatedSprite2D = $LayerHair
@onready var _hat:    AnimatedSprite2D = $LayerHat

var _current_anim: String  = ""
var _last_h_dir: String    = "right"
var _force_run: bool       = false
var _stopped_time: float   = 0.0

func _ready() -> void:
	set_outfit(starting_outfit)
	set_hair(starting_hair)
	set_hat(starting_hat)
	_stop_all()

func _process(delta: float) -> void:
	# Idle timer — only counts while the character is standing still.
	if idle_delay > 0.0 and (_current_anim == "" or _current_anim.begins_with("idle_")):
		_stopped_time += delta
		if _stopped_time >= idle_delay and _current_anim == "":
			_pick_random_idle()

# ── Public interface ───────────────────────────────────────────────────────────

## Called every physics frame by cat.gd / enemy_base.gd.
func update_direction(vel: Vector2) -> void:
	if vel.length_squared() < 100.0:
		# Stopped — freeze on last frame and let the idle timer count up.
		if not (_current_anim == "" or _current_anim.begins_with("idle_")):
			_current_anim = ""
			_stop_all()
		return

	# Moving — reset idle timer.
	_stopped_time = 0.0

	# Track horizontal direction; fall back to last known when moving vertically.
	if abs(vel.x) > 10.0:
		_last_h_dir = "right" if vel.x > 0.0 else "left"

	var is_running: bool  = _force_run or vel.length() >= run_threshold
	var prefix: String    = "run_" if is_running else "walk_"
	var anim: String      = _resolve_anim(prefix + _last_h_dir)

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

## Force run animations on (true) or off (false) regardless of velocity.
## cat.gd calls this during the speed-boost window after being tagged.
## enemy_base.gd calls this when anger reaches 60 %.
func set_force_run(enabled: bool) -> void:
	if _force_run == enabled:
		return
	_force_run = enabled
	# Re-evaluate the current animation immediately so the switch is instant.
	if _current_anim != "" and not _current_anim.begins_with("idle"):
		var prefix: String = "run_" if _force_run else "walk_"
		var anim: String   = _resolve_anim(prefix + _last_h_dir)
		if anim != _current_anim:
			_current_anim = anim
			_play_all(anim)

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

# ── Internals ──────────────────────────────────────────────────────────────────

func _pick_random_idle() -> void:
	if _base.sprite_frames == null:
		return
	var n: int    = randi_range(1, 2)
	var anim: String = "idle_" + str(n)
	if not _base.sprite_frames.has_animation(anim):
		return
	_current_anim = anim
	_play_all(anim)

## If the requested animation doesn't exist on the base layer, fall back to
## the walk equivalent. This lets characters without run frames (e.g. human)
## simply omit them from their SpriteFrames — walk plays automatically.
func _resolve_anim(anim: String) -> String:
	if _base.sprite_frames == null:
		return anim
	if _base.sprite_frames.has_animation(anim):
		return anim
	if anim.begins_with("run_"):
		var fallback: String = "walk_" + anim.substr(4)
		if _base.sprite_frames.has_animation(fallback):
			return fallback
	return anim

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
