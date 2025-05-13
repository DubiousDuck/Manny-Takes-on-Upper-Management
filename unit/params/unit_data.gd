extends Resource

class_name UnitData

@export var id:int

@export var level: int = 1
@export var exp: int = 0

# Battle related
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
	7: {STAT.ATK: 1, STAT.MAG: 1}
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

func _set_stat(delta: Array[int]):
	stat[STAT.HP] = delta[STAT.HP]
	stat[STAT.ATK] = delta[STAT.ATK]
	stat[STAT.MAG] = delta[STAT.MAG]
	stat[STAT.MOV] = delta[STAT.MOV]

# level related
func gain_exp(amount: int):
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
	level = 1
	while level < num:
		level_up()

# Item related
@export var item_list: Array[ItemData] = []

func add_item(item: ItemData):
	item_list.append(item)

func remove_item(item: ItemData):
	item_list.erase(item)
