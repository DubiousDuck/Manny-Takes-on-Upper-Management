extends Control

class_name SkillTree

@export_enum("Protagonist", "Company") var talent_type: int
@export var max_points: int = 3
@export var top_node: TalentNode

@onready var label: Label = $Label
@onready var node_folder: Array[TalentNode] = []

var current_points: int
var temp_dict: Dictionary = {}

func _ready():
	EventBus.connect("talent_node_pressed", _on_talent_node_pressed)
	current_points = max_points
	for node in $Nodes.get_children():
		if node is TalentNode: node_folder.append(node)
	
	temp_dict = Global.get_talent_activated(talent_type)
	# for each key in dict, find node with same node name and set level
	for key in temp_dict.keys():
		for node in node_folder:
			if node.talent_name == key and temp_dict[key] > 0:
				node.level = temp_dict[key]
				current_points -= temp_dict[key]
				node.toggle_disabled(false)
				break
	label.text = "Talent Points Left: " + str(current_points)
	top_node.toggle_disabled(false) # Always light up the top node (will be dimmed later if all points used)
	if current_points <= 0:
		EventBus.emit_signal("disable_all_nodes")

func _on_talent_node_pressed():
	current_points -= 1
	label.text = "Talent Points Left: " + str(current_points)
	if current_points <= 0:
		EventBus.emit_signal("disable_all_nodes")

func _on_reset_pressed():
	current_points = max_points
	label.text = "Talent Points Left: " + str(current_points)
	EventBus.emit_signal("reset_talent_levels")
	top_node.toggle_disabled(false)

func _on_save_exit_pressed():
	temp_dict.clear()
	for node in node_folder:
		if node.level >= 1:
			temp_dict[node.talent_name] = node.level
	Global.copy_talent_dict_from(talent_type, temp_dict)
	print(Global.get_talent_activated(talent_type))
	if Global.get_last_overworld() != "":
		get_tree().change_scene_to_file(Global.get_last_overworld())
