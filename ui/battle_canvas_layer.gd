extends CanvasLayer

var menuIsDisplayed: bool = false
@onready var battle_menu_control = $BattleMenuControl

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Recommended: Use action instead of direct key
		menuIsDisplayed = !menuIsDisplayed
		battle_menu_control.visible = menuIsDisplayed
		
		#if menuIsDisplayed:
			#get_tree().paused = true
		#else:
			#get_tree().paused = false
		
		print("Escape key pressed! menu displayed = " + str(menuIsDisplayed))


func _on_restart_level_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_level_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(Global.get_last_overworld())


func _on_quit_game_pressed():
	get_tree().quit()
