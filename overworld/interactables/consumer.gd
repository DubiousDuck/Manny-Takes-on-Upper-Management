extends Interactable

class_name Hole

@export_file("*.tscn") var scene_to_go

@export var locked=true
@export var req :Array[String] = []
@export var level_name :String

var mouse_on = false

func check_locked():
	if req.all(func(x): return Global.finished_levels.has(x)):
		locked=false
func _interact_call_back():
	Global.start_dialogue(["...."])
	await EventBus.ui_element_ended

func _on_control_mouse_entered() -> void:
	mouse_on = true

func _on_control_mouse_exited() -> void:
	mouse_on = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	var body = area.get_parent().get_parent()
	#print(body.get_class())
	print("Class type: " + body.get_class())  # Should print 'Follower'
	print("Is instance of Follower? " + str(body is Follower))  # Should return true
	if body is Follower:
		print('follower found')
		body.kill()
	#print(body)
