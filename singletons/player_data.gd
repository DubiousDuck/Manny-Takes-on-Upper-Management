class_name PlayerData extends Resource

@export var index : int = -99

@export var player_name : String = "A"

# include party details here

## Player level
@export var current_exp: int
@export var level: int

## Current party
@export var recruit_token: int = 0
@export var max_party_num: int = 3
@export var current_party: Array[UnitData] = [preload("res://unit/params/protagonist.tres")]
@export var reserves: Array[UnitData] = []

## Level Progess
@export var finished_levels := {}
