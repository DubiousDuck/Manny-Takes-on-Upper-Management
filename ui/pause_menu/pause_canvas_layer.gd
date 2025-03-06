extends CanvasLayer

var menuIsDisplayed: bool = false
@onready var battle_menu_control = $BattleMenuControl
@onready var label = $BattleMenuControl/Label
@onready var exit_level = $BattleMenuControl/HBoxContainer/ExitLevel
@onready var restart_level = $BattleMenuControl/HBoxContainer/RestartLevel
@onready var pause_button = $PauseButton
@onready var brightness_slider = $BattleMenuControl/BrightnessSlider

@onready var dev_button = $BattleMenuControl/DevButton

@export var isBattleScene: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	$BattleMenuControl.visible = false
	dev_button.visible = Global.dev_mode
	brightness_slider.setBrightness(Global.brightness_val)
	updateLabelText()
	if !isBattleScene:
		exit_level.visible = false
		restart_level.visible = false

func flipMenuDisplay():
	menuIsDisplayed = !menuIsDisplayed
	battle_menu_control.visible = menuIsDisplayed
	pause_button.visible = !menuIsDisplayed
	if menuIsDisplayed:
		get_tree().paused = true
	else:
		if background_control.get_child_count() == 0:
			get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Recommended: Use action instead of direct key
		flipMenuDisplay()

func updateLabelText():
	var filename = get_tree().current_scene.scene_file_path.get_file().replace(".tscn", "")
	var parts = filename.split("_")  # Split the string by underscores
	var i = 0
	for word in parts: # Iterates through, capitalizing each word
		parts[i] = word.capitalize()
		i += 1
	var result = " ".join(parts)      # Join the parts with spaces
	
	label.text = result

@onready var background_control = $BackgroundControl
func add_in_background(object):
	background_control.add_child(object)

func _on_restart_level_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_level_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())


func _on_quit_game_pressed():
	get_tree().quit()


func _on_resume_pressed():
	flipMenuDisplay()


func _on_pause_button_pressed():
	flipMenuDisplay()

func _on_dev_button_pressed():
	EventBus.battle_ended.emit(0)
	flipMenuDisplay()
