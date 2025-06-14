extends StatusEffect

class_name ForgetStatus

func on_apply(unit: Unit):
	super(unit)
	unit.actions_avail.erase(Unit.Action.ATTACK)

func on_expire(unit: Unit):
	super(unit)
	if !unit.actions_avail.has(Unit.Action.ATTACK):
		unit.actions_avail.append(Unit.Action.ATTACK)
