extends CharacterBody2D

class_name Unit

const THROW_ACTION_COMMAND = preload("res://skills/action_commands/throw_action_command.tscn")

signal movement_complete

#unit constants
enum Action {NONE, MOVE, ATTACK, ITEM}

#unit attributes (interface)
@export var health: int = 2 :
	set(new_health):
		$BackupHealth.modulate = Color(0,0,0,0)
		var old_health = health
		health = new_health
		$Health.text = str(health)
		if new_health >= old_health:
			$Health.modulate = Color("0ac863")
		else:
			$BackupHealth.text = str(new_health - old_health)
			$BackupHealth.modulate = Color("b61d268b")
			var a = create_tween()
			a.tween_property($BackupHealth, "position", $BackupHealth.position + Vector2(0,10), 2)
			a = create_tween()
			a.tween_property($BackupHealth, "modulate:a", .2, 2)
		var b = create_tween()
		b.tween_property($Health, "modulate", Color("ffffff"), 2)
		await b.finished
		$BackupHealth.position = $Health.position
		$BackupHealth.modulate = Color(0,0,0,0)

@export var attack_power: int = 1
@export var move_speed_per_cell := 0.2
@export var movement_range: int = 2
@export var all_actions: Array[Action] = [Action.MOVE, Action.ATTACK] #Master attribute of all available actions this unit can take in one turn
@export var skills: Array[SkillInfo] = []

#unit internal information
var cell: Vector2i
var actions_avail: Array[Action] = all_actions #list of actions this unit hasn't taken this turn
var is_player_controlled: bool
var move_range_highlight := Color(1, 1, 1, 1)
var selected: bool = false
var unit_held: Array[Unit] = [] #array of all units that this unit has picked up
var is_on_standby: bool = false: #true if no animations to be resolved
	set(value):
		if value == true: EventBus.emit_signal("unit_on_standby")

signal attack_point

func _process(delta):
	if actions_avail.is_empty(): #if there are no available actions left
		if is_player_controlled: $ColorRect.color = Color(0, 0.305, 0.461)
		else: $ColorRect.color = Color(0.51, 0.046, 0)
	else:
		if is_player_controlled: $ColorRect.color = Color(0, 0.592, 0.871)
		else: $ColorRect.color = Color(0.89, 0.281, 0.239)
	
	unit_held.map(
		func(unit):
			unit.global_position = global_position + Vector2(0, -30)
	)
		
func init():
	animation_state("front_idle")
	cell = HexNavi.global_to_cell(global_position)
	global_position = HexNavi.cell_to_global(cell)
	actions_avail.assign(all_actions)
	toggle_skill_ui(false)

func move_along_path(full_path : Array[Vector2i]):	
	var start_pos = full_path[0]
	var end_pos = full_path[-1]
	var diff = end_pos - start_pos
	
	if diff.x == 0:
		animation_state("front_walk")
	elif diff.x > 0:
		$Sprite2D.flip_h = false
		animation_state("side_walk")
	else:
		$Sprite2D.flip_h = true
		animation_state("side_walk")
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
	unit_held.map( #update held unit cell info
		func(unit):
			unit.cell = cell
	)
	EventBus.emit_signal("update_cell_status")
	if diff.x == 0:
		animation_state("front_idle")
	else:
		animation_state("side_idle")
	movement_complete.emit()

func take_action(skill: SkillInfo): #where animations are handled
	actions_avail.erase(Action.ATTACK)
	is_on_standby = false
	#print("# ANIMATION STARTED: " + skill.name + " (unit.gd)")
	match skill.name:
		"Throw":
			animation_state("throw")
			await $AnimationPlayer.animation_finished
		"Pick Up":
			animation_state("hold_prep")
			await $AnimationPlayer.animation_finished
		"Normal Melee Attack":
			animation_state("punch")
			await $AnimationPlayer.animation_finished
		"Normal Ranged Attack":
			animation_state("shoot")
			await $AnimationPlayer.animation_finished
		_:
			print("Failed to match skill name " + skill.name + " (unit.gd)")
			await get_tree().create_timer(0.2).timeout
			emit_attack_point()
	is_on_standby = true
	animation_state("side_idle")

func highlight_emit():
	var all_neighbors = HexNavi.get_all_neighbors_in_range(cell, movement_range)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, move_range_highlight, name)
	
func _on_hurtbox_mouse_entered():
	if actions_avail.has(Action.MOVE) and !selected:
		if is_player_controlled: $ColorRect.color = Color(0, 0.420, 0.630)
		else: $ColorRect.color = Color(0.51, 0.046, 0)
		highlight_emit()

func _on_hurtbox_mouse_exited():
	if is_player_controlled: $ColorRect.color = Color(0, 0.592, 0.871)
	else: $ColorRect.color = Color(0.89, 0.281, 0.239)
	EventBus.emit_signal("remove_cell_highlights", name)

func check_if_dead():
	if health <= 0:
		EventBus.emit_signal("unit_died")
		queue_free.call_deferred()

func toggle_skill_ui(state: bool):
	$SkillSelect.init()
	$SkillSelect.visible = state

func check_if_can_throw():
	var throw_skill = load("res://skills/throw.tres")
	if !unit_held.is_empty() and !skills.has(throw_skill):
		skills.append(throw_skill)
	else:
		skills.erase(throw_skill)

##

func animation_state(animation : String):
	$Sprite2D.hframes = 4
	#print("# NEW ANIMATION: " + animation + " (unit.gd)")
	$AnimationPlayer.play(animation)

#in the animation player
func emit_attack_point():
	print("Attack point emitted!")
	attack_point.emit()
	
#in the animation player
func emit_action_command_point(game : String):
	$AnimationPlayer.pause()
	match game:
		"throw":
			var a = THROW_ACTION_COMMAND.instantiate()
			add_child(a)
			get_tree().paused = true
		_:
			pass
	$AnimationPlayer.play()
