extends Node

const HINT_UI = preload("res://ui/hint/HintUI.tscn")

var shown_once_ids := {} # For one-time hints
var idle_timer := Timer.new()
var current_hint_id := ""

signal hint_requested(text: String)
signal hint_hide(text: String)

func _ready():
	var ui = HINT_UI.instantiate()
	GlobalUI.add_child(ui)
	
	add_child(idle_timer)
	idle_timer.wait_time = 25
	idle_timer.one_shot = false
	idle_timer.timeout.connect(_on_idle_timeout)
	#idle_timer.start()

func trigger_hint(id: String, message: String, only_once := true):
	if only_once and id in shown_once_ids:
		return
	shown_once_ids[id] = true
	current_hint_id = id
	emit_signal("hint_requested", message)

func reset_idle_timer():
	idle_timer.start() # Call this on any meaningful player action

func _on_idle_timeout():
	trigger_hint("idle_hint", "Don't forget to move your units!", false)

func pause_idle_timer():
	idle_timer.paused = true

func continue_idle_timer():
	idle_timer.paused = false
	reset_idle_timer()

func hide_hint(id: String = ""):
	if current_hint_id == id or id == "":
		hint_hide.emit()
