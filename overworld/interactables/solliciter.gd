extends CharacterBody2D

class_name Solliciter

const FOLLOW_D = 30   # Distance at which it follows the player
const SPEED = 60
const SCALE := 3
const TURN_COOLDOWN = 0.01  # seconds between allowed between steps
const MAX_RADIUS = 100  # Maximum movement radius from spawn

var player
var spawn_position = Vector2.ZERO  # Initial spawn position

@export_category("Character Parameters")
@export var unit_data: UnitData
@export var move_timer = 0.0
@export var turning = false
@export var turn_dir = Vector2.RIGHT
@export var lastpos = Vector2(0, 0)
@export var vel_moving_average = Vector2(0, 0)
@export var diff = Vector2(0, 0)

@export_category("Level Parameters")
@export_file("*.tscn") var scene_to_go
@export var level_name: String
@export var req: Array[String] = []
@export_multiline var locked_dialogue: Array[String]
@export_multiline var interact_dialogue: Array[String]
@export var correct_choice: String

@onready var sprite_2d = $Area2D/Sprite2D
@onready var warning = $Warning
@onready var area_2d = $Area2D


func _ready():
	animate_warning()
	spawn_position = global_position  # Store initial position as reference
	$Area2D.scene_to_go = scene_to_go
	$Area2D.level_name = level_name
	$Area2D.req = req
	if locked_dialogue:
		$Area2D.locked_dialogue = locked_dialogue
	if interact_dialogue:
		$Area2D.interact_dialogue = interact_dialogue
	if correct_choice:
		$Area2D.correct_choice = correct_choice

func _physics_process(delta):
	if player == null:
		player = get_parent().get_node("Player")

	diff = player.global_position - global_position
	var to_spawn = spawn_position - global_position   # Distance from spawn

	move_timer -= delta

	var chase = false
	
	# Check if level requirement is met and if the level is completed
	area_2d.check_locked()
	area_2d.check_completed()
	if !area_2d.locked:
		chase = true
		if area_2d.completed:
			chase = false
	
	
	if move_timer <= 0:
		# If too far from spawn, move back toward it
		if diff.length() > FOLLOW_D and diff.length() < MAX_RADIUS and chase:
			if !Global.finished_levels.has(level_name):
				$Warning.visible = true
			velocity = diff.normalized() * SPEED
		elif diff.length() < FOLLOW_D or to_spawn.length() < MAX_RADIUS/3:
			velocity = Vector2.ZERO
		elif to_spawn.length() > MAX_RADIUS:
			$Warning.visible = false
			velocity = to_spawn.normalized() * SPEED
			#velocity = Vector2.ZERO  # Stay still if within range
			#if to_spawn.dot(diff) >0:
				#velocity = diff.normalized() * SPEED
		
		#elif diff.length() <= FOLLOW_D:
			#velocity = -diff.normalized() * SPEED
		move_timer = TURN_COOLDOWN

	process_rot(delta)
	anim_handler()
	lastpos = global_position
	move_and_slide()

func process_rot(delta):
	vel_moving_average = vel_moving_average * 0.8 + 0.2 * (global_position - lastpos) / delta

	var last_dir = turn_dir
	turn_dir = Vector2.RIGHT if vel_moving_average.x > 0 else Vector2.LEFT

	sprite_2d.scale = Vector2(SCALE, SCALE) if vel_moving_average.x > 0 else Vector2(-SCALE, SCALE)

	if turn_dir != last_dir and not turning:
		turning = true
		var a = create_tween()
		a.tween_property(sprite_2d, "position", sprite_2d.position + Vector2(0, 0.1), 0.1)
		await a.finished
		a = create_tween()
		a.tween_property(sprite_2d, "position", sprite_2d.position - Vector2(0, 0.1), 0.1)
		await a.finished
		turning = false


func animate_warning():
	var a = warning.create_tween()
	a.set_loops() # Makes the tween loop indefinitely
	a.tween_property(warning, "scale", Vector2(1.5, 2), 0.25).set_trans(Tween.TRANS_SINE)
	a.tween_property(warning, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_SINE)
	
func anim_handler():
	
	sprite_2d.hframes = 4
	var idle = (vel_moving_average.length() < SPEED * 0.25)
	if abs(vel_moving_average.y) > SPEED * sqrt(2) / 2 + 1e-2 and not idle:
		$AnimationPlayer.play("ow_sollicitor/front_walk" if vel_moving_average.y >= 0 else "ow_sollicitor/back_walk")
	elif vel_moving_average != Vector2.ZERO and not idle:
		$AnimationPlayer.play("ow_sollicitor/side_walk")
	else:
		$AnimationPlayer.play("ow_sollicitor/front_idle")
