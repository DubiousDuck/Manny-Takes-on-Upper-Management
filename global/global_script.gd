extends Node

## Global script with utility functions

# Gives god mode to devs
var dev_mode: bool = true
######################       SET TO FALSE BEFORE EXPORTING !!!!!          #######################

# Battle related
var attack_successful: bool
var camera_top: int #y position
var camera_low: int #y position
var isPlayerTurn: bool = true
var is_attack_resolved: bool = true:
	set(value):
		is_attack_resolved = value
		print(is_attack_resolved)
		if value:
			EventBus.emit_signal("attack_resolved")

var brightness_val: float = 100.0

func start():
	brightness_val = 100.0

# Overworld
var current_scene : String
var current_level : String
var finished_levels := {}  # Acts as a HashSet
func finished_level():
	finished_levels[current_level]=true
	current_level=""

var _last_overworld_scene: PackedScene = PackedScene.new()

func set_last_overworld_scene(scene: Node):
	return _last_overworld_scene.pack(scene)

func get_last_overworld_scene() -> PackedScene:
	return _last_overworld_scene


# Skill Tree Related
var max_talent_points : int = 0

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
			
			

##Leveling System related

## Experience Gained
var max_exp : int = 6
var current_exp : int = 0
var level : int = 1

func gain_exp(value) -> int:
	print("Exp Gained: ", value)
	var original_level: int = level
	if(current_exp + value > max_exp):
		level += int((current_exp + value)/max_exp)
		max_talent_points += level - original_level
	current_exp = (current_exp + value) % max_exp
	return level - original_level

## Current Party related

## token necessary for recruiting new members
var recruit_token: int = 1

## Determines the maximum amount of party members
var max_party_num: int = 3

var current_party: Array[UnitData] = []
var reserves: Array[UnitData] = []

## Player input signals

func _unhandled_input(event):
	if event.is_action_pressed("Advance"):
		EventBus.input_advance.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Back"):
		EventBus.input_back.emit()
		get_viewport().set_input_as_handled()

## Scene transition

var current_enemies : Array[UnitData] = []

func start_battle(overworld_rid, classes : Array[UnitData]):
	EventBus.emit_signal("start_battle")
	print(overworld_rid, classes)
	current_enemies = classes
	
## Save and load

var save_path = "user://hr_saves/"
var player_save_file = "player"
var global_save_file = "global"
var save_extension = ".tres"

func _ready():
	verify_directory(save_path)
	EventBus.connect("ui_element_started", ui_element_start)
	EventBus.connect("ui_element_ended", ui_element_end)
	
	#load data
	load_player_data(DEBUG_INT)

func verify_directory(path : String):
	DirAccess.make_dir_absolute(path)
	
## UI

const DIALOGUE = preload("res://ui/dialogue.tscn")
const TUTORIAL = preload("res://ui/tutorial/tutorial.tscn")

var dialogue_choice: String = ""

func ui_element_start():
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED

func ui_element_end():
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT

func start_dialogue(text : Array[String]):
	var a = DIALOGUE.instantiate()
	UiLayer.add_child(a)
	a.read_text(text)
	await EventBus.ui_element_ended
	a.queue_free()

func start_tutorial(page_queue: Array[TutorialContent]):
	var a = TUTORIAL.instantiate()
	UiLayer.add_child(a)
	a.init(page_queue)
	await EventBus.ui_element_ended
	a.queue_free()
	
## Save and load #####################################################

const DEBUG_INT := 29

var player_data = PlayerData.new()

func load_player_data(save : int):
	var data = ResourceLoader.load(save_path + player_save_file + str(save) + save_extension)
	if !data:
		load_new_save()
		return
	player_data = data.duplicate(true)
	
	#load player level
	current_exp = player_data.current_exp
	level = player_data.level
	
	#read and copy talents
	copy_talent_dict_from(talent_type.PROTAG, player_data.protag_talents)
	copy_talent_dict_from(talent_type.COMPANY, player_data.company_talents)
	max_talent_points = player_data.max_talent_points
	
	#copy current_party
	recruit_token = player_data.recruit_token
	max_party_num = player_data.max_party_num
	current_party = player_data.current_party
	reserves = player_data.reserves

	print("- Loaded player data from index ", str(save))
	
func find_all_saves():
	var resources := Array()
	resources.resize(30)
	
	var dir = DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource = ResourceLoader.load(save_path + file_name)
				if resource and resource.has_method("get") and resource.get("index") != null:
					resources[resource.get("index")] = resource
			file_name = dir.get_next()
		dir.list_dir_end()
			
	return resources
	
func save_player_data(save : int):
	player_data.index = save
	
	#save player level
	player_data.current_exp = current_exp
	player_data.level = level
	
	#save talents
	player_data.protag_talents = _protag_talent.duplicate(true)
	player_data.company_talents = _company_talent.duplicate(true)
	player_data.max_talent_points = max_talent_points
	
	#save current party
	player_data.recruit_token = recruit_token
	player_data.max_party_num = max_party_num
	player_data.current_party = current_party
	player_data.reserves = reserves
	
	ResourceSaver.save(player_data, save_path + player_save_file + str(save) + save_extension)
	print("- Saved player data to index ", str(save))

func load_new_save():
	recruit_token = 0
	
	current_exp = 0
	level = 1
	max_talent_points = 0
	
	var protag = preload("res://unit/params/protagonist.tres")
	current_party.append_array([protag])
