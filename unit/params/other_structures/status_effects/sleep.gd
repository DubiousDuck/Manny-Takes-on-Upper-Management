extends StatusEffect

class_name SleepStatus

func on_apply(unit: Unit):
	super(unit)
	unit.actions_avail.clear()

func on_expire(unit: Unit):
	super(unit)
	if !unit.actions_avail.has(Unit.Action.MOVE):
		unit.actions_avail.append(Unit.Action.MOVE)
	if !unit.actions_avail.has(Unit.Action.ATTACK):
		unit.actions_avail.append(Unit.Action.ATTACK)
