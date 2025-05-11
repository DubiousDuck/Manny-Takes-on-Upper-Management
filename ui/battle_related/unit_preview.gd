extends CanvasLayer

class_name UnitPreview

const BUFF_COLOR: Color = Color("#2c9c3e")
const DEBUFF_COLOR: Color = Color.CRIMSON
const SKILL_PREVIEW = preload("res://ui/battle_related/skill_preview.tscn")

enum STAT{HP, MOV, ATK, MAG}

@onready var preview_window = $TextureRect
@onready var class_label = $TextureRect/CenterContainer/VBoxContainer/Class
@onready var hp_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/HP
@onready var mov_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/MOV
@onready var atk_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/ATK
@onready var mag_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/MAG
@onready var skill_list = $TextureRect/CenterContainer/VBoxContainer/ScrollContainer/SkillList



var cur_unit : Unit

var hp: int:
	set(value):
		hp = value
		hp_label.text = str(hp)
		set_label_color(STAT.HP, hp)
var mov: int:
	set(value):
		mov = value
		mov_label.text = str(mov)
		set_label_color(STAT.MOV, mov)
var atk: int:
	set(value):
		atk = value
		atk_label.text = str(atk)
		set_label_color(STAT.ATK, atk)
var mag: int:
	set(value):
		mag = value
		mag_label.text = str(mag)
		set_label_color(STAT.MAG, mag)

var locked_unit: Unit
var hovered_unit: Unit

func init(unit: Unit):
	cur_unit = unit
	#set sprite 2d to corresponding class
	class_label.text = unit.unit_data.unit_class
	hp = unit.max_health
	mov = unit.movement_range
	atk = unit.attack_power
	mag = unit.magic_power
	
	for child in skill_list.get_children():
		child.queue_free()
	for skill in cur_unit.skills:
		var a = SKILL_PREVIEW.instantiate()
		skill_list.add_child(a)
		a.label.text = skill.name

func set_label_color(stat: STAT, value: int):
	var label: Label
	var attr_string: String
	match stat:
		STAT.HP:
			label = hp_label
			attr_string = "HP"
		STAT.MOV:
			label = mov_label
			attr_string = "MOV"
		STAT.ATK:
			label = atk_label
			attr_string = "ATK"
		STAT.MAG:
			label = mag_label
			attr_string = "MAG"
	if label:
		if value > cur_unit.unit_data.get_stat(attr_string):
			label.add_theme_color_override("font_color", BUFF_COLOR)
		elif value < cur_unit.unit_data.get_stat(attr_string):
			label.add_theme_color_override("font_color", DEBUFF_COLOR)
		else:
			label.remove_theme_color_override("font_color")

func _ready():
	EventBus.connect("unit_hovered", _unit_hovered)
	EventBus.connect("unit_unhovered", _unit_unhovered)
	EventBus.connect("unit_right_clicked", _unit_right_clicked)
	EventBus.connect("clear_preview", _clear_preview)
	preview_window.hide()

func _unit_hovered(unit: Unit):
	if !locked_unit:
		show_preview(unit)
		hovered_unit = unit
func _unit_unhovered(unit: Unit):
	if !locked_unit and hovered_unit:
		preview_window.hide()
		hovered_unit = null
func _unit_right_clicked(unit: Unit):
	locked_unit = unit
	show_preview(locked_unit)
	hovered_unit = null
func _clear_preview():
	if locked_unit:
		locked_unit = null
		preview_window.hide()

func show_preview(unit: Unit):
	init(unit)
	
	preview_window.visible = true

	var screen_position = unit.global_position
	var screen_center = get_viewport().get_camera_2d().get_target_position()
	
	#print(screen_position, screen_center)

	if screen_position.x < screen_center.x:
		# Unit is on left → show preview on right
		preview_window.position = $RightAnchor.position
	else:
		# Unit is on right → show preview on left
		preview_window.position = $LeftAnchor.position
