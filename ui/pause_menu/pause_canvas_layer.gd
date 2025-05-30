extends CanvasLayer

var menuIsDisplayed: bool = false
var logDisplayed:bool = false
@onready var battle_menu_control = $BattleMenuControl
@onready var label = $BattleMenuControl/Label
@onready var exit_level = $BattleMenuControl/HBoxContainer/ExitLevel
@onready var restart_level = $BattleMenuControl/HBoxContainer/RestartLevel
@onready var to_main_menu = $BattleMenuControl/HBoxContainer/ToMainMenu
@onready var pause_button = $BattleBox/PauseButton
@onready var brightness_slider = $BattleMenuControl/BrightnessSlider
@onready var background_rect = $BackgroundRect

@onready var dev_button = $BattleMenuControl/DevButton
@onready var pass_button = $BattleBox/PassButton
@onready var battle_box = $BattleBox
@onready var pre_battle_box = $PreBattleBox
@onready var unit_count = $BattleBox/UnitCount

@export var isBattleScene: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.connect("ui_element_started", other_ui_started)
	EventBus.connect("ui_element_ended", other_ui_ended)
	$BattleMenuControl.visible = false
	$LogControl.visible = false
	dev_button.visible = Global.dev_mode
	brightness_slider.setBrightness(Global.brightness_val)
	updateLabelText()
	if !isBattleScene:
		exit_level.visible = false
		restart_level.visible = false
		pass_button.visible = false
		$BattleBox/LogButton.visible = false
		to_main_menu.visible = true
		background_rect.visible = false
		pre_battle_box.visible = false
		unit_count.visible = false
	else:
		to_main_menu.visible = false
		
	# Battle related
	EventBus.connect("units_left_changed", _on_units_left_changed)

func other_ui_started():
	pass
	
func other_ui_ended():
	pass

func flipMenuDisplay():
	menuIsDisplayed = !menuIsDisplayed
	battle_menu_control.visible = menuIsDisplayed
	pause_button.visible = !menuIsDisplayed
	if isBattleScene:
		pass_button.visible = !menuIsDisplayed
		$BattleBox/LogButton.visible = !menuIsDisplayed
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
	AudioPreload.play_sfx("menu_click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_level_pressed():
	AudioPreload.play_sfx("menu_click")
	get_tree().paused = false
	Global.battle_result = "lose"
	get_tree().change_scene_to_packed(Global.get_last_overworld_scene())


func _on_quit_game_pressed():
	AudioPreload.play_sfx("menu_click")
	get_tree().quit()


func _on_resume_pressed():
	AudioPreload.play_sfx("menu_click")
	flipMenuDisplay()


func _on_pause_button_pressed():
	AudioPreload.play_sfx("menu_click")
	flipMenuDisplay()

func _on_dev_button_pressed():
	EventBus.battle_ended.emit(0)
	flipMenuDisplay()

func _on_pass_button_pressed():
	AudioPreload.play_sfx("select")
	#print("---------------------- : " + str(Global.isPlayerTurn))
	if Global.isPlayerTurn:
		#print("hitting the button")
		EventBus.pass_turn.emit()

func _on_to_main_menu_pressed():
	AudioPreload.play_sfx("menu_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

# -- Prebattle related functions -- #
func _on_battle_start_pressed():
	AudioPreload.play_sfx("select")
	for child in pre_battle_box.get_children():
		child.disabled = true
	EventBus.emit_signal("battle_started")

func _on_party_comp_pressed():
	AudioPreload.play_sfx("select")
	var a = preload("res://overworld/party_comp/party_comp.tscn")
	Global.last_scene_type = "battle"
	get_tree().change_scene_to_packed(a)

func play_top_bar_slide_in(reversed: bool = false, is_player_label: bool = true):
	if is_player_label:
		$BackgroundRect/BackgroundTopBar/TurnIndicator.text = "Player's Turn"
	else:
		$BackgroundRect/BackgroundTopBar/TurnIndicator.text = "Enemy's Turn"
		
	if reversed:
		$AnimationPlayer.play("top_bar_slide_up")
	else: $AnimationPlayer.play("top_bar_slide_down")
	
	await $AnimationPlayer.animation_finished
	return

func play_both_bar_slide_out(reversed: bool = false):
	$AnimationPlayer.play("both_bars_slide_out",-1, 1.0, reversed)
	await $AnimationPlayer.animation_finished
	return

func _on_units_left_changed():
	unit_count.text = "Units left to move: " + str(Global.player_units_to_move)

func _on_log_button_pressed():
	AudioPreload.play_sfx("select")
	if logDisplayed:
		$LogControl.hide()
		get_tree().paused = false
		logDisplayed = false
	else:
		$LogControl/Log.text = "\n".join(PackedStringArray(Global.battle_log))
		$LogControl.show()
		get_tree().paused = true
		logDisplayed = true

func _on_log_resume_pressed():
	AudioPreload.play_sfx("menu_click")
	_on_log_button_pressed()
