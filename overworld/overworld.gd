extends Node2D

## General class for any overworld
class_name Overworld

var follower_spawn_radius: float = 110

@export var followers = {}

func _set_owner_recursive(node : Node, new_owner : Node, old_paths : Dictionary):
	if new_owner == null:
		return
		
	var should_set := new_owner.is_ancestor_of(node)
	
	if should_set:
		node.owner = new_owner
		if node.scene_file_path:
			old_paths[new_owner.get_path_to(node)] = node.scene_file_path
			node.scene_file_path = ""
	for c in node.get_children():
		_set_owner_recursive(c, new_owner, old_paths)

func update_followers() -> void:
	# Get a reference to the player node. Adjust the node path as needed.
	var player = get_node("Player")
	var player_pos = player.position
	var follower_scene = preload("res://overworld/Follower.tscn")

	for unit_data in Global.current_party:
		if unit_data in followers or unit_data.unit_class == 'Protagonist':
			continue
		var angle = randf_range(0, 2 * PI)
		var distance = randf_range(0, follower_spawn_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var follower = follower_scene.instantiate()
		follower.position = player_pos + offset
		follower.unit_data = unit_data
		follower.set_anim_lib()
		add_child(follower)
		_set_owner_recursive(follower,self,{})
		followers[unit_data] = follower
		
	for child in get_children():
		#if child in followers.values():  # Check if the child is in the followers dictionary
		if (child is Follower) and not child.unit_data in Global.current_party:
			var unit_data = child.unit_data  # Get the corresponding unit_data
			followers.erase(unit_data)  # Remove from dictionary
			child.queue_free()  # Properly delete the follower
			
func _ready():
	EventBus.emit_signal("back_to_overworld")
	#make the game remember this is the last overworld loaded
	Global.set_last_overworld_scene(get_tree().current_scene)
	update_followers()

func _on_to_talent_page_pressed():
	Global.set_last_overworld_scene(get_tree().current_scene)
	var talent_scene = preload("res://overworld/skill_tree/skill_tree.tscn")
	get_tree().change_scene_to_packed(talent_scene)

func _on_save_pressed():
	# TODO: change DEBUG_INT
	Global.save_player_data(Global.DEBUG_INT)

func _on_party_manage_pressed():
	Global.set_last_overworld_scene(get_tree().current_scene)
	var party_manage = preload("res://overworld/party_comp/party_comp.tscn")
	get_tree().change_scene_to_packed(party_manage)
