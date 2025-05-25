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
var player_units_to_move: int = 0:
	set(new_value):
		player_units_to_move = new_value
		EventBus.emit_signal("units_left_changed")

func start():
	brightness_val = 100.0

# Overworld
var current_scene : String
var current_level : String
var finished_levels := {}  # Acts as a HashSet key (String): value (bool)
## a dictionary that maps events that should be recorded with a certain level clear
var level_event_table: Dictionary[String, String] = {
	"level1-4": "area1-cleared",
	"level2-4": "area2-cleared"
}
var class_recruit_table: Dictionary[String, String] = {
	"level1-1": "Fighter",
	"level1-2": "Ranger",
	"level1-3": "Tank",
	"level2-1": "Mage",
	"level2-2": "Healer"
}
var recruitable_classes: Array[String] = []
## Dialogue that plays automatically upon scene ready; good for scene transitions
var dialogue_on_scene_ready: Array[String]
var win_dialogue: Array[String]
var lose_dialogue: Array[String]

func finished_level():
	finished_levels[current_level]=true
	# check level_event_table to see if should add events
	if level_event_table.keys().has(current_level):
		events.append(level_event_table[current_level])
	if class_recruit_table.keys().has(current_level):
		recruitable_classes.append(class_recruit_table.get(current_level, ""))
	current_level=""

## calls after loading data to keep finished level-dependent data up-to-date
func refresh_finished_levels():
	for level in finished_levels.keys():
		if level_event_table.keys().has(level) and !events.has(level_event_table[level]):
			events.append(level_event_table[level])
		if class_recruit_table.keys().has(level) and !recruitable_classes.has(class_recruit_table.get(level, "")):
			recruitable_classes.append(class_recruit_table.get(level, ""))
	
var _last_overworld_scene: PackedScene = PackedScene.new()
var _last_battle_scene: String
## Two values: "overworld", "battle"
var last_scene_type: String
var last_overworld_path: String

func set_last_overworld_scene(scene: Node):
	if scene.scene_file_path != "":
		last_overworld_path = scene.scene_file_path
	#print("last overworld path is: " + last_overworld_path + " and scene is: " + scene.name)
	return _last_overworld_scene.pack(scene)

func get_last_overworld_scene() -> PackedScene:
	return _last_overworld_scene

# Using scene path instead of path because I want to re-initiate everything each time we load the battle (for now)
func set_last_battle_scene(scene_path: String):
	_last_battle_scene = scene_path
	return true
	
func get_last_battle_scene() -> String:
	return _last_battle_scene

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
var eaten_units: Array[UnitData] = []
var unequipped_items: Array[ItemData] = []

var events: Array[String] = []

## Current Battle
var battle_log: Array[String] = []

## Function to return the lowest level across reserves and party; useful for creating new characters without having their levels being too low
func get_lowest_unit_level() -> int:
	var lowest_level: int = INF
	for unit in current_party:
		if unit.level < lowest_level:
			lowest_level = unit.level
	for unit in reserves:
		if unit.level < lowest_level:
			lowest_level = unit.level
	return lowest_level

## Function that sets the maximum number of party members depending on current Area
func set_max_party_num(value: int):
	# failsafe
	if value < 3:
		return
	else: max_party_num = value

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

var save_path: String = "user://hr_saves/"
var player_save_file: String = "player"
var global_save_file: String = "global"
var save_extension: String = ".tres"

func _ready():
	verify_directory(save_path)
	EventBus.connect("ui_element_started", ui_element_start)
	EventBus.connect("ui_element_ended", ui_element_end)
	## NOTICE: Not sure if this will corrupr save files but we'll see
	load_new_save()
	

func verify_directory(path : String):
	DirAccess.make_dir_absolute(path)
	
## UI

const DIALOGUE = preload("res://ui/dialogues/dialogue.tscn")
const TUTORIAL = preload("res://ui/tutorial/tutorial.tscn")
const SCREEN_WIPE = preload("res://ui/screen_effects/screen_wipe.tscn")
const LABEL_PASS = preload("uid://db1uopvokjy1o")
const SAVE_UI = preload("res://ui/save_and_load/save_ui.tscn")
const LOAD_UI = preload("res://ui/save_and_load/load_ui.tscn")

var dialogue_choice: String = ""

var can_actors_move : bool = true:
	set(new_value):
		can_actors_move = new_value
		#print("can_actors_move is now: " + str(new_value))
var ui_busy : bool = false
## boolean used to stop other inputs other than Global to prevent accidental interactions
var in_cutscene: bool = false

func cutscene_start():
	in_cutscene = true
	can_actors_move = false

func cutscene_end():
	in_cutscene = false
	can_actors_move = true
	
func ui_element_start():
	ui_busy = true ## prevent accidental freeze when launching a specific scene from the editor
	can_actors_move = false
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED

func ui_element_end():
	ui_busy = false
	#print("beep beep making player move true -- ui_element_end of Global.gd")
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
	if page_queue.size() <= 0:
		return
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

func play_label_slide_from_left(text: String):
	EventBus.ui_element_started.emit()
	var a = LABEL_PASS.instantiate()
	GlobalUI.add_child(a)
	a.play_run_in_from_left(text)
	await a.get_node("AnimationPlayer").animation_finished
	a.queue_free()
	EventBus.ui_element_ended.emit()
	
## Save and load #####################################################

const DEBUG_INT := 28

var player_data = PlayerData.new()

func load_player_data(save: int) -> bool:
	var file_path = save_path + player_save_file + str(save) + ".json"
	if not FileAccess.file_exists(file_path):
		print("Save file not found.")
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_string)
	if result is Dictionary:
		player_data = PlayerData.new()
		player_data.from_dict(result)
		print("- Loaded player data from JSON index ", str(save))
		
		load_player_data_to_global(player_data)
		return true
	else:
		push_error("Failed to parse JSON save file.")
		return false
	
func find_all_saves() -> Array:
	var saves := []
	saves.resize(30)

	var dir := DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var file_path := save_path + file_name
				var file := FileAccess.open(file_path, FileAccess.READ)
				if file:
					var content := file.get_as_text()
					var data = JSON.parse_string(content)
					if typeof(data) == TYPE_DICTIONARY and data.has("index"):
						var index = data["index"]
						if index >= 0 and index < saves.size():
							saves[index] = data
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return saves
	
func save_player_data(save: int):
	player_data.index = save
	player_data.current_exp = current_exp
	player_data.level = level
	player_data.recruit_token = recruit_token
	player_data.max_party_num = max_party_num
	player_data.current_party = current_party.duplicate(true)
	player_data.eaten_units = eaten_units.duplicate(true)
	player_data.reserves = reserves.duplicate(true)
	player_data.unequipped_items = unequipped_items.duplicate(true)
	player_data.finished_levels = finished_levels
	player_data.events = events
	player_data.tutorial_seen = TutorialManager.tutorial_seen
	player_data.last_overworld_path = last_overworld_path
	player_data.recruitable_classes = recruitable_classes

	var json_string = JSON.stringify(player_data.to_dict(), "\t")  # Pretty print with tabs
	var file_path = save_path + player_save_file + str(save) + ".json"

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

	print("- Saved player data to JSON index ", str(save))

## Set parameters of a new save file
func load_new_save():
	player_data = PlayerData.new()
	load_player_data_to_global(player_data)

## Helper function that converts all variables in player_data to Global
func load_player_data_to_global(player_data: PlayerData):
	#load player level
	current_exp = player_data.current_exp
	level = player_data.level
	
	#copy current_party
	recruit_token = player_data.recruit_token
	max_party_num = player_data.max_party_num
	current_party = player_data.current_party.duplicate(true)
	eaten_units = player_data.eaten_units.duplicate(true)
	reserves = player_data.reserves.duplicate(true)
	unequipped_items = player_data.unequipped_items.duplicate(true)
	
	#load level progress
	finished_levels = player_data.finished_levels
	events = player_data.events
	
	#load tutorial seen
	TutorialManager.tutorial_seen = player_data.tutorial_seen
	TutorialManager.update_tutorial_seen()
	
	last_overworld_path = player_data.last_overworld_path
	recruitable_classes = player_data.recruitable_classes
	
	refresh_finished_levels()
