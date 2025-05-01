extends Control

class_name LevelPreview

const party_comp_scene := "res://overworld/party_comp/party_comp.tscn"

@onready var level_name = $Window/MarginContainer/VBoxContainer/LevelName
@onready var member_count = $Window/MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/MemberCount

var battle_scene_path: String = ""

func init(level_info: LevelInfo):
	EventBus.ui_element_started.emit()
	battle_scene_path = level_info.level_path
	level_name.text = "You're about to enter: " + level_info.level_name
	member_count.text = "Enemy Count: " + str(level_info.enemy_count) + "/n Ally Count: "+ str(level_info.ally_count)
	
func _on_start_pressed():
	if battle_scene_path != "":
		EventBus.ui_element_ended.emit()
		Global.scene_transition(battle_scene_path)
		queue_free()
	else:
		push_warning("There is no battle scene path set! -- LevelPreview.gd")

func _on_party_pressed():
	EventBus.ui_element_ended.emit()
	get_tree().change_scene_to_file(party_comp_scene)
	queue_free()
