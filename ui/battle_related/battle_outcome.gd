extends Control

class_name BattleOutcome

const EXP_BAR = preload("res://ui/battle_related/exp_bar.tscn")

@onready var label = $Label #Not ready yet when init() is called
@onready var exp_bar : ProgressBar = $HSplitContainer/HSplitContainer/ExpBar
@onready var level_label : Label = $HSplitContainer/HSplitContainer/LevelLabel
@onready var xp_label = $VBoxContainer/XpLabel
@onready var item_drop_label = $VBoxContainer/ItemDropLabel
@onready var token_label = $VBoxContainer/TokenLabel
@onready var exp_bar_container = $ScrollContainer/ExpBarContainer

func _ready() -> void:
	exp_bar = $HSplitContainer/HSplitContainer/ExpBar
	exp_bar.max_value = Global.get_exp_requirment(Global.level)
	pass

func init(result: int):
	EventBus.ui_element_started.emit()
	match result:
		EventBus.BattleResult.PLAYER_VICTORY:
			$Label.text = "You won!"
			Global.battle_result = "win"
			AudioPreload.play_sfx("victory")
		EventBus.BattleResult.TIE:
			$Label.text = "It's a tie."        
			Global.battle_result = "none"
		EventBus.BattleResult.ENEMY_VICTORY:
			$Label.text = "You lost..."
			item_drop_label.hide()
			Global.battle_result = "lose"
	$HSplitContainer/HSplitContainer/ExpBar.set_value_no_signal(Global.current_exp) 

func update_xp_label(xp: int):
	xp_label.text = "All party members gained " + str(xp) + " XP!"

func update_item_label(item_name: String):
	if item_name != "":
		item_drop_label.text = "You got the item " + item_name + "!"
		item_drop_label.show()
	else:
		item_drop_label.hide()

func update_token_label(state: bool):
	if state:
		token_label.show()
	else: token_label.hide()

func add_exp_bar(unit: UnitData):
	var a = EXP_BAR.instantiate() as ExpBar
	exp_bar_container.add_child(a)
	a.init(unit)

func animate_exp_bar(unit: UnitData):
	for bar: ExpBar in exp_bar_container.get_children():
		if bar.current_unit_data == unit:
			bar.animate_exp(unit.level, unit.exp)
			break
 

func display():
	get_tree().paused = true

func _on_play_again_pressed():
	EventBus.ui_element_ended.emit()
	get_tree().paused = false
	queue_free()
	EventBus.start_battle.emit()
	get_tree().reload_current_scene()

func _on_previous_scene_pressed():
	EventBus.ui_element_ended.emit()
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())
	
