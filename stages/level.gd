extends Node2D

class_name Level

const INTRAVERSABLE_WEIGHT: float = 999

@onready var battle_outcome = preload("uid://ct4t683r6jn78")
@onready var pause_canvas_layer = $PauseCanvasLayer

@export var tile_map : TileMapLayer
@onready var unit_group_control : UnitGroupController = $Units

@export_category("Rewards")
@export var inital_exp : int
@export var repeat_exp : int
@export var dropped_items: Array[ItemData] = []

@export_category("Other Parameters")
## Array of of tutorials to show
@export var level_name : String
@export var tutorial_queue: Array[TutorialContent]

## Whether to give a recruit token or not after initial victory
@export var give_token: bool = true

func _ready():
	EventBus.connect("battle_ended", _on_battle_ended)
	EventBus.connect("battle_started", _on_battle_started)
	$Units.connect("switch_turn", _on_units_switch_turn)
	
	HexNavi.set_current_map(tile_map)
	HexNavi.set_weight_of_layer("traversable", false, INTRAVERSABLE_WEIGHT)
	
	unit_group_control.init()
	
	pause_canvas_layer.battle_box.visible = false
	pause_canvas_layer.pre_battle_box.visible = true
	
	Global.set_last_battle_scene(get_tree().current_scene.scene_file_path)
	
	TutorialManager.set_tutorial_queue(tutorial_queue)
	TutorialManager.reset_tutorial_queue()
	
	Global.battle_log.clear()

func battle_start():
	EventBus.clear_preview.emit()
	await pause_canvas_layer.play_both_bar_slide_out()
	
	await Global.play_label_slide_from_left("Battle!")
	
	pause_canvas_layer.battle_box.visible = true
	unit_group_control.battle_start()
	EventBus.tutorial_trigger.emit("battle_start")
	await EventBus.ui_element_ended
	
	HintManager.trigger_hint("level_1_intro", "Click on your unit (in blue) to continue!")
	HintManager.continue_idle_timer()

func _on_battle_started():
	battle_start()
	
func _on_battle_ended(result: int):
	##exp gain
	var a = battle_outcome.instantiate() as BattleOutcome
	a.init(result)
	GlobalUI.add_child(a)
	var init_level : int = Global.level
	if result == EventBus.BattleResult.PLAYER_VICTORY:
		Global.finished_level()
		EventBus.tutorial_trigger.emit("player_win")
		await EventBus.tutorial_finished
		
		# set xp_gained
		var xp_gained = inital_exp #TODO: gain repeat exp if level already beaten
		
		# gain token
		if give_token:
			Global.recruit_token += 1
			a.update_token_label(true)
		else: a.update_token_label(false)
		a.update_xp_label(xp_gained)
		
		# drop random loot
		var random_loot: ItemData = dropped_items.pick_random()
		if random_loot: Global.unequipped_items.append(random_loot)
		var item_name = random_loot.item_name if random_loot else ""
		a.update_item_label(item_name)
		
		# granting and animating experience
		var newly_learned_skills: Dictionary[UnitData, SkillInfo] = {}
		# creat a exp bar for each current party member and record their new skills
		for unit in Global.current_party:
			a.add_exp_bar(unit)
			newly_learned_skills[unit] = grant_exp(unit, xp_gained)
		# grants exp to reserve members too
		for unit in Global.reserves:
			newly_learned_skills[unit] = grant_exp(unit, xp_gained)
		# animate all exp bars at once
		await a.animate_exp_bar_of_party(Global.current_party)
		#print("animation complete")
		
		# display new learned skills
		for unit in newly_learned_skills.keys():
			await show_skill_unlock(unit, newly_learned_skills[unit])
	else:
		a.update_xp_label(0)
	# enables other buttons when all animation done
	a.display()

	HintManager.pause_idle_timer()

func _on_units_switch_turn(is_player):
	await pause_canvas_layer.play_top_bar_slide_in(false, is_player)
	await get_tree().create_timer(0.75).timeout
	await pause_canvas_layer.play_top_bar_slide_in(true, is_player)
	unit_group_control.start_next_turn()
	
	if is_player:
		HintManager.continue_idle_timer()
	else: HintManager.pause_idle_timer()

func grant_exp(unit: UnitData, xp: int) -> SkillInfo:
	var newly_unlocked_skill: SkillInfo = null
	var old_level = unit.level
	
	unit.gain_exp(xp) # assume this handles level ups
	
	if unit.level > old_level:
		for level in range(old_level + 1, unit.level + 1):
			var unlocked = unit.check_skill_unlock(level)
			if unlocked:
				newly_unlocked_skill = unlocked
	return newly_unlocked_skill

func show_skill_unlock(unit: UnitData, skill: SkillInfo):
	if !skill:
		return
	var popup = preload("res://ui/battle_related/skill_unlock_popup.tscn").instantiate() as SkillUnlockPopup
	popup.set_skill_info(unit, skill)
	GlobalUI.add_child(popup)
	await EventBus.ui_element_ended
