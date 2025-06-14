extends Area2D

## A generic class for all interactable items/areas/npcs
class_name Interactable

var is_in_range: bool = false
var mouse_selected: bool = false
var hint_message: String = "Press SPACE or Left Click to interact with NPCs/objects!"

## virtual function that should be customized by each inherited class
func _interact_call_back():
	HintManager.hide_hint("interactable_approached")
	pass

func _input(_event):
	#print(mouse_selected)
	if is_in_range and !Global.ui_busy and !Global.in_cutscene:
		if Input.is_action_just_pressed("ui_accept"):
			#get_viewport().set_input_as_handled()
			_interact_call_back()
		elif Input.is_action_just_pressed("LMB") and mouse_selected:
			_interact_call_back()

func _on_body_entered(body):
	# highlight sprite when player entered
	if body is Player and !Global.ui_busy and !Global.in_cutscene:
		HintManager.trigger_hint("interactable_approached", hint_message)
		$Sprite2D.modulate = Color(0.5, 0.5, 0.5)
		is_in_range = true

func _on_body_exited(body):
	if body is Player:
		$Sprite2D.modulate = Color(1, 1, 1)
		is_in_range = false

func _on_area_2d_mouse_entered() -> void:
	mouse_selected=true

func _on_area_2d_mouse_exited() -> void:
	mouse_selected=false
