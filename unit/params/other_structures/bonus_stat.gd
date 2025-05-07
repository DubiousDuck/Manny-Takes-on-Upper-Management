extends Resource

class_name BonusStat

@export var stat: String
@export var value: float

## Source of the stat buff
@export var source: String

## Duration of the buff in turns; negative duration means permanent
@export var duration: int
