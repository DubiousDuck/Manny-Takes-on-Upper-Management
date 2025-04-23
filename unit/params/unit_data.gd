extends Resource

class_name UnitData

#Battle related
@export var id:int
@export_enum("Protagonist", "Tank", "Fighter", 
	"Ranger", "Healer", "Mage", "Boss") var unit_class: String

enum ATTRIBUTES {HP, ATK, MAG, MOV}
@export var attributes: Dictionary = {
	ATTRIBUTES.HP: 2,
	ATTRIBUTES.ATK: 1,
	ATTRIBUTES.MAG: 1,
	ATTRIBUTES.MOV: 2
}

@export var skill_list: Array[SkillInfo] = []

func get_attribute(name):
	match name:
		"HP": return attributes[ATTRIBUTES.HP]
		"ATK": return attributes[ATTRIBUTES.ATK]
		"MAG": return attributes[ATTRIBUTES.MAG]
		"MOV": return attributes[ATTRIBUTES.MOV]

func _set_attributes(delta: Array[int]):
	attributes[ATTRIBUTES.HP] = delta[ATTRIBUTES.HP]
	attributes[ATTRIBUTES.ATK] = delta[ATTRIBUTES.ATK]
	attributes[ATTRIBUTES.MAG] = delta[ATTRIBUTES.MAG]
	attributes[ATTRIBUTES.MOV] = delta[ATTRIBUTES.MOV]

# Item related
@export var item_list: Array[ItemData] = []

func add_item(item: ItemData):
	item_list.append(item)

func remove_item(item: ItemData):
	item_list.erase(item)
