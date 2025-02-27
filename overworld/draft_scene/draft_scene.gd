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

func _on_mage_pressed():
	var mage = preload("res://unit/params/mage.tres")
	Global.reserves.append(mage)
	back_to_overworld()


func _on_fighter_pressed():
	var fighter = preload("res://unit/params/fighter.tres")
	Global.reserves.append(fighter)
	back_to_overworld()


func _on_ranger_pressed():
	var ranger = preload("res://unit/params/ranger.tres")
	Global.reserves.append(ranger)
	back_to_overworld()
