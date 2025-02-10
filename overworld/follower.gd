extends CharacterBody2D

class_name Follower

const TELE_D = 600
const FOLLOW_D = 90
const DISPERSE_D = 60

const SPEED = 80
const SCALE := 3
const TURN_COOLDOWN = 0.15  # seconds between allowed between steps

var dir = Vector2.RIGHT
var turn_timer = 0.0
var turning = false

var lastpos = Vector2(0,0)
var vel_moving_average = Vector2(0,0)

func _physics_process(delta):
	# Decrease the cooldown timer.
	turn_timer -= delta
	
	var player = get_parent().get_node("Player")
	var diff = player.position - position
	var direction = diff.normalized()
	
	#sort_z_layer()
	
	if (turn_timer <= 0):
		if (diff.length() > FOLLOW_D or diff.length()<DISPERSE_D):
			if (diff.length()>TELE_D):
				position = player.position-direction*FOLLOW_D
			velocity.x = direction.x * SPEED
			velocity.y = direction.y * SPEED
			
			if diff.length()<DISPERSE_D:
				velocity = -velocity
			
			var last_dir = dir
			if velocity.x > 0:
				dir = Vector2.RIGHT
			elif velocity.x < 0:
				dir = Vector2.LEFT
				
			# Only update direction if it has changed and the cooldown timer has expired.
			if (dir != last_dir) and (not turning):
				if dir.dot(Vector2.RIGHT) > 0.0:
					$Sprite2D.scale = Vector2(SCALE, SCALE)
				else:
					$Sprite2D.scale = Vector2(-SCALE, SCALE)
				
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
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
		turn_timer = TURN_COOLDOWN
	
	anim_handler(delta)
	lastpos = position
	move_and_slide()

func sort_z_layer():
	z_index = int(position.y)

func anim_handler(delta):
	vel_moving_average = vel_moving_average*0.8 + 0.2*(lastpos-position) / delta
	var idle = (vel_moving_average.length() < SPEED*0.25)
	if abs(vel_moving_average.y) > SPEED * sqrt(2) / 2 + 1e-2 and not idle:
		$AnimationPlayer.play("unit_anim/front_walk")
	elif vel_moving_average != Vector2.ZERO and not idle:
		$AnimationPlayer.play("unit_anim/side_walk")
	else:
		$AnimationPlayer.play("unit_anim/front_idle")
