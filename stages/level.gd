extends Node2D

class_name Level

const INTRAVERSABLE_WEIGHT: float = 999

@onready var battle_outcome = preload("res://ui/battle_outcome.tscn")
@onready var pause_canvas_layer = $PauseCanvasLayer

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

func _ready():
	EventBus.connect("battle_ended", _on_battle_ended)
	
	HexNavi.set_current_map(tile_map)
	HexNavi.set_weight_of_layer(INTRAVERSABLE_WEIGHT, "traversable", false)
	
	read_talent_and_apply(Global.talent_type.PROTAG)
	read_talent_and_apply(Global.talent_type.COMPANY)
	
	unit_group_control.init()

func _on_battle_ended(result: int):
	var a = battle_outcome.instantiate()
	a.init(result)
	pause_canvas_layer.add_in_background(a)
	#$PauseCanvasLayer.add_child(a)
	a.display()

func read_talent_and_apply(talent_type: int):
	#read the talent dictionary
	var talent_dict: Dictionary = Global.get_talent_activated(talent_type)
	
	if talent_type == Global.talent_type.PROTAG: #NOTICE: it's required that the protagonist stays at this path
		var protag_node: Unit = get_node_or_null("Units/PlayerGroup/Protag")
		if !protag_node: return # Safety measure
			
		for talent in talent_dict.keys():
			match talent:
				"extra_range":
					protag_node.movement_range += talent_dict["extra_range"]
				"raise_power":
					protag_node.attack_power += talent_dict["raise_power"]
				"raise_magic":
					protag_node.magic_power += talent_dict["raise_magic"]
				"heal_skill":
					var heal: SkillInfo = preload("res://skills/basic_heal.tres")
					protag_node.skills.append(heal)
			
	elif talent_type == Global.talent_type.COMPANY:
		for talent in talent_dict.keys():
			match talent:
				"extra_health":
					#FIXME: EWW Prob not the best way to implement this -- Oscar
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							unit.max_health += talent_dict["extra_health"]
							unit.health += talent_dict["extra_health"]
					)
				"raise_power":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							unit.attack_power += talent_dict["raise_power"]
					)
				"raise_magic":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							unit.magic_power += talent_dict["raise_magic"]
					)
				"arrow_rain":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							if unit.unit_data.unit_class == "Ranger":
								var arrow_rain: SkillInfo = preload("res://skills/arrow_rain.tres")
								unit.skills.append(arrow_rain)
					)
	#for each talent, match its name and apply its effect
