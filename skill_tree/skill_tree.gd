extends Control

class_name SkillTree

@export var max_points: int = 3
@export var top_node: TalentNode

@onready var label: Label = $Label

var current_points: int

func _ready():
	EventBus.connect("talent_node_pressed", _on_talent_node_pressed)
	current_points = max_points
	label.text = "Talent Points Left: " + str(current_points)

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
