extends Resource

class_name BonusStatManager

static func create_bonus_stat(stat_name: String, value: Variant, source: String, duration: int) -> BonusStat:
	var new_bonus_stat = BonusStat.new()
	new_bonus_stat.stat = stat_name
	new_bonus_stat.value = value
	new_bonus_stat.source = source
	new_bonus_stat.duration = duration
	return new_bonus_stat
