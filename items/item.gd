extends Resource

class_name ItemData

@export var item_name: String
@export_multiline var description: String
@export var icon: Texture2D

enum EffectType{ATTACK_UP, DEFENSE_UP, HP_UP, MOV_UP, UNLOCK_SKILL}

## The list of effect this item has; should be in the format of enum (int) keys and Variant values
@export var effect_dict: Dictionary[EffectType, Variant]
