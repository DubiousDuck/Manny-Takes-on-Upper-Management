class_name Actor extends CharacterBody2D

func start_cutscene():
	Global.can_actors_move = false

func end_cutscene():
	Global.can_actors_move = true

func face_right():
	get_node("Sprite2D").flip_h = 0
	
func face_left():
	get_node("Sprite2D").flip_h = 1

func set_anim(anim : String):
	get_node("AnimationPlayer").play(anim)

func _process(delta):
	if !Global.can_actors_move:
		get_node("CollisionShape2D").disabled = true
	else:
		get_node("CollisionShape2D").disabled = false
