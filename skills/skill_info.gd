extends Resource

class_name SkillInfo

enum EffectType {DAMAGE, KNOCKBACK, HEAL, BUFF, DEBUFF, STATUS, ACTION_COMMAND, WAIT, DISPLACE, SET_TILE}
#DAMAGE = 0, KNOCKBACK = 1, HEAL = 2, BUFF = 3, DEBUFF = 4, STATUS = 5, ACTION_COMMAND = 6, WAIT = 7, DISPLACE = 8, SET_TILE = 9
enum TargetType {ALLIES, ENEMIES, SELF, ANY_UNIT, EXCEPT_SELF, ALLIES_EXCEPT_SELF, ANY_CELL, ANY_CELL_EXCEPT_SELF, ANY_CELL_EXCEPT_ALLIES}
#ALLIES = 0, ENEMIES = 1, SELF = 2, ANY_UNIT = 3, EXCEPT_SELF = 4, ALLIES_EXCEPT_SELF = 5, ANY_CELL = 6, ANY_CELL_EXCEPT_SELF = 7, ANY_CELL_EXCEPT_ALLIES


@export_category("Basic Info")
@export var name: String
@export_multiline var description: String = ""
@export_enum("Attack", "Skill", "Other") var type: String = "Attack"
@export var targets: TargetType
@export_enum("physical", "magic") var affinity
@export_range(0, 10) var range: int
@export_range(-10, 10) var area: int = 0 #negative area covers the same as positive but excludes origin

@export_category("Skill Detail")
# special skill effect structure:
# buff, debuffs: path to BonusStat resource (aka String)
# status effect: status effect object
@export var skill_effects: Dictionary[EffectType, Variant] = {}
@export var effect_execution_order: Array[EffectType] = []
