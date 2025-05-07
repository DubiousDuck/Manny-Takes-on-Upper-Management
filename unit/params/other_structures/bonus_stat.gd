extends Resource

class_name BonusStat

@export var stat: String
@export var value: float

## Source of the stat buff
@export var source: String

## Duration of the buff in turns; negative duration means permanent
@export var duration: int

func _init(_stat: String = "", _value: int = 0, _source: String = "", _duration: int = 0):
	stat = _stat
	value = _value
	source = _source
	duration = _duration
