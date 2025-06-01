extends Node2D

@export var tutorial_queue: Array[TutorialContent] = []

@onready var profile_box = $TextureRect/MarginContainer/ProfileBox

var class_dict: Dictionary = {
	"Fighter": 	"res://unit/params/fighter.tres",
	"Ranger": "res://unit/params/ranger.tres",
	"Tank": "res://unit/params/tank.tres",
	"Mage": "res://unit/params/mage.tres",
	"Healer": "res://unit/params/healer.tres"
}

# Called when the node enters the scene tree for the first time.
func _ready():
	TutorialManager.set_tutorial_queue(tutorial_queue)
	
	for child in profile_box.get_children():
		if child is ClassProfile:
			if child.unit_name in Global.recruitable_classes:
				child.connect("pressed", _on_character_pressed)
				child.set_locked(false)
			else:
				child.set_locked(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

const MEMBER = preload("res://overworld/party_comp/member_draggable.tscn")

func back_to_overworld():
	EventBus.tutorial_trigger.emit("first_time_recruit")
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())

func party_add_logic(ally_type):
	if Global.max_party_num > Global.current_party.size():
		Global.current_party.append(ally_type)
	else:
		Global.reserves.append(ally_type)
		HintManager.trigger_hint("reserve_added", "Your new recruit is in the Reserves", false)
	Global.recruit_token -= 1

# Function to assign a unique ID and return the character with that ID
static var next_id=0
func create_character(character_data: UnitData):
	character_data.id = next_id
	# Make sure that the new recruit doesn't start at level 1
	while character_data.level < Global.get_protag_unit_level():
		character_data.level_up()
	next_id += 1
	print(next_id)
	return character_data

func _on_character_pressed(unit_name: String):
	# defaults to spawning fighter as a guardrail
	var new_char := load(class_dict.get(unit_name, "res://unit/params/fighter.tres")).duplicate(true)
	party_add_logic(create_character(new_char))
	back_to_overworld()

func _on_cancel_pressed():
	AudioPreload.play_sfx("click")
	back_to_overworld()
