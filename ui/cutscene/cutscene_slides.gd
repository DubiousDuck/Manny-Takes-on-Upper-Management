extends Control

class_name CutsceneSlides

var texture_len: int = 0
var is_playing: bool = false

@export_file("*.tscn") var level_to_go: String
@export var cutscene_elements: Array[CutsceneElement] = []
@export var current_page: int = 0
@export var autoplay: bool = false

func _ready():
	for element in cutscene_elements:
		element.hide()
	texture_len = cutscene_elements.size()
	
	if autoplay:
		current_page += 1
		if current_page <= texture_len:
			advance_cutscene()

func _input(event):
	if Input.is_action_just_pressed("LMB") or Input.is_action_just_pressed("ui_accept"):
		if is_playing:
			return
		current_page += 1
		if current_page <= texture_len:
			advance_cutscene()
		else:
			Global.scene_transition(level_to_go)

func advance_cutscene():
	for element in cutscene_elements:
		if current_page == element.fade_in_click:
			#print("element %s is being fade in!" %element.name)
			fade_node(element, true, element.duration)
		elif current_page == element.fade_out_click:
			fade_node(element, false, element.duration)

func fade_node(node: CutsceneElement, fade_in: bool, duration: float):
	var tween = get_tree().create_tween()
	node.visible = true
	node.modulate.a = 0 if fade_in else 1
	tween.tween_property(node, "modulate:a", 1.0 if fade_in else 0.0, duration)

	if !fade_in:
		tween.tween_callback(Callable(node, "hide"))  # Optional: hide after fade-out
