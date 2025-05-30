extends Panel

class_name ClassProfile

signal pressed(unit_name: String)

@export var unit_name: String = ""
@export var protrait: Texture2D = preload("res://assets/concept_art/fighter_concept.png")

var can_be_selected: bool = false

func _ready():
	$ExpandableArea/Profile.texture = protrait
	$ExpandableArea/Label.text = unit_name

func _on_mouse_box_mouse_entered():
	$AnimationPlayer.play("expand")

func _on_mouse_box_mouse_exited():
	$AnimationPlayer.play("contract")

func _on_mouse_box_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and can_be_selected:
		emit_signal("pressed", unit_name)
		AudioPreload.play_sfx("confirm")

func set_locked(state: bool):
	if state:
		can_be_selected = false
		$ExpandableArea/Profile.modulate = Color.BLACK
		$ExpandableArea/Label.text = "???"
	else:
		can_be_selected = true
		$ExpandableArea/Profile.modulate = Color.WHITE
		$ExpandableArea/Label.text = unit_name
