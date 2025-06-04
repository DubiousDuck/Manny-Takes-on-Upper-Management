extends Node2D

## General class for any overworld
class_name Overworld

var follower_spawn_radius: float = 50

@onready var main_interface = $MainInterface

@export var followers = {}
@export var tutorial_queue: Array[TutorialContent] = []
@export var max_party_num: int = 3

func update_followers() -> void:
	# Get a reference to the player node. Adjust the node path as needed.
	var player = get_node("Player")
	var player_pos = player.position
	var follower_scene = preload("res://overworld/Follower.tscn")
	
	# Clear existing followers since we're creating followers everytime
	for child in get_children():
		if child is Follower:
			child.queue_free()
	followers.clear()

	# Add new followers for party members who don't already have a follower
	for unit_data in Global.current_party:
		if unit_data in followers or unit_data.unit_class == 'Protagonist':
			continue
			
		# Generate random position around the player
		var angle = randf_range(0, 2 * PI)
		var distance = randf_range(0, follower_spawn_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		
		# Instantiate a new follower and set up
		var follower = follower_scene.instantiate()
		follower.position = player_pos + offset
		follower.unit_data = unit_data
		follower.set_anim_lib()  # Assuming this is a function that sets animation for the follower
		follower.scale = Vector2(0.5, 0.5)
		add_child(follower)
		#_set_owner_recursive(follower, self)
		
		followers[unit_data] = follower
	

func _ready():
	#make the game remember this is the last overworld loaded
	Global.set_last_overworld_scene(get_tree().current_scene)
	Global.set_max_party_num(max_party_num)
	EventBus.emit_signal("back_to_overworld")
	
	##update player info
	#TODO replace A with player name when able to access
	#$CanvasLayer/PlayerInfo.text = "Player " + "A" + "\nLevel " + str(Global.level)
	
	#print("update followers... -- overworld.gd")
	update_followers()
	
	# Play stored dialogue if not empty
	if Global.dialogue_on_scene_ready:
		Global.start_dialogue(Global.dialogue_on_scene_ready)
		await EventBus.ui_element_ended
		Global.dialogue_on_scene_ready.clear()
	if Global.battle_result == "win" and Global.win_dialogue:
		Global.start_dialogue(Global.win_dialogue)
		await EventBus.ui_element_ended
		Global.win_dialogue.clear()
	elif Global.battle_result == "lose" and Global.lose_dialogue:
		Global.start_dialogue(Global.lose_dialogue)
		await EventBus.ui_element_ended
		Global.lose_dialogue.clear()
	Global.battle_result = "none"
	
	TutorialManager.set_tutorial_queue(tutorial_queue)
	# check if player has recruit token and call tutorial if needed
	if Global.recruit_token >= 1:
		EventBus.emit_signal("tutorial_trigger", "recruit_tutorial")
		HintManager.trigger_hint("recruit_token", "Don't forget to recruit a new Ally!", false)
		
	HintManager.pause_idle_timer()

func _on_save_pressed():
	if !Global.can_actors_move:
		return
	AudioPreload.play_sfx("menu_click")
	Global.save_screen()

func _on_party_manage_pressed():
	if !Global.can_actors_move:
		return
	AudioPreload.play_sfx("menu_click")
	Global.set_last_overworld_scene(get_tree().current_scene)
	Global.last_scene_type = "overworld"
	var party_manage = preload("res://overworld/party_comp/party_comp.tscn")
	get_tree().change_scene_to_packed(party_manage)
