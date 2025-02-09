extends TextureButton

class_name TalentNode

## Color of the activated line
const ACTIVATED_COLOR := Color(0.868, 0.591, 0.129)
## Color of the deactivated line
const DEACTIVATED_COLOR := Color(0.385, 0.385, 0.385)

## Node name should be in snake_case for consistency
@export var node_name: String = ""
## The maximum level players can upgrade to on this talent node
@export var max_level: int = 2

@onready var label = $Label
@onready var line = $Line2D

## Current level of the talent node
var level: int = 0:
	set(value):
		level = value
		label.text = str(level) + "/" + str(max_level)
		# affect system data here
var left_click: bool = false
var right_click: bool = true

func _ready():
	EventBus.connect("disable_all_nodes", _on_disable_node)
	EventBus.connect("reset_talent_levels", _on_level_reset)
	if get_parent() is TalentNode:
		line.add_point(global_position + size/2)
		line.add_point(get_parent().global_position + size/2)
	init()

## custom function to reset the state and level of the node
func init():
	level = 0
	disabled = false
	line.default_color = DEACTIVATED_COLOR
	$Panel.show_behind_parent = false

func _process(delta):
	if get_parent() is TalentNode:
		if get_parent().disabled:
			disabled = true
			return
		
		if get_parent().level <= 0:
			toggle_disabled(true)
		else: 
			toggle_disabled(false)

func _on_pressed():
	if level < max_level:
		toggle_disabled(false)
		level += 1
		EventBus.emit_signal("talent_node_pressed")

func toggle_disabled(state: bool):
	if state:
		disabled = true
		line.default_color = DEACTIVATED_COLOR
		$Panel.show_behind_parent = false
	else:
		disabled = false
		line.default_color = ACTIVATED_COLOR
		$Panel.show_behind_parent = true

func _on_disable_node():
	disabled = true
	if level <= 0:
		toggle_disabled(true)

func _on_level_reset():
	init()
