extends Control

class_name BattleOutcome

@onready var label = $Label #Not ready yet when init() is called
@onready var exp_bar : ProgressBar = $HSplitContainer/HSplitContainer/ExpBar
@onready var level_label : Label = $HSplitContainer/HSplitContainer/LevelLabel
@onready var xp_label = $Label2

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
		EventBus.BattleResult.TIE:
			$Label.text = "It's a tie."
			Global.battle_result = "none"
		EventBus.BattleResult.ENEMY_VICTORY:
			$Label.text = "You lost..."
			Global.battle_result = "lose"
	$HSplitContainer/HSplitContainer/ExpBar.set_value_no_signal(Global.current_exp) 

func update_xp_label(xp: int):
	xp_label.text = "You gained " + str(xp) + " XP!"

func animate_exp(final_exp : int, initial_level : int, final_level: int):
	var exp_req = Global.get_exp_requirment(Global.level);
	for i in range(initial_level, final_level):
		var exp_tween = create_tween()
		exp_tween.set_ease(Tween.EASE_IN)
		exp_tween.set_trans(Tween.TRANS_QUAD)
		exp_tween.tween_property(exp_bar, "value", exp_bar.max_value, 0.5).set_delay(0.1)
		exp_tween.tween_property(level_label, "text" , "+" + str(int(level_label.text.substr(1))+1), 0.05).set_delay(0.1)
		exp_tween.tween_property(exp_bar, "value", 0, 0.01)
		await exp_tween.finished
		
		exp_bar.max_value = Global.get_exp_requirment(i+1)
	
	##animation for exp gain
	var exp_tween = create_tween()
	exp_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	exp_tween.tween_property(exp_bar, "value", final_exp, 0.5)
 

func display():
	get_tree().paused = true

func _on_play_again_pressed():
	EventBus.ui_element_ended.emit()
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()

func _on_previous_scene_pressed():
	EventBus.ui_element_ended.emit()
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())
	
