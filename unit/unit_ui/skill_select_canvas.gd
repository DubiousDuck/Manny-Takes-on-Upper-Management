extends CanvasLayer

class_name SkillSelectCanvas

@onready var icon = preload("res://unit/unit_ui/skill_icon.tscn")
@onready var hbox = $Panel/HBoxContainer
@onready var test_icon = $Panel/HBoxContainer/SkillIcon

@export var container: UnitContainer

var unit: Unit
var buttons : Array[SkillIcon] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("show_skill_select", init)
	EventBus.connect("hide_skill_select", _on_hide)
	visible = false
	test_icon.visible = false

func init(new_unit: Unit, valid_skills: Array[SkillInfo] = []):
	unit = new_unit
	for child in hbox.get_children():
		hbox.remove_child(child)
	buttons.clear()
	
	# instantiate all skills, but disable those that are not valid
	for skill in unit.skills:
		# only spawns WAIT if the unit has no attack token
		if skill.name != "Wait" and !unit.actions_avail.has(Unit.Action.ATTACK):
			continue
		var a: SkillIcon = icon.instantiate()
		a.skill = skill
		a.set_tooltip(skill.description)
		hbox.add_child(a)
		buttons.append(a)
		a.connect("pressed", _on_button_pressed)
		a.connect("mouse_entered", _on_mouse_entered.bind(a)) #bind() is a useful function
		a.connect("mouse_exited", _on_mouse_exit)
		if !(valid_skills.has(skill)):
			a.disabled = true
	
	visible = true
	$HBoxContainer/Hide.button_pressed = false

func _on_hide():
	visible = false
	unit = null
	for child in hbox.get_children():
		hbox.remove_child(child)
	buttons.clear()

func _on_button_pressed():
	for button in buttons:
		if button.button_pressed:
			#do something
			print("# SKILL CHOSEN: " + button.skill.name + " (skill_select.gd)")
			EventBus.emit_signal("skill_chosen", button.skill)
			button.button_pressed = false
			EventBus.tutorial_trigger.emit("attack_chosen")
			visible = false
			return

## display highlights of skill range when hovered over
func _on_mouse_entered(icon_hovered: SkillIcon):
	EventBus.emit_signal("remove_cell_highlights", name)
	EventBus.emit_signal("remove_cell_highlights", name+"_valid_targets")
	
	var all_neighbors := HexNavi.get_all_neighbors_in_range(HexNavi.global_to_cell(unit.global_position), icon_hovered.skill.range, 999)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, CellHighlight.ATTACK_PREVIEW_HIGHLIGHT, name)
	if container:
		var valid_targets = container.get_targets_of_type(all_neighbors, icon_hovered.skill.targets, unit)
		if valid_targets.size() > 0:
			if icon_hovered.skill.targets in [SkillInfo.TargetType.ENEMIES, SkillInfo.TargetType.ANY_UNIT, SkillInfo.TargetType.ALLIES, SkillInfo.TargetType.EXCEPT_SELF, SkillInfo.TargetType.ALLIES_EXCEPT_SELF, SkillInfo.TargetType.SELF]:
				EventBus.emit_signal("show_cell_highlights", valid_targets, CellHighlight.ATTACK_HIGHLIGHT, name+"_valid_targets")

func _on_mouse_exit():
	EventBus.emit_signal("remove_cell_highlights", name)
	EventBus.emit_signal("remove_cell_highlights", name+"_valid_targets")


func _on_cancel_pressed():
	EventBus.emit_signal("cancel_select_unit")

func _on_hide_toggled(toggled_on):
	if toggled_on:
		$Panel.hide()
		$HBoxContainer/Hide.text = "Show"
	else:
		$Panel.show()
		$HBoxContainer/Hide.text = "Hide"
