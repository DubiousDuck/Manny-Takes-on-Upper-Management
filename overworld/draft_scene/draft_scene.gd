extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func back_to_overworld():
	get_tree().change_scene_to_file(Global.get_last_overworld())

func _on_mage_pressed():
	back_to_overworld()


func _on_fighter_pressed():
	back_to_overworld()


func _on_ranger_pressed():
	back_to_overworld()
