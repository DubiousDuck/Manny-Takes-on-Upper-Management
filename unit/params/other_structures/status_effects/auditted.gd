extends StatusEffect

class_name AuditEffect

func on_apply(unit: Unit):
	super(unit)
	unit.actions_avail.erase(Unit.Action.MOVE)

func on_expire(unit: Unit):
	super(unit)
	if !unit.actions_avail.has(Unit.Action.MOVE):
		unit.actions_avail.append(Unit.Action.MOVE)
