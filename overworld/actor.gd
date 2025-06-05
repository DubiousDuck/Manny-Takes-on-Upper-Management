class_name Actor extends CharacterBody2D

const FOOTSTEP_SFX = preload("res://assets/sfx/footstep_sfx.mp3")

func start_cutscene():
	Global.cutscene_start()

func end_cutscene():
	Global.cutscene_end()

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

func footstep_sfx_handle(state: bool):
	if state:
		footstep_sfx_play()
	else:
		$SfxPlayer.stop()

func footstep_sfx_play():
	if $SfxPlayer.stream != FOOTSTEP_SFX or !$SfxPlayer.playing:
		$SfxPlayer.stream = FOOTSTEP_SFX
		$SfxPlayer.play()

func sfx_stop():
	$SfxPlayer.stop()
