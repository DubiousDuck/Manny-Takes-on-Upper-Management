extends Node2D

class_name Level

const INTRAVERSABLE_WEIGHT: float = 999

@onready var battle_outcome = preload("uid://ct4t683r6jn78")
@onready var pause_canvas_layer = $PauseCanvasLayer

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

@export var inital_exp : int
@export var repeat_exp : int

## Array of of tutorials to show
@export var tutorial_queue: Array[TutorialContent]

func _ready():
	EventBus.connect("battle_ended", _on_battle_ended)
	
	HexNavi.set_current_map(tile_map)
	HexNavi.set_weight_of_layer("traversable", false, INTRAVERSABLE_WEIGHT)
	
	read_talent_and_apply(Global.talent_type.PROTAG)
	read_talent_and_apply(Global.talent_type.COMPANY)
	
	if !tutorial_queue.is_empty():
		Global.start_tutorial(tutorial_queue)
	
	unit_group_control.init()

func _on_battle_ended(result: int):
	##exp gain
	var a = battle_outcome.instantiate()
	a.init(result)
	var num_level_ups : int
	if(result == EventBus.BattleResult.PLAYER_VICTORY):
		#TODO: gain repeat exp if level already beaten
		num_level_ups = Global.gain_exp(inital_exp)
	pause_canvas_layer.add_in_background(a)
	#$PauseCanvasLayer.add_child(a)
	a.display()
	a.animate_exp(Global.current_exp, num_level_ups)

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
					if !(heal in protag_node.skills):
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
							if unit != null and unit.unit_data.unit_class == "Ranger":
								var skill: SkillInfo = preload("res://skills/arrow_rain.tres")
								if !(skill in unit.skills): unit.skills.append(skill)
					)
				"stink_bomb":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							if unit != null and unit.unit_data.unit_class == "Mage":
								var skill: SkillInfo = preload("res://skills/stink_bomb.tres")
								if !(skill in unit.skills): unit.skills.append(skill)
					)
				"throw_candy":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							if unit != null and unit.unit_data.unit_class == "Healer":
								var skill: SkillInfo = preload("res://skills/throw_candy.tres")
								if !(skill in unit.skills): unit.skills.append(skill)
					)
				"whirlwind":
					$Units/PlayerGroup.get_children().map(
						func(unit: Unit):
							if unit != null and unit.unit_data.unit_class == "Fighter":
								var skill: SkillInfo = preload("res://skills/whirlwind.tres")
								if !(skill in unit.skills): unit.skills.append(skill)
					)
	#for each talent, match its name and apply its effect
