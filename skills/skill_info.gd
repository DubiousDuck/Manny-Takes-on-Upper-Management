extends Resource

class_name SkillInfo

enum EffectType {DAMAGE, KNOCKBACK, HEAL, BUFF, DEBUFF, STUN, ACTION_COMMAND, WAIT}
#DAMAGE = 0, KNOCKBACK = 1, HEAL = 2, BUFF = 3, DEBUFF = 4, STUN = 5, ACTION_COMMAND = 6, WAIT = 7

enum TargetType {ALLIES, ENEMIES, SELF, ANY}

@export_category("Basic Info")
@export var name: String
@export_enum("attack", "skill", "passive") var type
@export_enum("allies", "enemies", "self", "any") var targets
@export_range(0, 10) var range: int

@export_category("Skill Detail")
@export var skill_effects: Array[Vector2i] #Structure --> Vector2i(EffectType, Value)
