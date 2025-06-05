extends CanvasLayer

class_name SkillSelectCanvas

const WAIT = preload("res://skills/wait.tres")
const MOVE = preload("res://skills/move.tres")
const skill_icon = preload("res://unit/unit_ui/skill_icon.tscn")
const action_icon = preload("res://unit/unit_ui/action_icon.tscn")
const BACK_BUTTON = preload("res://unit/unit_ui/back_button.tscn")

@onready var action_container = $Panel/ActionContainer
@onready var skill_container = $Panel/SkillContainer
@onready var test_action_icon = $Panel/ActionContainer/ActionIcon
@onready var test_skill_icon = $Panel/SkillContainer/SkillIcon

@export var container: UnitContainer

var unit: Unit
var valid_skills: Array[SkillInfo] = []
var buttons : Array[SkillIcon] = []
var action_type_dict: Dictionary = {
	"Attack": [],
	"Skill": []
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("show_skill_select", init)
	EventBus.connect("hide_skill_select", _on_hide)
	visible = false
	test_skill_icon.visible = false
	test_action_icon.visible = false

func init_actions(new_unit: Unit):
	for child in action_container.get_children():
		action_container.remove_child(child)
	# Manually create and connect each button
	for action in new_unit.actions_avail:
		match action:
			Unit.Action.ATTACK:
				# Attack button
				var a = action_icon.instantiate() as ActionIcon
				a.text = "Attacks"
				action_container.add_child(a)
				a.connect("pressed", _on_action_button_pressed.bind("Attack"))
				
				# Skill Button
				var b = action_icon.instantiate() as ActionIcon
				b.text = "Skills"
				action_container.add_child(b)
				b.connect("pressed", _on_action_button_pressed.bind("Skill"))
			Unit.Action.MOVE:
				var a = action_icon.instantiate() as ActionIcon
				a.text = "Move"
				action_container.add_child(a)
				a.connect("pressed", _on_action_button_pressed.bind("Move"))
	var a = action_icon.instantiate() as ActionIcon
	a.text = "Wait"
	action_container.add_child(a)
	a.connect("pressed", _on_action_button_pressed.bind("Wait"))

func init_skills(valids: Array[SkillInfo]):
	#print("Init skills for:", unit.name, "Skill count:", unit.skills.size())  # ← Add this

	action_type_dict["Attack"].clear()
	action_type_dict["Skill"].clear()
	# log for this given position, what the valid skills are
	valid_skills = valids
	
	# record the skill type of each skill of the unit
	for skill in unit.skills:
		if skill.type == "Attack" or skill.type == "attack":
			action_type_dict["Attack"].append(skill)
			#print(skill.name + " is being added to the Attack list")
		elif skill.type == "Skill" or skill.type == "skill":
			action_type_dict["Skill"].append(skill)
			#print(skill.name + " is being added to the Skill list")
		else:
			pass
			#print(skill.name + " is not being added... and it is of type: " + str(skill.type))

func init(new_unit: Unit, valids: Array[SkillInfo] = []):
	unit = new_unit
	init_actions(unit)
	init_skills(valids)
	
	visible = true
	action_container.visible = true
	skill_container.visible = false
	$HBoxContainer/Hide.button_pressed = false

func _on_action_button_pressed(type: String):
	action_container.hide()
	match type:
		"Attack", "Skill":
			HintManager.trigger_hint("second_layer_needed", "Choose a valid %s" %type, false)
			show_skill_of_type(type)
		"Move":
			HintManager.trigger_hint("move_pressed", "Choose a tile to move to", false)
			EventBus.emit_signal("skill_chosen", MOVE)
			visible = false
			return
		"Wait":
			EventBus.emit_signal("skill_chosen", WAIT)
			visible = false
			return
	
func show_skill_of_type(type: String):
	clear_all_skill_button()
	skill_container.show()
	
	var skill_array: Array = action_type_dict.get(type, [])
	#print("There are %d skills in skill type: %s" %[skill_array.size(), type])
	for skill in skill_array:
		var a = skill_icon.instantiate() as SkillIcon
		a.skill = skill
		# only spawns WAIT if the unit has no attack token
		#if skill.name != "Wait" and !unit.actions_avail.has(Unit.Action.ATTACK):
			#continue
		a.set_tooltip(skill.description)
		skill_container.add_child(a)
		buttons.append(a)
		a.connect("pressed", _on_button_pressed)
		a.connect("mouse_entered", _on_mouse_entered.bind(a)) #bind() is a useful function
		a.connect("mouse_exited", _on_mouse_exit)
		if !(valid_skills.has(skill)):
			a.disabled = true
	
	# Add the Back button last so it appears at the bottom
	var back = BACK_BUTTON.instantiate() as Button
	skill_container.add_child(back)
	back.connect("pressed", _on_back_pressed)

func _on_hide():
	visible = false
	unit = null
	clear_all_skill_button()

func clear_all_skill_button():
	for child in skill_container.get_children():
		skill_container.remove_child(child)
	buttons.clear()

func _on_button_pressed():
	for button in buttons:
		if button.button_pressed:
			#print("# SKILL CHOSEN: " + button.skill.name + " (skill_select.gd)")
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
	AudioPreload.play_sfx("select")
	EventBus.emit_signal("cancel_select_unit")

func _on_hide_toggled(toggled_on):
	AudioPreload.play_sfx("select")
	if toggled_on:
		$Panel.hide()
		$HBoxContainer/Hide.text = "Show"
	else:
		$Panel.show()
		$HBoxContainer/Hide.text = "Hide"

func _on_back_pressed():
	AudioPreload.play_sfx("select")
	skill_container.hide()
	action_container.show()
