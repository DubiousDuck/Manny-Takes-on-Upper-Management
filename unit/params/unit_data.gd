extends Resource

class_name UnitData

## a unit's ID is assigned at runtime and is used to identify a specific Unit throughout saves
@export var id:int

@export var level: int = 1
@export var exp: int = 0

# Battle related
## Identifer of the Class; each Class corresponds to a unique UnitData template
@export_enum("Protagonist", "Tank", "Fighter", 
	"Ranger", "Healer", "Mage", "Boss") var unit_class: String

enum STAT {HP, ATK, MAG, MOV}
@export var stat: Dictionary[STAT, int] = {
	STAT.HP: 4,
	STAT.ATK: 2,
	STAT.MAG: 2,
	STAT.MOV: 2
}
## Stat grwoth table of a unit; should be set manually for each base class resource; format-- level: stats gained
@export var stat_growth_table: Dictionary[int, Dictionary] = {
	2: {STAT.HP: 1},
	3: {STAT.ATK: 1},
	4: {STAT.MAG: 1},
	5: {STAT.HP: 2},
	7: {STAT.ATK: 1, STAT.MAG: 1},
	8: {STAT.HP: 1},
	9: {STAT.ATK: 1, STAT.MAG: 1},
	10: {STAT.HP: 2},
	12: {STAT.ATK: 2},
	13: {STAT.MAG: 2},
	15: {STAT.HP: 1, STAT.ATK: 1, STAT.MAG: 1},
	16: {STAT.ATK: 1, STAT.MAG: 1},
	17: {STAT.HP: 2},
	18: {STAT.MAG: 2},
	19: {STAT.ATK: 2},
	20: {STAT.HP: 1, STAT.ATK: 1, STAT.MAG: 1}
}

@export var skill_list: Array[SkillInfo] = []

## Skill unlock table of a unit; should be set manually for each base class resource
@export var skill_table: Dictionary[int, SkillInfo] = {}

## Variable to prevent repeated level ups when reloading a battle scene
var leveled_up: bool = false

func get_stat(name):
	match name:
		"HP": return stat[STAT.HP]
		"ATK": return stat[STAT.ATK]
		"MAG": return stat[STAT.MAG]
		"MOV": return stat[STAT.MOV]

func _set_stat(delta: Array[int] = [4, 2, 2, 2]):
	stat[STAT.HP] = delta[STAT.HP]
	stat[STAT.ATK] = delta[STAT.ATK]
	stat[STAT.MAG] = delta[STAT.MAG]
	stat[STAT.MOV] = delta[STAT.MOV]

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
	#print("Level up! The unit is now level %d." % level)
	if stat_growth_table.has(level):
		for stat_enum in stat_growth_table[level].keys():
			stat[stat_enum] += stat_growth_table[level][stat_enum]
	if skill_table.has(level):
		skill_list.append(skill_table[level])

## Set the unit data to a preset level; assumes the UnitData was originally at level 1
func set_self_level(num: int):
	if !leveled_up:
		level = 1
		while level < num:
			level_up()
		leveled_up = true
	else: print("No need to level up as  this resource has already been leveled up before. -- UnitData.gd")

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
		"item_list": item_list.map(func(item): return item.item_name),     # or item ID
		"leveled_up": leveled_up,
	}

static func new_from_dict(data: Dictionary) -> UnitData:
	var unit = UnitDatabase.get_by_class(data.get("unit_class", "Fighter"))
	unit.id = data.get("id", 0)
	unit.unit_class = data.get("unit_class", "Fighter")
	unit.level = data.get("level", 1)
	unit.exp = data.get("exp", 0)
	
	# Rebuilding the stat dictionary in a careful way
	var raw_stat = data.get("stat", {})
	for key in raw_stat.keys():
		unit.stat[int(key)] = int(raw_stat[key])
	print("The rebuilt unit stat is: " + str(unit.stat) + " -- unit_data.gd")

	unit.leveled_up = data.get("leveled_up", false)

	unit.skill_list.clear()
	for skill_name in data.get("skill_list", []):
		unit.skill_list.append(SkillInfobase.get_by_name(skill_name))

	unit.item_list.clear()
	for item_name in data.get("item_list", []):
		unit.item_list.append(ItemDatabase.get_by_name(item_name))

	return unit
