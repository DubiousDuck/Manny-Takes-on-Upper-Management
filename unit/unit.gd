extends CharacterBody2D

class_name Unit

signal movement_complete

@export var move_speed_per_cell := 0.2
@export var movement_range : int = 2
var cell : Vector2
var moved : bool = false
var is_player_controlled : bool

func _process(delta):
	if moved: #dim color if moved TODO Replace placeholder
		if is_player_controlled: $ColorRect.color = Color(0, 0.305, 0.461)
		else: $ColorRect.color = Color(0.51, 0.046, 0)
	else:
		if is_player_controlled: $ColorRect.color = Color(0, 0.592, 0.871)
		else: $ColorRect.color = Color(0.89, 0.281, 0.239)
		
func init():
	cell = HexNavi.global_to_cell(global_position)
	global_position = HexNavi.cell_to_global(cell)

func move_along_path(full_path : Array[Vector2i]):
	var move_tween = get_tree().create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.set_trans(Tween.TRANS_CUBIC)
	for next_point in full_path:
		move_tween.tween_property(
			self,
			'global_position',
			HexNavi.cell_to_global(next_point),
			move_speed_per_cell
		)
		#tween will append all property tweeners first before executing
	await move_tween.finished
	cell = HexNavi.global_to_cell(global_position)
	EventBus.emit_signal("update_cell_status")
	movement_complete.emit()

func highlight_emit(): #virtual function for the base Unit class
	pass
	
func _on_hurtbox_mouse_entered():
	if !moved or !is_player_controlled:
		highlight_emit()

func _on_hurtbox_mouse_exited():
	EventBus.emit_signal("remove_cell_highlights", name)
