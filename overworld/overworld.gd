extends Node2D

## General class for any overworld
class_name Overworld

@export var follower_count: int = 10

var follower_spawn_radius: float = 110

func spawn_followers(num_followers: int) -> void:
	# Get a reference to the player node. Adjust the node path as needed.
	var player = get_node("Player")
	var player_pos = player.position
	var follower_scene = preload("res://overworld/Follower.tscn")

	for i in range(num_followers):
		var angle = randf_range(0, 2 * PI)
		var distance = randf_range(0, follower_spawn_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var follower = follower_scene.instantiate()
		follower.position = player_pos + offset
		add_child(follower)

func _ready():
	#make the game remember this is the last overworld loaded
	Global.set_last_overworld(get_tree().current_scene.scene_file_path)
	
	spawn_followers(follower_count)
