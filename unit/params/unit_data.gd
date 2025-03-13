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

#Non-player units only
@export_category("Non-Player Unit")
@export_enum("Hostile", "Resentful", 
	"Indifferent", "Respectful", "Loyal") var rel: String
@export_range(-50, 50) var mood: int = 50

@export_category("Protagonist Only")
#Protagonist only
@export var money: int = 5 #TODO: move to save file perhaps

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
#
#@export var unique_id: int
#func _init():
	#unique_id = generate_unique_id()
#static var next_unique_id = 0
#static func generate_unique_id() -> int:
	#next_unique_id += 1
	#return next_unique_id
