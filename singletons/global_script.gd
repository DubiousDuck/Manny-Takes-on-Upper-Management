extends Node

## Global script with utility functions

# Gives god mode to devs TODO: CHANGE IT BACK BEFORE EXPORTING
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
## Three possible values: "win", "lose", "none"
var battle_result: String = "none"

func start():
	brightness_val = 100.0

# Overworld
var current_scene : String
var current_level : String
var finished_levels := {}  # Acts as a HashSet
## Dialogue that plays automatically upon scene ready; good for scene transitions
var dialogue_on_scene_ready: Array[String]
var win_dialogue: Array[String]
var lose_dialogue: Array[String]

func finished_level():
	finished_levels[current_level]=true
	current_level=""

var _last_overworld_scene: PackedScene = PackedScene.new()

func set_last_overworld_scene(scene: Node):
	return _last_overworld_scene.pack(scene)

func get_last_overworld_scene() -> PackedScene:
	return _last_overworld_scene

##Leveling System related

## calculated in steps of 5 (i.e. lvl 0-4 need 6 xp, 5-10 needs 12 etc.)
var exp_requirments = { 
	0:3,
	1:6,
	2:12,
	3:24
}

var max_level_ind = 3

##helper for getting exp reqs, checks if max level reached and indexes by every 5th level
func get_exp_requirment(level:int):
	var ind = int(level/5)
	if(ind > max_level_ind):
		ind = max_level_ind
	return exp_requirments[ind]

var current_exp : int = 0
var level : int = 1

## Experience Gained
func gain_exp(value):
	print("Exp Gained: ", value)
	current_exp += value
	var exp_req = get_exp_requirment(level)
	print("exp req: ", exp_req)
	
	var original_level: int = level
	
	while(current_exp >= exp_req):
		level += 1
		current_exp -= exp_req

## Current Party related

## token necessary for recruiting new members
var recruit_token: int = 0

## Determines the maximum amount of party members
var max_party_num: int = 3

var current_party: Array[UnitData] = []
var reserves: Array[UnitData] = []
var unequipped_items: Array[ItemData] = []

var events: Array[String] = []

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
	## NOTICE: Not sure if this will corrupr save files but we'll see
	load_new_save()
	

func verify_directory(path : String):
	DirAccess.make_dir_absolute(path)
	
## UI

const DIALOGUE = preload("res://ui/dialogue.tscn")
const TUTORIAL = preload("res://ui/tutorial/tutorial.tscn")
const SCREEN_WIPE = preload("res://ui/screen_wipe.tscn")
const SAVE_UI = preload("res://ui/save_and_load/save_ui.tscn")
const LOAD_UI = preload("res://ui/save_and_load/load_ui.tscn")

var dialogue_choice: String = ""

var can_actors_move : bool = true
var ui_busy : bool = false

func ui_element_start():
	ui_busy = true ## prevent accidental freeze when launching a specific scene from the editor
	can_actors_move = false
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED

func ui_element_end():
	ui_busy = false
	can_actors_move = true
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_INHERIT

func scene_transition(scene : String):
	EventBus.ui_element_started.emit()
	var a = SCREEN_WIPE.instantiate()
	GlobalUI.add_child(a)
	a.get_node("AnimationPlayer").play("In")
	await a.get_node("AnimationPlayer").animation_finished
	get_tree().change_scene_to_file(scene)
	a.get_node("AnimationPlayer").play("Out")
	await a.get_node("AnimationPlayer").animation_finished
	a.queue_free()
	EventBus.ui_element_ended.emit()

func start_dialogue(text : Array[String], in_cutscene : bool = false): 
	var a = DIALOGUE.instantiate()
	GlobalUI.add_child(a)
	a.read_text(text, in_cutscene)
	if in_cutscene:
		await EventBus.dialogue_finished
	else: await EventBus.ui_element_ended
	a.queue_free()

func start_tutorial(page_queue: Array[TutorialContent]):
	var a = TUTORIAL.instantiate()
	GlobalUI.add_child(a)
	a.init(page_queue)
	await EventBus.ui_element_ended
	a.queue_free()
	
func save_screen():
	EventBus.ui_element_started.emit()
	var a = SAVE_UI.instantiate()
	GlobalUI.add_child(a)
	await EventBus.ui_element_ended
	
func load_screen():
	EventBus.ui_element_started.emit()
	var a = LOAD_UI.instantiate()
	GlobalUI.add_child(a)
	await EventBus.ui_element_ended
	
## Save and load #####################################################

const DEBUG_INT := 28

var player_data = PlayerData.new()

func load_player_data(save : int):
	var data = ResourceLoader.load(save_path + player_save_file + str(save) + save_extension)
	if !data:
		push_warning("no valid data found. initializing a new save... -- Global.gd")
		load_new_save()
		return
	player_data = data.duplicate(true)
	
	#load player level
	current_exp = player_data.current_exp
	level = player_data.level
	
	#copy current_party
	recruit_token = player_data.recruit_token
	max_party_num = player_data.max_party_num
	current_party = player_data.current_party.duplicate(true)
	reserves = player_data.reserves.duplicate(true)
	unequipped_items = player_data.unequipped_items.duplicate(true)
	
	#load level progress
	finished_levels = player_data.finished_levels
	events = player_data.events
	
	print(OS.get_user_data_dir())
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
	
	#save current party
	player_data.recruit_token = recruit_token
	player_data.max_party_num = max_party_num
	player_data.current_party = current_party.duplicate(true)
	player_data.reserves = reserves.duplicate(true)
	player_data.unequipped_items = unequipped_items.duplicate(true)
	
	#save level progress
	player_data.finished_levels = finished_levels
	player_data.events = events
	
	ResourceSaver.save(player_data, save_path + player_save_file + str(save) + save_extension)
	print("- Saved player data to index ", str(save))

## Set parameters of a new save file
func load_new_save():
	recruit_token = 0
	
	current_exp = 0
	level = 1
	
	var protag = preload("res://unit/params/protagonist.tres")
	current_party.append_array([protag.duplicate(true)])
