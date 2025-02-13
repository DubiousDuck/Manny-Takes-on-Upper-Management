extends CanvasLayer

var menuIsDisplayed: bool = false
@onready var battle_menu_control = $BattleMenuControl
@onready var label = $BattleMenuControl/Label
@onready var exit_level = $BattleMenuControl/HBoxContainer/ExitLevel
@onready var restart_level = $BattleMenuControl/HBoxContainer/RestartLevel

@export var isBattleScene: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	updateLabelText()
	if !isBattleScene:
		exit_level.visible = false
		restart_level.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Recommended: Use action instead of direct key
		menuIsDisplayed = !menuIsDisplayed
		battle_menu_control.visible = menuIsDisplayed
		
		if menuIsDisplayed:
			get_tree().paused = true
		else:
			get_tree().paused = false

func updateLabelText():
	var filename = get_tree().current_scene.scene_file_path.get_file().replace(".tscn", "")
	var parts = filename.split("_")  # Split the string by underscores
	var i = 0
	for word in parts: # Iterates through, capitalizing each word
		parts[i] = word.capitalize()
		i += 1
	var result = " ".join(parts)      # Join the parts with spaces
	
	label.text = result

func _on_restart_level_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_level_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file(Global.get_last_overworld())


func _on_quit_game_pressed():
	get_tree().quit()


func _on_resume_pressed():
	get_tree().paused = false
	menuIsDisplayed = false
	battle_menu_control.visible = menuIsDisplayed
