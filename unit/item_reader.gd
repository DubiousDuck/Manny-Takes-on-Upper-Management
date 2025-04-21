extends Node2D

class_name ItemReader

func get_item_effects(item: ItemData) -> Dictionary:
	var effects := item.effect_dict.duplicate(true)
	var effect_output: Dictionary = {
		"HP": 0,
		"ATK": 0,
		"MAG": 0,
		"MOV": 0,
		"DEF": 0,
		"NEW_SKILL": null
	}
	for key in effects.keys():
		print(key)
		match key:
			ItemData.EffectType.ATTACK_UP:
				effect_output["ATK"] += effects[key]
			ItemData.EffectType.HP_UP:
				effect_output["HP"] += effects[key]
			ItemData.EffectType.DEFENSE_UP:
				effect_output["HP"] += effects[key]
			ItemData.EffectType.MOV_UP:
				effect_output["MOV"] += effects[key]
			ItemData.EffectType.UNLOCK_SKILL:
				effect_output["NEW_SKILL"] = effects[key]
			_:
				print("no corresponding effect found...")
	return effect_output
