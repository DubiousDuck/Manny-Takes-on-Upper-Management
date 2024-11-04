extends CharacterBody2D

class_name Unit

signal movement_complete

@export var move_speed_per_cell = 0.2
var cell : Vector2
var moved : bool = false

func init():
	cell = Navi.global_to_cell(global_position)
	global_position = Navi.cell_to_global(cell)

func move_along_path(full_path : Array[Vector2i]):
	var move_tween = get_tree().create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_CUBIC)
	for next_point in full_path:
		move_tween.tween_property(
			self,
			'global_position',
			Navi.cell_to_global(next_point),
			move_speed_per_cell
		)
		#tween will append all property tweeners first before executing
	await move_tween.finished
	cell = Navi.global_to_cell(global_position)
	movement_complete.emit()
