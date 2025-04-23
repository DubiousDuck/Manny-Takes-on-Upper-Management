extends Node2D

class_name Level

const INTRAVERSABLE_WEIGHT: float = 999

@onready var battle_outcome = preload("uid://ct4t683r6jn78")
@onready var pause_canvas_layer = $PauseCanvasLayer

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

@export_category("Rewards")
@export var inital_exp : int
@export var repeat_exp : int
@export var dropped_items: Array[ItemData] = []

@export_category("Other Parameters")
## Array of of tutorials to show
@export var level_name : String
@export var tutorial_queue: Array[TutorialContent]

## Whether to give a recruit token or not after initial victory
@export var give_token: bool = true

func _ready():
	EventBus.connect("battle_ended", _on_battle_ended)
	
	HexNavi.set_current_map(tile_map)
	HexNavi.set_weight_of_layer("traversable", false, INTRAVERSABLE_WEIGHT)
	
	#read_talent_and_apply(Global.talent_type.PROTAG)
	#read_talent_and_apply(Global.talent_type.COMPANY)
	
	if !tutorial_queue.is_empty():
		if Global.ui_busy:
			await EventBus.ui_element_ended # wait for fade
		Global.start_tutorial(tutorial_queue)
	
	unit_group_control.init()

func _on_battle_ended(result: int):
	##exp gain
	var a = battle_outcome.instantiate()
	a.init(result)
	pause_canvas_layer.add_in_background(a)
	var init_level : int = Global.level
	if result == EventBus.BattleResult.PLAYER_VICTORY:
		Global.finished_level()
		pause_canvas_layer.add_in_background(a)
		
		# gain exp points
		var xp_gained = inital_exp #TODO: gain repeat exp if level already beaten
		Global.gain_exp(xp_gained)
		
		# gain token
		if give_token:
			Global.recruit_token += 1
		a.update_xp_label(xp_gained)
		
		# drop loot
		Global.unequipped_items.append_array(dropped_items)
	else:
		a.update_xp_label(0)
	#$PauseCanvasLayer.add_child(a)
	a.display()
	a.animate_exp(Global.current_exp, init_level, Global.level)
