extends CanvasLayer

class_name UnitPreview

const BUFF_COLOR: Color = Color("#2c9c3e")
const DEBUFF_COLOR: Color = Color.CRIMSON
const SKILL_PREVIEW = preload("res://ui/battle_related/skill_preview.tscn")

enum STAT{HP, MOV, ATK, MAG}

@onready var preview_window = $TextureRect
@onready var class_label = $TextureRect/CenterContainer/VBoxContainer/Class
@onready var class_sprite = $TextureRect/CenterContainer/VBoxContainer/ClassSprite
@onready var hp_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/HP
@onready var mov_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/MOV
@onready var atk_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/ATK
@onready var mag_label = $TextureRect/CenterContainer/VBoxContainer/CenterContainer/GridContainer/MAG
@onready var skill_list = $TextureRect/CenterContainer/VBoxContainer/ScrollContainer/SkillList
@onready var level_label = $TextureRect/CenterContainer/VBoxContainer/LevelLabel

var stat_to_label: Dictionary[String, Label] = {}
var cur_unit : Unit
var cur_unit_container: UnitContainer

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
	cur_unit_container = unit.container
	#set sprite 2d to corresponding class
	class_label.text = unit.unit_data.unit_class
	set_class_sprite(unit.unit_data.unit_class)
	level_label.text = "Level: %d" %unit.unit_data.level
	
	hp = unit.max_health
	mov = unit.movement_range
	atk = unit.attack_power
	mag = unit.magic_power
	
	for child in skill_list.get_children():
		child.queue_free()
	
	# Read and set skill list information
	for skill in cur_unit.skills:
		var a = SKILL_PREVIEW.instantiate() as SkillPreview
		skill_list.add_child(a)
		a.skill = skill
		a.label.text = skill.name
		a.set_tooltip(skill.description)
		a.connect("mouse_entered", _on_mouse_entered.bind(a))
		a.connect("mouse_exited", _on_mouse_exited)
	
	# Set up tooltips for stats buffs
	set_tooltip(cur_unit)

## display highlights of skill range when hovered over
func _on_mouse_entered(icon_hovered: SkillPreview):
	EventBus.emit_signal("remove_cell_highlights", name)
	EventBus.emit_signal("remove_cell_highlights", name+"_valid_targets")
	
	var all_neighbors := HexNavi.get_all_neighbors_in_range(HexNavi.global_to_cell(cur_unit.global_position), icon_hovered.skill.range, 999)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, CellHighlight.ATTACK_PREVIEW_HIGHLIGHT, name)
	if cur_unit_container:
		var valid_targets = cur_unit_container.get_targets_of_type(all_neighbors, icon_hovered.skill.targets, cur_unit)
		if valid_targets.size() > 0:
			if icon_hovered.skill.targets in [SkillInfo.TargetType.ENEMIES, SkillInfo.TargetType.ANY_UNIT, SkillInfo.TargetType.ALLIES, SkillInfo.TargetType.EXCEPT_SELF, SkillInfo.TargetType.ALLIES_EXCEPT_SELF, SkillInfo.TargetType.SELF]:
				EventBus.emit_signal("show_cell_highlights", valid_targets, CellHighlight.ATTACK_HIGHLIGHT, name+"_valid_targets")

func _on_mouse_exited():
	EventBus.emit_signal("remove_cell_highlights", name)
	EventBus.emit_signal("remove_cell_highlights", name+"_valid_targets")

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
	self.show()
	preview_window.hide()
	
	stat_to_label = {
		"max_health": hp_label,
		"attack_power": atk_label,
		"magic_power": mag_label,
		"movement_range": mov_label
	}

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

func set_class_sprite(name: String):
	var texture: AtlasTexture
	match name:
		"Protagonist":
			texture = preload("res://ui/single_sprite_atlus/base_sprite.atlastex")
		"Ranger":
			texture = preload("res://ui/single_sprite_atlus/ranger_sprite.atlastex")
		"Fighter":
			texture = preload("res://ui/single_sprite_atlus/fighter_sprite.atlastex")
		"Mage":
			texture = preload("res://ui/single_sprite_atlus/mage_sprite.atlastex")
		"Healer":
			texture = preload("res://ui/single_sprite_atlus/healer_sprite.atlastex")
		"Tank":
			texture = preload("res://ui/single_sprite_atlus/tank_sprite.atlastex")
		_:
			texture = preload("res://ui/single_sprite_atlus/base_sprite.atlastex")
	class_sprite.texture = texture

func set_tooltip(unit: Unit):
	var tooltip_dict: Dictionary[String, String] = {
		"max_health": "",
		"attack_power": "",
		"magic_power": "",
		"movement_range": ""
	}
	for buff in unit.bonus_stat:
		if buff.stat == "damage_reduction":
			continue
		if int(buff.value) > 0:
			tooltip_dict[buff.stat] += "+%s from %s\n" %[int(buff.value),buff.source]
		else: tooltip_dict[buff.stat] += "%s from %s\n" %[int(buff.value),buff.source]

	for key in tooltip_dict.keys():
		stat_to_label[key].tooltip_text = tooltip_dict[key]
