extends CharacterBody2D

class_name Follower

const FOLLOW_D = 90
const DISPERSE_D = 60

const SPEED = 95
const SCALE := 3
const TURN_COOLDOWN = 0.20  # seconds between allowed between steps

var dir = Vector2.RIGHT
var turn_timer = 0.0
var turning = false

func _physics_process(delta):
	# Decrease the cooldown timer.
	turn_timer -= delta
	
	var player = get_parent().get_node("Player")
	var diff = player.position - position
	var direction = diff.normalized()
	
	if (turn_timer <= 0):
		if (diff.length() > FOLLOW_D or diff.length()<DISPERSE_D):
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
		
	move_and_slide()
	anim_handler()

func anim_handler():
	if abs(velocity.y) > SPEED * sqrt(2) / 2 + 1e-2:
		$AnimationPlayer.play("unit_anim/front_walk")
	elif velocity != Vector2.ZERO:
		$AnimationPlayer.play("unit_anim/side_walk")
	else:
		$AnimationPlayer.play("unit_anim/front_idle")
