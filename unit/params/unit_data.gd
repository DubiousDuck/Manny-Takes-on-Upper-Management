extends Resource

class_name UnitData

## a unit's ID is assigned at runtime and is used to identify a specific Unit throughout saves
@export var id:int

@export var level: int = 1
@export var exp: int = 0

# Battle related
## Identifer of the Class; each Class corresponds to a unique UnitData template
@export_enum("Protagonist", "Tank", "Fighter", 
	"Ranger", "Healer", "Mage", "Boss 1", "Boss 2", "CTO", "CFO", "CEO", "Turret") var unit_class: String

enum STAT {HP, ATK, MAG, MOV, DMG_RED}
@export var stat: Dictionary[STAT, float] = {
	STAT.HP: 4,
	STAT.ATK: 2,
	STAT.MAG: 2,
	STAT.MOV: 2,
	STAT.DMG_RED: 0
}
## Stat grwoth table of a unit; should be set manually for each base class resource; format-- level: stats gained
@export var stat_growth_table: Dictionary[int, Dictionary] = {
	2: {STAT.HP: 2},
	3: {STAT.ATK: 1, STAT.MAG: 1},
	4: {STAT.HP: 2},
	5: {STAT.HP: 3},
	6: {STAT.HP: 3},
	7: {STAT.ATK: 1, STAT.MAG: 1},
	8: {STAT.HP: 3},
	9: {STAT.HP: 4},
	10: {STAT.ATK: 1, STAT.MAG: 1},
	11: {STAT.HP: 4},
	12: {STAT.ATK: 1, STAT.MAG: 1},
	13: {STAT.HP: 4},
	15: {STAT.HP: 4, STAT.ATK: 1, STAT.MAG: 1},
	16: {STAT.ATK: 1, STAT.MAG: 1},
	17: {STAT.HP: 4},
	18: {STAT.MAG: 1},
	19: {STAT.ATK: 1},
	20: {STAT.HP: 4, STAT.ATK: 1, STAT.MAG: 1}
}

@export var skill_list: Array[SkillInfo] = []

## Skill unlock table of a unit; should be set manually for each base class resource
@export var skill_table: Dictionary[int, SkillInfo] = {}

func get_stat(name):
	match name:
		"HP": return stat[STAT.HP]
		"ATK": return stat[STAT.ATK]
		"MAG": return stat[STAT.MAG]
		"MOV": return stat[STAT.MOV]
		"DMG_RED": return stat[STAT.DMG_RED]

func _set_stat(delta: Array[float] = [4, 2, 2, 2, 0]):
	stat[STAT.HP] = delta[STAT.HP]
	stat[STAT.ATK] = delta[STAT.ATK]
	stat[STAT.MAG] = delta[STAT.MAG]
	stat[STAT.MOV] = delta[STAT.MOV]
	stat[STAT.DMG_RED] = delta[STAT.DMG_RED]

# level related
func gain_exp(amount: int):
	print("gaining %d exp... -- UnitData.gd" %amount)
	exp += amount
	while exp >= exp_to_next_level():
		exp -= exp_to_next_level()
		level_up()

func exp_to_next_level() -> int:
	return 4 + (level - 1) * 2 # test curve

func level_up():
	level += 1
	print("Level up! The unit is now level %d." % level)
	if stat_growth_table.has(level):
		for stat_enum in stat_growth_table[level].keys():
			stat[stat_enum] += stat_growth_table[level][stat_enum]
			print("unit gained %d in %d!" %[stat_growth_table[level][stat_enum], stat_enum])
	if skill_table.has(level):
		skill_list.append(skill_table[level])

func check_skill_unlock(level: int):
	return skill_table.get(level, null)

# Item related
@export var item_list: Array[ItemData] = []

func add_item(item: ItemData):
	item_list.append(item)

func remove_item(item: ItemData):
	item_list.erase(item)

# Saving and loading related
func to_dict() -> Dictionary:
	return {
		"id": id,
		"level": level,
		"exp": exp,
		"unit_class": unit_class,
		"stat": stat,
		"skill_list": skill_list.map(func(skill): return skill.name), # or skill ID
		"item_list": item_list.map(func(item): return item.item_name)     # or item ID
	}

static func new_from_dict(data: Dictionary) -> UnitData:
	var unit = UnitDatabase.get_by_class(data.get("unit_class", "Fighter"))
	unit.id = data.get("id", 0)
	unit.unit_class = data.get("unit_class", "Fighter")
	unit.exp = data.get("exp", 0)
	
	# Handles the stat growth and skill learned through leveling up
	var target_level = data.get("level", 1)
	while unit.level < target_level: # assumes unit.level == 1 when init
		unit.level_up()

	unit.item_list.clear()
	for item_name in data.get("item_list", []):
		unit.item_list.append(ItemDatabase.get_by_name(item_name))

	return unit
