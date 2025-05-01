extends Resource

class_name LevelInfo

@export var level_name: String
@export var level_path: String
@export var layout_img: Texture2D
@export var ally_count: int
@export var enemy_count: int

func init(ln: String, img: Texture2D, ally_n: int, enemy_n: int):
	level_name = ln
	layout_img = img
	ally_count = ally_n
	enemy_count = enemy_n
