class_name PlayerData extends Resource

@export var index : int = -99

@export var player_name : String = "A"

# include party details here

## Player level
@export var current_exp: int
@export var level: int

## Current party
@export var recruit_token: int = 0
@export var max_party_num: int = 3
@export var current_party: Array[UnitData] = [preload("res://unit/params/protagonist.tres").duplicate(true)]
@export var reserves: Array[UnitData] = []
@export var eaten_units: Array[UnitData] = []
@export var unequipped_items: Array[ItemData] = []

## Level Progess
@export var finished_levels := {}
@export var events : Array[String] = []
@export var recruitable_classes: Array[String] = []

## Tutorial seen
@export var tutorial_seen: Dictionary[String, bool] = {}

## Last overworld path; default to Area 1
@export var last_overworld_path: String = "uid://c8qibn8b170i0"

func to_dict() -> Dictionary:
	return {
		"index": index,
		"player_name": player_name,
		"current_exp": current_exp,
		"level": level,
		"recruit_token": recruit_token,
		"max_party_num": max_party_num,
		"current_party": current_party.map(func(unit): return unit.to_dict()),
		"reserves": reserves.map(func(unit): return unit.to_dict()),
		"eaten_units": eaten_units.map(func(unit): return unit.to_dict()),
		"unequipped_items": unequipped_items.map(func(item): return item.to_dict()),
		"finished_levels": finished_levels,
		"events": events,
		"tutorial_seen": tutorial_seen,
		"last_overworld_path": last_overworld_path,
		"recruitable_classes": recruitable_classes
	}

func from_dict(data: Dictionary) -> void:
	index = data.get("index", -99)
	player_name = data.get("player_name", "A")
	current_exp = data.get("current_exp", 0)
	level = data.get("level", 1)
	recruit_token = data.get("recruit_token", 0)
	max_party_num = data.get("max_party_num", 3)

	current_party = parse_unitdata_array(data.get("current_party", []))
	reserves = parse_unitdata_array(data.get("reserves", []))
	eaten_units = parse_unitdata_array(data.get("eaten_units", []))
	unequipped_items = pare_itemdata_array(data.get("unequipped_items", []))

	finished_levels = data.get("finished_levels", {})
	
	# recasting from Array to Array[String]
	events.clear()
	var raw_events = data.get("events", [])
	for event in raw_events:
		events.append(event)
	
	# recasting from Dictionary to Dictionary[String, bool]
	tutorial_seen.clear()
	var raw_tutorial_seen = data.get("tutorial_seen", {})
	for title in raw_tutorial_seen.keys():
		tutorial_seen[title] = raw_tutorial_seen[title]
	
	last_overworld_path = data.get("last_overworld_path", "res://overworld/area_1.tscn")
	
	var raw_array: Array = data.get("recruitable_classes", [])
	for element in raw_array:
		recruitable_classes.append(element)

static func parse_unitdata_array(data_array: Array) -> Array[UnitData]:
	var result: Array[UnitData] = []
	for d in data_array:
		result.append(UnitData.new_from_dict(d))
	return result

static func pare_itemdata_array(data_array: Array) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for d in data_array:
		result.append(ItemData.new_from_dict(d))
	return result
