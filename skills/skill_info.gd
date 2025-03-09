extends Resource

class_name SkillInfo

enum EffectType {DAMAGE, KNOCKBACK, HEAL, BUFF, DEBUFF, STUN, ACTION_COMMAND, WAIT, DISPLACE, DAMAGE_REDUCTION, SET_TILE}
#DAMAGE = 0, KNOCKBACK = 1, HEAL = 2, BUFF = 3, DEBUFF = 4, STUN = 5, ACTION_COMMAND = 6, WAIT = 7, DISPLACE = 8, DAMAGE_REDUCTION = 9, SET_TILE = 10
enum TargetType {ALLIES, ENEMIES, SELF, ANY_UNIT, EXCEPT_SELF, ALLIES_EXCEPT_SELF, ANY_CELL, ANY_CELL_EXCEPT_SELF}
#ALLIES = 0, ENEMIES = 1, SELF = 2, ANY_UNIT = 3, EXCEPT_SELF = 4, ALLIES_EXCEPT_SELF = 5, ANY_CELL = 6, ANY_CELL_EXCEPT_SELF = 7


@export_category("Basic Info")
@export var name: String
@export_enum("attack", "skill", "passive") var type
@export_enum("allies", "enemies", "self", "any_unit", 
"except_self", "allies_except_self", "any_cell", "any_cell_except_self") var targets
@export_enum("physical", "magic") var affinity
@export_range(0, 10) var range: int
@export_range(-10, 10) var area: int = 0 #negative area covers the same as positive but excludes origin

@export_category("Skill Detail")
@export var skill_effects: Array[Vector2i] #Structure --> Vector2i(EffectType, Value)
