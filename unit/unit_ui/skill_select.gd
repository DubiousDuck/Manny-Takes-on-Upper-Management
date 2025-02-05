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
		a.connect("mouse_entered", _on_mouse_entered.bind(a)) #bind() is a useful function
		a.connect("mouse_exited", _on_mouse_exit)
	
func _on_button_pressed():
	for button in buttons:
		if button.button_pressed:
			#do something
			print("# SKILL CHOSEN: " + button.skill.name + " (skill_select.gd)")
			EventBus.emit_signal("skill_chosen", button.skill)
			button.button_pressed = false
			return

## display highlights of skill range when hovered over
func _on_mouse_entered(icon_hovered: SkillIcon):
	print(icon_hovered.name + str(" is being hovered over!"))
	#Prob unoptimal but convenient implmentation
	EventBus.emit_signal("remove_cell_highlights", name)
	
	var all_neighbors := HexNavi.get_all_neighbors_in_range(HexNavi.global_to_cell(unit.global_position), icon_hovered.skill.range)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, Color(1, 1, 0, 0.5), name)

func _on_mouse_exit():
	EventBus.emit_signal("remove_cell_highlights", name)
