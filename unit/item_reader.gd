extends Node2D

class_name ItemReader

func get_item_effects(item: ItemData) -> Array:
	var effects := item.effect_dict.duplicate(true)
	var output: Array = []
	for key in effects.keys():
		print(key)
		match key:
			ItemData.EffectType.ATTACK_UP:
				output.append(BonusStatManager.create_bonus_stat("attack_power", effects[key], item.item_name, -1))
			ItemData.EffectType.HP_UP:
				output.append(BonusStatManager.create_bonus_stat("max_health", effects[key], item.item_name, -1))
			ItemData.EffectType.DEFENSE_UP:
				output.append(BonusStatManager.create_bonus_stat("damage_reduction", effects[key], item.item_name, -1))
			ItemData.EffectType.MOV_UP:
				output.append(BonusStatManager.create_bonus_stat("movement_range", effects[key], item.item_name, -1))
			ItemData.EffectType.UNLOCK_SKILL:
				output.append(effects[key])
			_:
				print("no corresponding effect found...")
	return output
