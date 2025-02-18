extends Control

class_name SkillTree

@export var max_points: int = 3
@export var top_nodes: Array[TalentNode]

@onready var point_label: Label = $Label
@onready var mode_label: Label = $Label2
@onready var protag_folder: Array[TalentNode] = []
@onready var company_folder: Array[TalentNode] = []

var current_mode: int:
	set(value):
		if value == Global.talent_type.PROTAG:
			mode_label.text = "Leader Benefits"
		else:
			mode_label.text = "Company Benefits"
		current_mode = value

var current_points: int:
	set(value):
		point_label.text = "Talent Points Left: " + str(value)
		current_points = value

var temp_dict_protag: Dictionary = {}
var temp_dict_company: Dictionary = {}

func _ready():
	EventBus.connect("talent_node_pressed", _on_talent_node_pressed)
	current_points = max_points
	for node in $ProtagNodes.get_children():
		if node is TalentNode: protag_folder.append(node)
	for node in $CompanyNodes.get_children():
		if node is TalentNode: company_folder.append(node)
	
	temp_dict_protag = Global.get_talent_activated(Global.talent_type.PROTAG)
	temp_dict_company = Global.get_talent_activated(Global.talent_type.COMPANY)
	# for each key in dict, find node with same node name and set level
	for key in temp_dict_protag.keys():
		for node in protag_folder:
			if node.talent_name == key and temp_dict_protag[key] > 0:
				node.level = temp_dict_protag[key]
				current_points -= temp_dict_protag[key]
				node.toggle_disabled(false)
				break
	for key in temp_dict_company.keys():
		for node in company_folder:
			if node.talent_name == key and temp_dict_company[key] > 0:
				node.level = temp_dict_company[key]
				current_points -= temp_dict_company[key]
				node.toggle_disabled(false)
				break
	top_nodes.map(
		func(node: TalentNode): node.toggle_disabled(false)
	) # Always light up the top node (will be dimmed later if all points used)
	if current_points <= 0:
		EventBus.emit_signal("disable_all_nodes")
	switch_mode(Global.talent_type.PROTAG) #defaults to protag tree

func switch_mode(mode: int):
	current_mode = mode
	match current_mode:
		Global.talent_type.PROTAG:
			$ProtagNodes.show()
			$CompanyNodes.hide()
		Global.talent_type.COMPANY:
			$CompanyNodes.show()
			$ProtagNodes.hide()

func _on_talent_node_pressed():
	current_points -= 1
	if current_points <= 0:
		EventBus.emit_signal("disable_all_nodes")

func _on_reset_pressed():
	current_points = max_points
	EventBus.emit_signal("reset_talent_levels")
	top_nodes.map(
		func(node: TalentNode): node.toggle_disabled(false)
	)

func _on_save_exit_pressed():
	temp_dict_protag.clear()
	for node in protag_folder:
		if node.level >= 1:
			temp_dict_protag[node.talent_name] = node.level
	Global.copy_talent_dict_from(Global.talent_type.PROTAG, temp_dict_protag)
	print(Global.get_talent_activated(Global.talent_type.PROTAG))
	
	temp_dict_company.clear()
	for node in company_folder:
		if node.level >= 1:
			temp_dict_company[node.talent_name] = node.level
	Global.copy_talent_dict_from(Global.talent_type.COMPANY, temp_dict_company)
	print(Global.get_talent_activated(Global.talent_type.COMPANY))
	
	
	if Global.get_last_overworld() != "":
		get_tree().change_scene_to_file(Global.get_last_overworld())

func _on_switch_tree_pressed():
	if current_mode == Global.talent_type.PROTAG:
		switch_mode(Global.talent_type.COMPANY)
	elif current_mode == Global.talent_type.COMPANY:
		switch_mode(Global.talent_type.PROTAG)
