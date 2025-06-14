extends Actor

class_name Player

const SPEED = 100
const SCALE := 3

@export var dir = Vector2.RIGHT
@export var turning = false

@export var holding = 0
@export var throwing = false

func _process(_delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector2(input_dir.x, input_dir.y).normalized()
	
	#sort_z_layer()
	
	if direction and Global.can_actors_move:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
		
		var last_dir = dir
		
		if velocity.x > 0:
			dir = Vector2.RIGHT
			$Sprite2D.flip_h = 0
		elif velocity.x < 0:
			dir = Vector2.LEFT
			$Sprite2D.flip_h = 1
			
		if dir != last_dir:
			if not turning:
				var a = create_tween()
				turning = true
				a.tween_property($Sprite2D, "position", $Sprite2D.position + Vector2(0,.1), 0.1)
				await a.finished
				a = create_tween()
				a.tween_property($Sprite2D, "position", $Sprite2D.position - Vector2(0,.1), 0.1)
				await a.finished
				turning = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if Global.can_actors_move:
		move_and_slide()
		anim_handler()
	else:
		velocity = Vector2.ZERO

func anim_handler():
	# enable below for throwing animation
	#if throwing:
		#$AnimationPlayer.play("ow_anim/throw")
		#return
	if holding>0:
		$AnimationPlayer.play("ow_anim/holding_empty")
		return
	
	if abs(velocity.y) >= abs(velocity.x):
		if velocity.y > 0:
			$AnimationPlayer.play("ow_anim/front_walk")
			footstep_sfx_handle(true)
		elif velocity.y < 0:
			$AnimationPlayer.play("ow_anim/back_walk")
			footstep_sfx_handle(true)
		else:
			footstep_sfx_handle(false)
			$AnimationPlayer.play("ow_anim/front_idle")
	elif velocity != Vector2.ZERO:
		footstep_sfx_handle(true)
		$AnimationPlayer.play("ow_anim/side_walk")
	else:
		footstep_sfx_handle(false)
		$AnimationPlayer.play("ow_anim/front_idle")

func _throwing_done() -> void:
	throwing=false
