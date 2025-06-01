extends Actor

class_name Follower

const PLAYER_HOLD_D = 40
const TELE_D = 300
const FOLLOW_D = 45
const DISPERSE_D = 30
const hold_offset = Vector2(0, -15)

const SPEED = 100
const SCALE := 3
const TURN_COOLDOWN = 0.15  # seconds between allowed steps

var player
var anim_lib: String = "ow_anim"

# unit attributes
@export var unit_data: UnitData

@export var move_timer = 0.0
@export var turning = false

@export var turn_dir = Vector2.RIGHT
@export var lastpos = Vector2(0, 0)
@export var vel_moving_average = Vector2(0, 0)
@export var diff = Vector2(0, 0)

@export var thrown = false
@export var free = true
@export var selected = false

@export var throw_dir = Vector2(0, 0)
@export var throw_time = 0
@export var time_since_hold = 0
@export var time_since_throw = 0

@export var is_dying: bool = false  # Flag to prevent other logic from running
#var death_in_progress = false
# Kill function, initiates death sequence
func kill():
	if is_dying:
		return
	get_parent().followers.erase(unit_data)
	Global.eaten_units.append(unit_data)
	Global.current_party.erase(unit_data)
	is_dying = true

# Handles the dying process (shrink, fade, and fall)
func process_kill():
	if free and is_dying:# and not death_in_progress:  # Set flag to indicate death process
		#death_in_progress=true
		# Play the crying animation if it exists
		#if $AnimationPlayer.has_animation("%s/cry" % anim_lib):
		$Sprite2D.hframes = 4
		$AnimationPlayer.play("%s/hurt" % anim_lib)

		# Create a tween for fade out, shrinking, and downward movement
		var tween = self.create_tween()

		# Fade out the character by gradually reducing alpha
		tween.parallel().tween_property(self, "modulate:a", 0.0, 2)

		# Shrink the sprite by reducing the scale
		#var t1 = $Sprite2D.create_tween()
		tween.parallel().tween_property($Sprite2D, "scale", Vector2(0.1, 0.1), 2)

		# Move the character downwards (as if falling into a hole)
		tween.parallel().tween_property(self, "position", position + Vector2(0, 20), 2)

		# Wait for the tween to finish before freeing the node
		await tween.finished
		
		print("DEAD")
		#print(Global.current_party)
		print(get_parent().followers)
		#print(Global.current_party)
		queue_free()  # Remove the node from the scene

# Hold and throw logic
func free_hold():
	free = true
	thrown = false
	get_node("CollisionShape2D").disabled = false
	set_collision_mask_value(1, true)
	player.set_collision_mask_value(2, true)
	player.set_collision_layer_value(2, true)

func process_hold():
	if (selected and diff.length() > PLAYER_HOLD_D):
		free_hold()
	if not free and not thrown and (player.holding != 1):
		free_hold()
	if (Input.is_action_just_pressed("LMB")):
		if selected and (player.holding == 0):
			free = false
			player.holding += 1
			time_since_hold = 0
			get_node("CollisionShape2D").disabled = true
		if (not free) and (player.holding == 1) and (time_since_hold > 1):
			thrown = true
			player.throwing = true
			player.holding -= 1
			var throw_direction = get_global_mouse_position() - player.global_position
			var throw_angle = deg_to_rad(min(45, throw_direction.length()))
			var vel_mag = max(1, min(30, throw_direction.length())) * 10
			throw_time = 2 * sin(throw_angle) * vel_mag / 1000
			velocity = throw_direction.normalized() * vel_mag + Vector2(0, -sin(throw_angle)) * vel_mag
			time_since_throw = 0
			get_node("CollisionShape2D").disabled = false
			set_collision_mask_value(1, false)
			player.set_collision_mask_value(2, false)
			player.set_collision_layer_value(2, false)
	if (time_since_throw > throw_time) and thrown:
		free_hold()

# Handle rotation
func process_rot(delta):
	if is_dying:
		return
	vel_moving_average = vel_moving_average * 0.8 + 0.2 * (position - lastpos) / delta

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
func _process(delta):
	player = get_parent().get_node("Player")

	process_kill()
	process_hold()

	diff = player.position - position
	move_timer -= delta

	if not free:
		if (player.holding == 1):
			time_since_hold += delta
			position = player.position + hold_offset
		if thrown:
			time_since_throw += delta
			velocity -= Vector2(0, -1000) * delta
	elif is_dying:
		velocity*=0
		move_and_slide()
		return
	elif (move_timer <= 0):
		var direction = diff.normalized()
		if (diff.length() > FOLLOW_D or diff.length() < DISPERSE_D):
			if (diff.length() > TELE_D):
				position = player.position - direction * FOLLOW_D
			velocity.x = direction.x * SPEED
			velocity.y = direction.y * SPEED

			if diff.length() < DISPERSE_D:
				velocity = -velocity

		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.y = move_toward(velocity.y, 0, SPEED)
		move_timer = TURN_COOLDOWN

	process_rot(delta)
	anim_handler(delta)
	lastpos = position
	move_and_slide()

# Sort by Z layer for depth rendering
func sort_z_layer():
	z_index = int(position.y)

# Handle animations based on state
func anim_handler(_delta):
	if is_dying:
		return
	if not free:
		$Sprite2D.hframes = 1
		$AnimationPlayer.play("%s/thrown" % anim_lib)
		return

	$Sprite2D.hframes = 4
	var idle = (vel_moving_average.length() < SPEED * 0.25)
	if (abs(vel_moving_average.y) > SPEED * sqrt(2) / 2 + 1e-2) and not idle:
		if vel_moving_average.y >= 0:
			$AnimationPlayer.play("%s/front_walk" % anim_lib)
		else:
			$AnimationPlayer.play("%s/back_walk" % anim_lib)
	elif vel_moving_average != Vector2.ZERO and not idle:
		$AnimationPlayer.play("%s/side_walk" % anim_lib)
	else:
		$AnimationPlayer.play("%s/front_idle" % anim_lib)

# Handle mouse interaction
func _on_area_2d_mouse_entered() -> void:
	if (diff.length() < PLAYER_HOLD_D):
		selected = true

func _on_area_2d_mouse_exited() -> void:
	selected = false

# Set the animation library based on the unit class
func set_anim_lib():
	if unit_data:
		match unit_data.unit_class:
			"Healer":
				anim_lib = "Healer_ow"
			"Fighter":
				anim_lib = "Fighter"
			"Ranger":
				anim_lib = "Ranger"
			"Mage":
				anim_lib = "Mage"
			_:
				anim_lib = "ow_anim"
