extends Control

class_name BattleOutcome

@onready var label = $Label #Not ready yet when init() is called?
@onready var button = $Button

func init(result: int):
	match result:
		EventBus.BattleResult.PLAYER_VICTORY:
			$Label.text = "You won!"
		EventBus.BattleResult.TIE:
			$Label.text = "It's a tie."
		EventBus.BattleResult.ENEMY_VICTORY:
			$Label.text = "You lost..."

func display():
	get_tree().paused = true

func _on_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
