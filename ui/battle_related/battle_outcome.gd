extends Control

class_name BattleOutcome

signal all_bars_done

const EXP_BAR = preload("res://ui/battle_related/exp_bar.tscn")

@onready var label = $Label #Not ready yet when init() is called
@onready var xp_label = $VBoxContainer/XpLabel
@onready var item_drop_label = $VBoxContainer/ItemDropLabel
@onready var token_label = $VBoxContainer/TokenLabel
@onready var exp_bar_container = $ScrollContainer/ExpBarContainer

var unit_to_bar: Dictionary[UnitData, ExpBar] = {}
var bars_done: int = 0


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
			$VBoxContainer/ItemDropLabel.hide()
			Global.battle_result = "lose"
	button_toggle(false)
	

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
	unit_to_bar[unit] = a
	a.connect("bar_done", _on_bar_done)
	a.init(unit)

func animate_exp_bar(unit: UnitData):
	for bar: ExpBar in exp_bar_container.get_children():
		if bar.current_unit_data == unit:
			await bar.animate_exp(unit.level, unit.exp)
			break

func animate_exp_bar_of_party(party: Array[UnitData]):
	bars_done = 0
	for unit in party:
		var bar: ExpBar = unit_to_bar.get(unit, null)
		if bar:
			bar.animate_exp(unit.level, unit.exp)
	await all_bars_done
	#print("all bars done")
 
func _on_bar_done():
	bars_done += 1
	if bars_done == exp_bar_container.get_child_count():
		all_bars_done.emit()

func display():
	button_toggle(true)
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
	
func button_toggle(state: bool):
	if state:
		$HBoxContainer/PlayAgain.show()
		$HBoxContainer/PreviousScene.show()
	else:
		$HBoxContainer/PlayAgain.hide()
		$HBoxContainer/PreviousScene.hide()
