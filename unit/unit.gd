extends CharacterBody2D

class_name Unit

const UNIT_PREVIEW = preload("res://ui/battle_related/unit_preview.tscn")
const THROW_ACTION_COMMAND = preload("res://skills/action_commands/throw_action_command.tscn")
const MASH_ACTION_COMMAND = preload("res://skills/action_commands/mash_action_command.tscn")
const OUTLINE_WIDTH := 1
const DMG_RED_COLOR = Color(0.156, 0.475, 1.0)

signal movement_complete
signal attack_point
signal anim_complete
signal all_complete
signal status_updated(successful: bool)
signal tile_action_done
signal init_finished

#unit constants
enum Action {NONE, MOVE, ATTACK, ITEM}

#unit attributes (interface)
@export var unit_id: int
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
		if new_health == 0:
			is_dead = true
		else: is_dead = false #TODO: see if this line is necessary

@export var unit_data: UnitData
@export var move_speed_per_cell := 0.2
@export var all_actions: Array[Action] = [Action.MOVE, Action.ATTACK] #Master attribute of all available actions this unit can take in one turn

@onready var pof_icon = $IconAnchor/PoFIcon
@onready var status_icon = $IconAnchor/StatusIcon
@onready var background_icon = $Sprite2D/BackgroundIcon


# -- Unit Stats Related Variables and Functions -- #
## Base stats dictionary
@export var base_stats: Dictionary[String, Variant] = {
	"max_health": 2,
	"attack_power": 1,
	"magic_power": 1,
	"movement_range": 2,
	"damage_reduction": 0
}
## Bonus stats dictionary
@export var bonus_stat: Array[BonusStat] = []
# custom getter function to help with the custom getter variables
func get_stat(stat_name: String):
	var total = base_stats.get(stat_name, 0)
	for bonus in bonus_stat:
		if bonus.stat == stat_name:
			total += bonus.value
	return total
# custom getter variables to reduce the need to change other scripts
var max_health: int:
	get(): return get_stat("max_health")
var attack_power: int:
	get(): return get_stat("attack_power")
var magic_power: int:
	get(): return get_stat("magic_power")
var movement_range: int:
	get(): return get_stat("movement_range")
var damage_reduction: float:
	get(): return get_stat("damage_reduction")

func apply_stat_modifer(stat_mod: BonusStat):
	bonus_stat.append(stat_mod.duplicate())
	# applies modulate value for visual indication
	if stat_mod.stat == "damage_reduction" and stat_mod.value > 0:
		set_unit_modulate(DMG_RED_COLOR)

func update_modifiers():
	var new_array: Array[BonusStat] = []
	for i in range(bonus_stat.size()):
		if bonus_stat[i].duration >= 0:
			bonus_stat[i].duration -= 1
			if bonus_stat[i].duration > 0:
				new_array.append(bonus_stat[i])
		else: new_array.append(bonus_stat[i])
	bonus_stat = new_array.duplicate()
	
	# removes modulate if necessary
	if abs(damage_reduction) <= 0:
		set_unit_modulate(Color.WHITE)

func has_temporary_buffs() -> bool:
	for i in range(bonus_stat.size()):
		if bonus_stat[i].duration > 0 and bonus_stat[i].value > 0:
			return true
	return false

func has_temporary_debuffs() -> bool:
	for i in range(bonus_stat.size()):
		if bonus_stat[i].duration > 0 and bonus_stat[i].value < 0:
			return true
	return false

# Status Effects Related
var active_status_effect: StatusEffect

func apply_status(status: StatusEffect):
	if active_status_effect:
		active_status_effect.on_expire(self)
	active_status_effect = status.duplicate()
	active_status_effect.on_apply(self)

func update_status_effect():
	if active_status_effect:
		active_status_effect.duration -= 1

		if active_status_effect.duration < 0:
			remove_status_effect()
			#print("Status expired, unit still alive:", !is_dead)
			status_updated.emit(!is_dead)
		else:
			await active_status_effect.tick(self)
			#print("Status tick finished, unit dead?", is_dead)
			status_updated.emit(!is_dead)
	else:
		set_status_effect_icon(false)
		#print("No active status, unit still alive:", !is_dead)
		status_updated.emit(!is_dead)


func remove_status_effect():
	if active_status_effect:
		active_status_effect.on_expire(self)

func find_and_remove_status_effect(type: StatusEffect.Effect):
	if active_status_effect and active_status_effect.type == type:
		remove_status_effect()
	else:
		return

#unit internal information
var cell: Vector2i
var actions_avail: Array[Action] = all_actions #list of actions this unit hasn't taken this turn
var is_player_controlled: bool
var move_range_highlight := Color(1, 1, 1, 1)
var outline_col := Color(1, 1, 1, 1)
var selected: bool = false
var unit_held: Array[Unit] = [] #array of all units that this unit has picked up
var is_held: bool = false
var is_dead: bool = false
var container: UnitContainer
var skills: Array[SkillInfo] = []

var in_pof: bool = false:
	set(new_state):
		in_pof = new_state
		toggle_background_aura(in_pof)

enum POF_RECEIVE_STATE {NONE, READY, TRIGGERED}
var pof_receive_state := POF_RECEIVE_STATE.NONE

func _ready():
	pass
	
## read unit_data and set attributes
func load_unit_data():
	#read unit data and set base attributes
	base_stats.max_health = unit_data.get_stat("HP")
	base_stats.attack_power = unit_data.get_stat("ATK")
	base_stats.magic_power = unit_data.get_stat("MAG")
	base_stats.movement_range = unit_data.get_stat("MOV")
	base_stats.damage_reduction = unit_data.get_stat("DMG_RED")
	
	skills = unit_data.skill_list
	
	#read from item list and apply effects
	#delegates to the ItemReader to make organization cleaner
	for item in unit_data.item_list:
		var effects: Array = $ItemReader.get_item_effects(item)
		for effect in effects:
			if effect is BonusStat:
				bonus_stat.append(effect)
			elif effect is SkillInfo and !skills.has(effect):
				skills.append(effect)
	health = max_health
	_set_anim_lib()

func _process(_delta):
	unit_held.map(
		func(unit):
			if !unit:
				return
			unit.global_position = global_position + Vector2(0, -30)
	)
	
	if has_temporary_buffs():
		$Sprite2D/BuffParticles.emitting = true
	else: $Sprite2D/BuffParticles.emitting = false
	if has_temporary_debuffs():
		$Sprite2D/DebuffParticles.emitting = true
	else: $Sprite2D/DebuffParticles.emitting = false

func set_unit_modulate(tint: Color):
	modulate = tint
	# manually set sprite shader parameter to reflect modulate change
	var sprite_shader = $Sprite2D.material
	if sprite_shader and sprite_shader is ShaderMaterial:
		sprite_shader.set_shader_parameter("sprite_modulate", tint)
		
func init():
	animation_state("front_idle")
	cell = HexNavi.global_to_cell(global_position)
	actions_avail.assign(all_actions)
	toggle_skill_ui(false, [])
	
	#check and remove dead held units
	var valid_children: Array[Unit] = []
	for child in unit_held:
		if !child.is_dead:
			valid_children.append(child)
			print("held child: " + child.name + " is dead...")
	unit_held = valid_children
	
	in_pof = false
	update_modifiers()
	
	# Await status update
	update_status_effect()
	#print("status updated!")
	var is_alive: bool = await status_updated
	
	if !is_alive:
		#print("unit died during status effect")
		emit_signal("init_finished")
		return
	else:
		pass
		#print("unit did not die during status effect")

	# Await tile action (especially teleport animation)
	tile_action(true)
	#print("tile actioned!")
	await tile_action_done
	
	await get_tree().process_frame
	#print("init finished")
	emit_signal("init_finished")

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
	await tile_action()
	unit_held.map( #update held unit cell info
		func(unit):
			unit.global_position = HexNavi.cell_to_global(cell)
			unit.cell = cell
	)
	if diff.x == 0:
		animation_state("front_idle")
	else:
		animation_state("side_idle")
	#print(name + " moved!")
	
	EventBus.emit_signal("update_cell_status", true)
	movement_complete.emit()
	EventBus.emit_signal("tutorial_trigger", "ready_to_attack")

func take_action(skill: SkillInfo, target_cell: Vector2i = Vector2i.MIN): #where animations are handled
	actions_avail.erase(Action.ATTACK)
	Global.attack_successful = true #False only when action command fails
	#print("# ANIMATION STARTED: " + skill.name + " (unit.gd)")
	# NOTICE: It's imperical to have both `attack_point` and `anim_complete` emitted by the time each animation ends
	if target_cell != Vector2i.MIN: #Flip sprite as needed
		if target_cell.x - cell.x > 0:
			$Sprite2D.flip_h = false
		elif target_cell.x - cell.x < 0:
			$Sprite2D.flip_h = true
	match skill.name:
		"Throw At":
			animation_state("throw")
			await $AnimationPlayer.animation_finished
		"Pick Up":
			animation_state("hold_prep")
			await $AnimationPlayer.animation_finished
		"Basic Punch", "Forgetful Hammer":
			animation_state("punch")
			await $AnimationPlayer.animation_finished
		"Rubber Band Shoot":
			animation_state("shoot")
			await $AnimationPlayer.animation_finished
		"Magical Shot":
			animation_state("magic_shoot")
			await $AnimationPlayer.animation_finished
		"Shove":
			animation_state("shove")
			await $AnimationPlayer.animation_finished
		"Arrow Rain":
			animation_state("arrow_rain")
			await $AnimationPlayer.animation_finished
		"Whirlwind":
			animation_state("whirlwind")
			await $AnimationPlayer.animation_finished
		"Defend":
			animation_state("defend")
			await $AnimationPlayer.animation_finished
		"Give Milk":
			animation_state("heal")
			await $AnimationPlayer.animation_finished
		"Wait":
			await get_tree().create_timer(0.2).timeout
			emit_attack_point()
			emit_anim_comlete()
		_:
			animation_state("default")
			await $AnimationPlayer.animation_finished
	animation_state("side_idle")

func highlight_emit():
	var all_neighbors = HexNavi.get_all_neighbors_in_range(cell, base_stats.movement_range)
	EventBus.emit_signal("show_cell_highlights", all_neighbors, move_range_highlight, name)
	
func _on_hurtbox_mouse_entered():
	toggle_outline(true)
	EventBus.unit_hovered.emit(self)

func _on_hurtbox_mouse_exited():
	if !selected:
		toggle_outline(false)
	EventBus.unit_unhovered.emit(self)

func _on_hurtbox_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.unit_right_clicked.emit(self)

func check_if_dead():
	if health <= 0 || cell == Vector2i(-999, -999) || HexNavi.get_cell_custom_data(cell, "effect") == "death": #if no health or out of bounds
		is_dead = true
		animation_state("vanish")
		await $AnimationPlayer.animation_finished
		EventBus.emit_signal("unit_died", self)
		all_complete.emit()
		queue_free.call_deferred()
	return

## check and execute effect of the tile that the unit lands on
func tile_action(round_start: bool = false):
	var effect = HexNavi.get_cell_custom_data(cell, "effect")
	var cell_effect: String = effect if effect is String else ""
	match cell_effect:
		"teleport":
			# Do not teleport at round start
			if !round_start:
				var end_points := HexNavi.get_all_tile_with_layer("effect", "teleport")
				#print(end_points)
				if end_points.size() <= 1:
					return #if there are no other teleport tiles
				var random_tile: Vector2i = end_points.pick_random()
				while random_tile == cell:
					random_tile = end_points.pick_random()
				#transport unit
				animation_state("teleported")
				await anim_complete
				cell = random_tile
				global_position = HexNavi.cell_to_global(cell)
				animation_state("teleported_reversed")
				await anim_complete
				animation_state("front_idle")
		"heal": # allows for overheal
			animation_state("front_idle")
			regain_health(1, true)
			#MyMapLayer.set_random_heal_tile(self)
		"spike":
			take_damage(1, self)
	
	await get_tree().process_frame
	emit_signal("tile_action_done")

func toggle_skill_ui(state: bool, valid_skills: Array[SkillInfo]):
	if state:
		EventBus.show_skill_select.emit(self, valid_skills)
	else:
		EventBus.hide_skill_select.emit()

func check_if_can_throw():
	var throw_skill = load("res://skills/throw.tres")
	if !unit_held.is_empty():
		if !skills.has(throw_skill):
			skills.append(throw_skill)
	else:
		skills.erase(throw_skill)

## Animation related
var two_signals: Array[bool] = [false, false]

func animation_state(animation : String):
	$Sprite2D.hframes = 4
	var full_anim_name = "%s/%s" % [anim_lib, animation]
	
	if $AnimationPlayer.has_animation(full_anim_name):
		$AnimationPlayer.play(full_anim_name)
	else:
		# Play fallback/default animation
		var default_anim = "%s/default" % anim_lib
		if $AnimationPlayer.has_animation(default_anim):
			$AnimationPlayer.play(default_anim)
		else:
			print("Missing animation: %s and default %s" % [full_anim_name, default_anim])

#in the animation player
func emit_attack_point():
	#print("Attack point emitted!")
	attack_point.emit()
	
#in the animation player
func emit_action_command_point(game : String):
	$AnimationPlayer.pause()
	match game:
		"throw":
			var a = THROW_ACTION_COMMAND.instantiate()
			add_child(a)
			if global_position.y <= Global.camera_top:
				a.position = Vector2(-(a.size.x)/2, 20) #need to comensate for the size of the bars
			elif global_position.y >= Global.camera_low:
				a.position = Vector2(-(a.size.x)/2, -20-(a.size.y))
			get_tree().paused = true
		"mash":
			var a = MASH_ACTION_COMMAND.instantiate()
			add_child(a)
			if global_position.y <= Global.camera_top:
				a.position = Vector2(-(a.size.x)/2, 20) #need to comensate for the size of the bars
			elif global_position.y >= Global.camera_low:
				a.position = Vector2(-(a.size.x)/2, -20-(a.size.y))
			get_tree().paused = true
		_:
			pass
	$AnimationPlayer.play()

#in the animation player
func emit_anim_comlete():
	#print("anim complete emitted!")
	anim_complete.emit()
	
## When receive the attack point signal, check to see if can emit "total_complete"
func _on_attack_point():
	two_signals[0] = true
	if two_signals.count(true) == 2:
		all_complete.emit()

## When receive the anim complete signal, check to see if can emit "total_complete"
func _on_anim_complete():
	two_signals[1] = true
	if two_signals.count(true) == 2:
		all_complete.emit()

var anim_lib: String = "unit_anim"
## Find matching animation library
func _set_anim_lib():
	if unit_data:
		match unit_data.unit_class:
			"Healer":
				anim_lib = "Healer"
			"Mage":
				anim_lib = "Mage"
			"Fighter":
				anim_lib = "Fighter"
			"Ranger":
				anim_lib = "Ranger"
			"Tank":
				anim_lib = "Tank"
			_:
				anim_lib = "unit_anim"

## toggle_outline
func toggle_outline(state: bool):
	$Sprite2D.material.set_shader_parameter("line_color", outline_col)
	if state:
		$Sprite2D.material.set_shader_parameter("line_thickness", OUTLINE_WIDTH)
	else:
		$Sprite2D.material.set_shader_parameter("line_thickness", 0)

## Status icon display
func set_pof_icon_state(state: String):
	match state:
		"can_trigger":
			pof_receive_state = POF_RECEIVE_STATE.READY
			pof_icon.show()
			pof_icon.find_child("AnimationPlayer").play("target")
		"already_triggered":
			pof_receive_state = POF_RECEIVE_STATE.TRIGGERED
			pof_icon.show()
			pof_icon.find_child("AnimationPlayer").play("repeating_dizzy")
		"none":
			pof_receive_state = POF_RECEIVE_STATE.NONE
			pof_icon.hide()
		_:
			pof_icon.hide()
	update_status_icon_layout()
	return

func set_status_icon_tooltip(tooltip: String):
	$IconAnchor/TooltipBox.tooltip_text = tooltip

func set_status_effect_icon(visible: bool):
	if visible:
		status_icon.show()
	else:
		status_icon.hide()
	update_status_icon_layout()
	return

func update_status_icon_layout():
	var icons: Array[Sprite2D] = []
	if pof_icon.visible:
		icons.append(pof_icon)
	if status_icon.visible:
		icons.append(status_icon)
	
	if icons.is_empty():
		return
	
	var gap = 64  # Adjust pixel spacing to taste
	var displacement = gap/icons.size()
	for i in range(icons.size()):
		var offset = Vector2(displacement/2 + displacement*i-gap/2, 0)
		icons[i].global_position = $IconAnchor.global_position + offset

## Background icon display
func toggle_background_aura(state: bool):
	if state:
		background_icon.show()
		background_icon.play("default")
	else:
		background_icon.hide()
		background_icon.stop()

## Take damage
func take_damage(amount: int, attacker: Unit, check_dead: bool = true):
	health -= amount
	
	# wakes up from sleep if hurt
	find_and_remove_status_effect(StatusEffect.Effect.SLEEP)
	
	# drops unit held
	if !unit_held.is_empty():
		for held in unit_held:
			held.is_held = false
	unit_held.clear()
	
	# prevents animation self lock
	if self != attacker:
		animation_state("hurt_initial")
	
	if check_dead:
		await check_if_dead()
	return

func regain_health(amount: int, overheal: bool = false):
	# if health already greater than max_health and no overheal, keep it current
	if health > max_health and !overheal:
		health = health
	#else if the amount added will go over max health and no overheal, heal it to max only
	elif health + amount > max_health and !overheal:
		health = max_health
	else: health += amount
