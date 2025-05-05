extends Control

class_name UnitPreview

@onready var class_label = $Class
@onready var hp_label = $GridContainer/HP
@onready var mov_label = $GridContainer/MOV
@onready var atk_label = $GridContainer/ATK
@onready var mag_label = $GridContainer/MAG

var cur_unit : Unit

var hp: int:
	set(value):
		hp = value
		hp_label.text = str(hp)
		if hp > cur_unit.unit_data.get_attribute("HP"):
			hp_label.modulate = Color("0ac863")
var mov: int:
	set(value):
		mov = value
		mov_label.text = str(mov)
		if mov > cur_unit.unit_data.get_attribute("MOV"):
			mov_label.modulate = Color("0ac863")
var atk: int:
	set(value):
		atk = value
		atk_label.text = str(atk)
		if atk > cur_unit.unit_data.get_attribute("ATK"):
			atk_label.modulate = Color("0ac863")
var mag: int:
	set(value):
		mag = value
		mag_label.text = str(mag)
		if mag > cur_unit.unit_data.get_attribute("MAG"):
			mag_label.modulate = Color("0ac863")
	
func init(unit: Unit):
	cur_unit = unit
	#set sprite 2d to corresponding class
	class_label.text = unit.unit_data.unit_class
	hp = unit.max_health
	mov = unit.movement_range
	atk = unit.attack_power
	mag = unit.magic_power
