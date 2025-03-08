extends CharacterBody2D

class_name Solliciter

const FOLLOW_D = 60   # Distance at which it follows the player
const SPEED = 80
const SCALE := 3
const TURN_COOLDOWN = 0.01  # seconds between allowed between steps
const MAX_RADIUS = 100  # Maximum movement radius from spawn

var player
var spawn_position = Vector2.ZERO  # Initial spawn position

@export var unit_data: UnitData
@export var move_timer = 0.0
@export var turning = false
@export var turn_dir = Vector2.RIGHT
@export var lastpos = Vector2(0, 0)
@export var vel_moving_average = Vector2(0, 0)
@export var diff = Vector2(0, 0)

@export_file("*.tscn") var scene_to_go

@onready var sprite_2d = $Area2D/Sprite2D

func _ready():
	spawn_position = position  # Store initial position as reference
	$Area2D.scene_to_go = scene_to_go

func _physics_process(delta):
	if player == null:
		player = get_parent().get_node("Player")

	diff = player.position - position
	var to_spawn = spawn_position- position   # Distance from spawn

	move_timer -= delta

	if move_timer <= 0:
		# If too far from spawn, move back toward it
		if to_spawn.length() > MAX_RADIUS:
			velocity = Vector2.ZERO  # Stay still if within range
			if to_spawn.dot(diff) >0:
				velocity = diff.normalized() * SPEED
		elif diff.length() < FOLLOW_D:
			velocity = -diff.normalized() * SPEED
		else:
			velocity = diff.normalized() * SPEED
		move_timer = TURN_COOLDOWN

	process_rot(delta)
	anim_handler(delta)
	lastpos = position
	move_and_slide()

func process_rot(delta):
	vel_moving_average = vel_moving_average * 0.8 + 0.2 * (position - lastpos) / delta

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

func anim_handler(_delta):
	sprite_2d.hframes = 4
	var idle = (vel_moving_average.length() < SPEED * 0.25)
	if abs(vel_moving_average.y) > SPEED * sqrt(2) / 2 + 1e-2 and not idle:
		$AnimationPlayer.play("ow_anim/front_walk" if vel_moving_average.y >= 0 else "ow_anim/back_walk")
	elif vel_moving_average != Vector2.ZERO and not idle:
		$AnimationPlayer.play("ow_anim/side_walk")
	else:
		$AnimationPlayer.play("ow_anim/front_idle")
