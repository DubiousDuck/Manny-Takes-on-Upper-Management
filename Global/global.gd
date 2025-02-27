extends Node

## Global script with utility functions

# Gives god mode to devs
var dev_mode: bool = true
######################       SET TO FALSE BEFORE EXPORTING !!!!!          #######################

var player_has_initialized: bool = true

# Battle related
var attack_successful: bool
var camera_top: int #y position
var camera_low: int #y position

# Overworld
var _last_overworld: String = ""
var _last_overworld_position: Vector2 = Vector2(0,0)

var brightness_val: float = 100.0

func start():
	brightness_val = 100.0

# Overworld
var _last_overworld_name: String = ""

func set_last_overworld_name(file_name: String):
	#TODO: check if the file_name is a valid scene path
	_last_overworld_name = file_name

func get_last_overworld_name() -> String:
	return _last_overworld_name
	
	
# Overworld
var _last_overworld_scene: PackedScene = PackedScene.new()

func set_last_overworld_scene(scene: Node):
	return _last_overworld_scene.pack(scene)

func get_last_overworld_scene() -> PackedScene:
	return _last_overworld_scene


# Skill Tree Related
enum talent_type{PROTAG, COMPANY}

## A dictionary of all protagonist talent nodes that have been activated.
var _protag_talent: Dictionary = {}
## A dictionary of all company talent nodes that have been activated.
var _company_talent: Dictionary = {}

func get_talent_activated(code: int) -> Dictionary:
	match code:
		talent_type.PROTAG:
			return _protag_talent
		talent_type.COMPANY:
			return _company_talent
		_:
			return {}

func clear_talent(code: int) -> void:
	match code:
		talent_type.PROTAG:
			_protag_talent.clear()
		talent_type.COMPANY:
			_company_talent.clear()

func copy_talent_dict_from(code: int, from: Dictionary):
	match code:
		talent_type.PROTAG:
			_protag_talent = from.duplicate()
		talent_type.COMPANY:
			_company_talent = from.duplicate()

func merge_talent_dict_with(code: int, target: Dictionary):
	match code:
		talent_type.PROTAG:
			_protag_talent.merge(target, true)
		talent_type.COMPANY:
			_company_talent.merge(target, true)
			
## Current Party related

## Determines the maximum amount of party members
var max_party_num: int = 3

var current_party: Array[UnitData] = []
var reserves: Array[UnitData] = []

## Player input signals

func _input(event):
	if event.is_action_pressed("Advance"):
		EventBus.input_advance.emit()
	elif event.is_action_pressed("Back"):
		EventBus.input_back.emit()

## Scene transition

var current_enemies : Array[UnitData] = []

func start_battle(overworld_rid, classes : Array[UnitData]):
	print(overworld_rid, classes)
	current_enemies = classes
	
## Save and load

var save_path = "user://save/"
var player_save_file = "player"
var global_save_file = "global"
var save_extension = ".tres"

func _ready():
	verify_directory(save_path)
	EventBus.connect("ui_element_started", ui_element_start)
	EventBus.connect("ui_element_ended", ui_element_end)
	
	#load data
	load_player_data(DEBUG_INT)
	
	# TODO REMOVE ME after party management system done
	if current_party.size() <= 0:
		var protag = preload("res://unit/params/protagonist.tres")
		var fighter = preload("res://unit/params/fighter.tres")
		current_party.append_array([protag, fighter])
	if reserves.size() <= 0:
		var mage = preload("res://unit/params/mage.tres")
		var ranger = preload("res://unit/params/ranger.tres")
		var healer = preload("res://unit/params/healer.tres")
		reserves.append_array([mage, ranger, healer])

func verify_directory(path : String):
	DirAccess.make_dir_absolute(path)
	
## UI

const DIALOGUE = preload("res://ui/dialogue.tscn")

func ui_element_start():
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED

func ui_element_end():
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_ALWAYS

func start_dialogue(text : Array[String]):
	var a = DIALOGUE.instantiate()
	UiLayer.add_child(a)
	a.read_text(text)
	await EventBus.ui_element_ended
	a.queue_free()
	
## Save and load #####################################################

const DEBUG_INT := 999

var player_data = PlayerData.new()

func load_player_data(save : int):
	var data = ResourceLoader.load(save_path + player_save_file + str(save) + save_extension)
	if !data:
		return
	player_data = data.duplicate(true)
	
	#read and copy talents
	copy_talent_dict_from(talent_type.PROTAG, player_data.protag_talents)
	copy_talent_dict_from(talent_type.COMPANY, player_data.company_talents)
	
	#copy current_party
	max_party_num = player_data.max_party_num
	current_party = player_data.current_party
	reserves = player_data.reserves

	print("- Loaded player data")
	
func save_player_data(save : int):
	#save talents
	player_data.protag_talents = _protag_talent.duplicate(true)
	player_data.company_talents = _company_talent.duplicate(true)
	
	#save current party
	player_data.max_party_num = max_party_num
	player_data.current_party = current_party
	player_data.reserves = reserves
	
	ResourceSaver.save(player_data, save_path + player_save_file + str(save) + save_extension)
	print("- Saved player data")
