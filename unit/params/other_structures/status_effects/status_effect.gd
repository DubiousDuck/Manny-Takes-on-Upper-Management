extends Resource

class_name StatusEffect

enum Effect{SLEEP, POISON, FORGET}

@export var icon: Texture2D

@export var name: String = "Unnamed Status Effect"
@export var type: Effect
@export var duration: int = 2
@export var magnitude: int = 1

# Tick function that is called every turn
func tick(unit: Unit):
	match type:
		Effect.SLEEP:
			sleep_tick(unit)
		Effect.POISON:
			poison_tick(unit)
		Effect.FORGET:
			forget_tick(unit)

func sleep_tick(unit: Unit):
	unit.actions_avail.clear()
	unit.regain_health(magnitude)

func poison_tick(unit: Unit):
	unit.take_damage(magnitude, null)

func forget_tick(unit: Unit):
	unit.actions_avail.erase(Unit.Action.ATTACK)

# function that is called when status is first applied
func on_apply(unit: Unit):
	unit.status_icon.texture = icon

# function that is called when status has expired
func on_expire(unit: Unit):
	pass
