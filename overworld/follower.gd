extends CharacterBody2D

class_name Follower

const PLAYER_HOLD_D = 80
const TELE_D = 600
const FOLLOW_D = 90
const DISPERSE_D = 60

const SPEED = 80
const SCALE := 3
const TURN_COOLDOWN = 0.15  # seconds between allowed between steps

var player

var move_timer = 0.0
var turning = false

var turn_dir = Vector2.RIGHT
var lastpos = Vector2(0,0)
var vel_moving_average = Vector2(0,0)
var diff = Vector2(0,0)

var thrown = false
var free = true
var selected = false

var throw_dir = Vector2(0,0)
var throw_time = 0
var time_since_hold = 0
var time_since_throw = 0


func free_hold():
	free=true
	thrown=false
	get_node("CollisionShape2D").disabled=false
	set_collision_mask_value(1,true)
	player.set_collision_mask_value(2,true)
	player.set_collision_layer_value(2,true)
func process_hold():
	if (selected and diff.length()>PLAYER_HOLD_D):
		free_hold()
	if not free and not thrown and (player.holding!=1):
		free_hold()
	if (Input.is_action_just_pressed("LMB")):
		if selected and (player.holding==0):
			free=false
			player.holding+=1
			time_since_hold=0
			get_node("CollisionShape2D").disabled=true
		if (not free) and (player.holding==1) and (time_since_hold>1):
			thrown=true
			player.holding-=1
			var throw_direction = get_global_mouse_position()-player.global_position
			var throw_angle = deg_to_rad(min(45,throw_direction.length()))
			var vel_mag = max(1,min(30,throw_direction.length()))*10
			throw_time = 2*sin(throw_angle)* vel_mag/1000
			velocity = throw_direction.normalized() * vel_mag + Vector2(0,-sin(throw_angle))* vel_mag
			time_since_throw=0
			get_node("CollisionShape2D").disabled=false
			set_collision_mask_value(1,false)
			player.set_collision_mask_value(2,false)
			player.set_collision_layer_value(2,false)
	if (time_since_throw > throw_time) and thrown:
		free_hold()
func process_rot(delta):
	vel_moving_average = vel_moving_average*0.8 + 0.2*(position-lastpos) / delta
	
	var last_dir = turn_dir
	if vel_moving_average.x > 0:
		turn_dir = Vector2.RIGHT
	elif vel_moving_average.x < 0:
		turn_dir = Vector2.LEFT
		
	if vel_moving_average.x > 0.0:
		$Sprite2D.scale = Vector2(SCALE, SCALE)
	else:
		$Sprite2D.scale = Vector2(-SCALE, SCALE)
		
	# Only update direction if it has changed and the cooldown timer has expired.
	if (turn_dir != last_dir) and (not turning):
		#$Sprite2D.scale = Vector2(-SCALE, SCALE)
			
		# Trigger the turning tween.
		turning = true
		var a = create_tween()
		a.tween_property($Sprite2D, "position", $Sprite2D.position + Vector2(0, 0.1), 0.1)
		await a.finished
		a = create_tween()
		a.tween_property($Sprite2D, "position", $Sprite2D.position - Vector2(0, 0.1), 0.1)
		await a.finished
		turning = false
		# Reset the turn cooldown.
func _physics_process(delta):
	player = get_parent().get_node("Player")
	
	process_hold()
	
	diff = player.position - position
	move_timer -= delta
	#print(free)
	if not free:
		if (player.holding==1):
			time_since_hold += delta
			position = player.position + Vector2(0, -30)
		if thrown:
			time_since_throw += delta
			velocity -= Vector2(0,-1000)*delta
	elif (move_timer <= 0):
		var direction = diff.normalized()
		if (diff.length() > FOLLOW_D or diff.length()<DISPERSE_D):
			if (diff.length()>TELE_D):
				position = player.position-direction*FOLLOW_D
			velocity.x = direction.x * SPEED
			velocity.y = direction.y * SPEED
			
			if diff.length()<DISPERSE_D:
				velocity = -velocity
			
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
		move_timer = TURN_COOLDOWN
	
	process_rot(delta)
	anim_handler(delta)
	lastpos = position
	move_and_slide()

func sort_z_layer():
	z_index = int(position.y)

func anim_handler(delta):
	if not free:
		$Sprite2D.hframes = 1
		$AnimationPlayer.play("ow_anim/thrown")
		return
	
	$Sprite2D.hframes = 4
	var idle = (vel_moving_average.length() < SPEED*0.25)
	if (abs(vel_moving_average.y) > SPEED * sqrt(2) / 2 + 1e-2) and not idle:
		if vel_moving_average.y >= 0:
			$AnimationPlayer.play("ow_anim/front_walk")
		else:
			$AnimationPlayer.play("ow_anim/back_walk")
	elif vel_moving_average != Vector2.ZERO and not idle:
		$AnimationPlayer.play("ow_anim/side_walk")
	else:
		$AnimationPlayer.play("ow_anim/front_idle")

func _on_area_2d_mouse_entered() -> void:
	if (diff.length()<PLAYER_HOLD_D):
		selected=true

func _on_area_2d_mouse_exited() -> void:
	selected=false
