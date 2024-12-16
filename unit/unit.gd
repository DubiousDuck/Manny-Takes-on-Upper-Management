extends CharacterBody2D

class_name Unit

signal movement_complete
signal action_complete

#unit constants
enum Action {NONE, MOVE, ATTACK, SKILL}

#unit attributes (interface)
@export var health: int = 2
@export var attack_power: int = 1
@export var move_speed_per_cell := 0.2
@export var movement_range: int = 2
@export var all_actions: Array[Action] = [Action.MOVE] #Master attribute of all available actions this unit can take in one turn

#unit internal information
var cell: Vector2i
var actions_avail: Array[Action] = all_actions #list of actions this unit hasn't taken this turn
var is_player_controlled: bool
var move_range_highlight := Color(1, 1, 1, 1)

func _process(delta):
	if actions_avail.is_empty(): #if there are no available actions left
		if is_player_controlled: $ColorRect.color = Color(0, 0.305, 0.461)
		else: $ColorRect.color = Color(0.51, 0.046, 0)
	else:
		if is_player_controlled: $ColorRect.color = Color(0, 0.592, 0.871)
		else: $ColorRect.color = Color(0.89, 0.281, 0.239)
	$Health.text = str(health) #TODO: Replace placeholder
		
func init():
	cell = HexNavi.global_to_cell(global_position)
	global_position = HexNavi.cell_to_global(cell)
	actions_avail.assign(all_actions)

func move_along_path(full_path : Array[Vector2i]):
	var move_tween = get_tree().create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_CUBIC)
	for next_point in full_path:
		move_tween.tween_property(
			self,
			'global_position',
			HexNavi.cell_to_global(next_point),
			move_speed_per_cell
		)
		#tween will append all property tweeners first before executing
	await move_tween.finished
	actions_avail.erase(Action.MOVE)
	cell = HexNavi.global_to_cell(global_position)
	EventBus.emit_signal("update_cell_status")
	movement_complete.emit()

func take_action(): #where animations are handled
	pass

func highlight_emit():
	var all_neighbors = HexNavi.get_all_neighbors_in_range(cell, movement_range)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, move_range_highlight, name)
	
func _on_hurtbox_mouse_entered():
	highlight_emit()

func _on_hurtbox_mouse_exited():
	EventBus.emit_signal("remove_cell_highlights", name)
