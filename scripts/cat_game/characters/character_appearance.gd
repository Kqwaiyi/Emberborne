## scripts/characters/character_appearance.gd
## A saveable data object that stores one character's variant choices.
## Save instances of this as .tres files to create named presets
## (e.g. appearance_default.tres, appearance_fancy.tres).
## Apply to a LayeredCharacter node by calling apply_appearance(resource).
class_name CharacterAppearance
extends Resource

## Index into LayeredCharacter.outfit_variants (0 = first outfit).
@export var outfit_index: int = 0

## Index into LayeredCharacter.hair_variants (0 = first hair style).
@export var hair_index: int = 0

## Index into LayeredCharacter.hat_variants.
## Set to -1 to hide the hat layer entirely (no hat).
@export var hat_index: int = -1
