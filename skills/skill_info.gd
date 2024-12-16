extends Resource

class_name SkillInfo

enum EffectType {DAMAGE, KNOCKBACK, HEAL, BUFF, DEBUFF, STUN, ACTION_COMMAND}

@export_category("Basic Info")
@export var name: String
@export_enum("attack", "skill", "passive") var type
@export_enum("allies", "enemies", "self") var targets
@export_range(0, 10) var range: int

@export_category("Skill Detail")
@export var skill_effects: Array[Vector2i] #Structure --> Vector2i(EffectType, Value)
