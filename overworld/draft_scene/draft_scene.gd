extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


const MEMBER = preload("res://overworld/party_comp/draggable_member.tscn")

func back_to_overworld():
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())

func party_add_logic(ally_type):
	if Global.max_party_num > Global.current_party.size():
		print("adding to party")
		Global.current_party.append(ally_type)
	else:
		print("adding to reserves")
		Global.reserves.append(ally_type)

func _on_mage_pressed():
	var mage = preload("res://unit/params/mage.tres")
	party_add_logic(mage)
	back_to_overworld()


func _on_fighter_pressed():
	var fighter = preload("res://unit/params/fighter.tres")
	party_add_logic(fighter)
	back_to_overworld()


func _on_ranger_pressed():
	var ranger = preload("res://unit/params/ranger.tres")
	party_add_logic(ranger)
	back_to_overworld()


func _on_healer_pressed():
	var healer = preload("res://unit/params/healer.tres")
	party_add_logic(healer)
	back_to_overworld()
