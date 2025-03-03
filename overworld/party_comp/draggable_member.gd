extends Node2D

class_name DraggableMember

@export var unit_data: UnitData

var is_draggable := false
var is_dragging := false

func _ready():
	$Label.text = unit_data.unit_class
	
func _process(_delta):
	#if unit is protanoist, can't be dragged out of current party
	if unit_data.unit_class == "Protagonist":
		return
	if is_draggable:
		if Input.is_action_just_pressed("LMB"):
			EventBus.emit_signal("dragging_start")
			is_dragging = true
		if Input.is_action_pressed("LMB") and is_dragging:
			global_position = get_global_mouse_position()
		elif Input.is_action_just_released("LMB"):
			is_dragging = false
			EventBus.emit_signal("dragging_stop")

func _on_area_2d_mouse_entered():
	is_draggable = true

func _on_area_2d_mouse_exited():
	if !is_dragging:
		is_draggable = false
