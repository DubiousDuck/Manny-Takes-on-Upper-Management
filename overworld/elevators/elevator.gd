extends Node2D

class_name ElevatorScene

@export_file("*.tscn") var scene_to_go: String
@export var speaker_name: String

func _ready():
	AudioPreload.stop()
	$ElevatorGate.speaker_name = speaker_name

func go_to_next_scene():
	Global.scene_transition(scene_to_go)
	
## Camera related things
var jitter_tween: Tween = null
var jitter_offset := 2.0
var jitter_duration := 0.08
var original_position := Vector2.ZERO

@onready var camera = $Camera2D

func start_elevator_jitter():
	original_position = camera.position
	
	jitter_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_loops()
	_run_jitter_loop()

func _run_jitter_loop():
	var left_pos = original_position + Vector2(-jitter_offset, 0)
	var right_pos = original_position + Vector2(jitter_offset, 0)

	jitter_tween.tween_property(camera, "position", left_pos, jitter_duration)
	jitter_tween.tween_property(camera, "position", right_pos, jitter_duration)
	jitter_tween.tween_property(camera, "position", original_position, jitter_duration)
	jitter_tween.tween_interval(2)

func stop_elevator_jitter():
	jitter_tween.stop()
	camera.position = original_position
