class_name Flag extends Node

@export var event : String

@export_enum(
	"if_event_has_happened",
	"if_event_hasnt_happened"
) var trigger

@export_enum(
	"every_frame",
	"on_ready"
) var frequency

func _ready():
	check_condition()

func _process(_delta):
	if frequency == 0:
		check_condition()
		
func check_condition():
	if trigger == 0:
		if Global.events.has(event):
			act()
	elif trigger == 1:
		if !Global.events.has(event):
			act()
		
func act():
	print("Flag for event " + event + " has been triggered! (flag.gd)")
	queue_free()
