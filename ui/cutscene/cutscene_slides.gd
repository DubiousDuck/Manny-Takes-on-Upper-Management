extends Control

class_name CutsceneSlides

var texture_len: int = 0
var current_page: int = 0
var is_playing: bool = false

@export_file("*.tscn") var level_to_go: String
@export var textures: Array[Texture2D]

func _ready():
	if !textures.is_empty():
		$TextureRect.texture = textures[0]
		texture_len = textures.size()

func _input(event):
	if Input.is_action_just_pressed("LMB") or Input.is_action_just_pressed("ui_accept"):
		if is_playing:
			return
		current_page += 1
		if current_page < texture_len:
			var a = get_tree().create_tween()
			a.tween_property($TextureRect, "modulate:a", 0.1, 0.5)
			await a.finished
			$TextureRect.texture = textures[current_page]
			a.tween_property($TextureRect, "modulate:a", 1, 0.5)
			await a.finished
		else:
			Global.scene_transition(level_to_go)
