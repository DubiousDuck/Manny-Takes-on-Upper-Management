extends Node2D

@export var tutorial_queue: Array[TutorialContent] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	TutorialManager.set_tutorial_queue(tutorial_queue)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


const MEMBER = preload("res://overworld/party_comp/member_draggable.tscn")

func back_to_overworld():
	EventBus.tutorial_trigger.emit("first_time_recruit")
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())

func party_add_logic(ally_type):
	if Global.max_party_num > Global.current_party.size():
		print("adding to party")
		Global.current_party.append(ally_type)
	else:
		print("adding to reserves")
		Global.reserves.append(ally_type)
	Global.recruit_token -= 1

# Function to assign a unique ID and return the character with that ID
static var next_id=0
func create_character(character_data: UnitData):
	character_data.id = next_id
	# Make sure that the new recruit doesn't start at level 1
	while character_data.level < Global.get_lowest_unit_level():
		character_data.level_up()
	next_id += 1
	print(next_id)
	return character_data

func _on_mage_pressed():
	var mage = preload("res://unit/params/mage.tres").duplicate(true)
	mage = create_character(mage)  # Assign a unique ID
	party_add_logic(mage)
	back_to_overworld()

func _on_fighter_pressed():
	var fighter = preload("res://unit/params/fighter.tres").duplicate(true)
	fighter = create_character(fighter)  # Assign a unique ID
	party_add_logic(fighter)
	back_to_overworld()

func _on_ranger_pressed():
	var ranger = preload("res://unit/params/ranger.tres").duplicate(true)
	ranger = create_character(ranger)  # Assign a unique ID
	party_add_logic(ranger)
	back_to_overworld()

func _on_healer_pressed():
	var healer = preload("res://unit/params/healer.tres").duplicate(true)
	healer = create_character(healer)  # Assign a unique ID
	party_add_logic(healer)
	back_to_overworld()

func _on_cancel_pressed():
	back_to_overworld()
