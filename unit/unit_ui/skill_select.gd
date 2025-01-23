extends Control

class_name SkillSelect

@export var unit: Unit
@onready var hbox = $HBoxContainer
@onready var icon = preload("res://unit/unit_ui/skill_icon.tscn")

@onready var test_icon = $HBoxContainer/SkillIcon

var buttons : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	test_icon.visible = false
	unit = get_parent()
	init()
	

func init():
	for child in hbox.get_children():
		hbox.remove_child(child)
	buttons.clear()
	
	for skill in unit.skills:
		var a: SkillIcon = icon.instantiate()
		a.skill = skill
		hbox.add_child(a)
		buttons.append(a)
		a.connect("pressed", _on_button_pressed)
	
func _on_button_pressed():
	for button in buttons:
		if button.button_pressed:
			#do something
			print("# SKILL CHOSEN: " + button.skill.name + " (skill_select.gd)")
			EventBus.emit_signal("skill_chosen", button.skill)
			button.button_pressed = false
			return
