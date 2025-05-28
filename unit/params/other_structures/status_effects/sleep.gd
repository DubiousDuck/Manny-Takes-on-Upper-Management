extends StatusEffect

class_name SleepStatus

func on_apply(unit: Unit):
	super(unit)
	unit.actions_avail.clear()
