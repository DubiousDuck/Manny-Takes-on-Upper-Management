extends Resource

class_name ItemData

@export var item_name: String
@export_multiline var description: String
@export var icon: Texture2D

enum EffectType{ATTACK_UP, MAG_UP, DEFENSE_UP, HP_UP, MOV_UP, UNLOCK_SKILL}

## The list of effect this item has; should be in the format of enum (int) keys and Variant values
@export var effect_dict: Dictionary[EffectType, Variant]

# Save and Load
func to_dict() -> Dictionary:
	return {
		"item_name": item_name,
		"description": description,
		"icon": icon,
		"effect_dict": effect_dict
	}

static func new_from_dict(data: Dictionary) -> ItemData:
	var item := ItemDatabase.get_by_name(data.get("item_name", ""))
	#item.item_name = data.get("item_name", "")
	#item.description = data.get("description", "")
	#item.icon = data.get("icon", null)
	#
	## Rebuilding the effect dictionary in a careful way
	#var raw_effect = data.get("effect_dict", {})
	#for key in raw_effect.keys():
		#item.effect_dict[int(key)] = int(raw_effect[key])
	#print("The rebuilt item effects are: " + str(item.effect_dict) + " -- item.gd")

	return item
