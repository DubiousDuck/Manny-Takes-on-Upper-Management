extends Area2D

## A generic class for all interactable items/areas/npcs
class_name Interactable

var is_in_range: bool = false
var mouse_selected: bool = false

## virtual function that should be customized by each inherited class
func _interact_call_back():
	pass

func _input(event):
	if is_in_range:
		if Input.is_action_just_pressed("ui_accept"):
			_interact_call_back()
		elif Input.is_action_just_pressed("LMB") and mouse_selected:
			_interact_call_back()

func _on_body_entered(body):
	# highlight sprite when player entered
	if body is Player:
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
