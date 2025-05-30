extends Control

class_name ExpBar

signal bar_done

var current_unit_data: UnitData
var unit_prev_level: int

@onready var class_label = $HBoxContainer/ClassName
@onready var progress_bar = $HBoxContainer/ProgressBar
@onready var exp_label = $HBoxContainer/ExpLabel

func init(unit_data: UnitData):
	current_unit_data = unit_data
	unit_prev_level = current_unit_data.level
	class_label.text = current_unit_data.unit_class
	progress_bar.value = current_unit_data.exp
	exp_label.text = "Lv. %d" %current_unit_data.level

func animate_exp(new_level: int, new_exp: int):
	var exp_req = Global.get_exp_requirment(Global.level);
	for i in range(new_level - unit_prev_level):
		var exp_tween = create_tween()
		exp_tween.set_ease(Tween.EASE_IN)
		exp_tween.set_trans(Tween.TRANS_QUAD)
		exp_tween.tween_property(progress_bar, "value", progress_bar.max_value, 0.3).set_delay(0.1)
		exp_tween.tween_property(exp_label, "text" , "Lv. %d" %new_level, 0.05).set_delay(0.1)
		exp_tween.tween_property(progress_bar, "value", 0, 0.01)
		await exp_tween.finished
		
		progress_bar.max_value = current_unit_data.exp_to_next_level()
	
	##animation for exp gain
	if current_unit_data.exp > 0:
		var exp_tween = create_tween()
		exp_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		exp_tween.tween_property(progress_bar, "value", new_exp, 0.5)
		await exp_tween.finished
	
	bar_done.emit()
