extends Node2D

class_name SingleTile

func _ready():
	$AnimationPlayer.play_backwards("disappear")
