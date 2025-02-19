class_name PlayerData extends Resource

@export var player_name : String = "A"

# include party details here

## Activated talents
@export var protag_talents: Dictionary = {}
@export var company_talents: Dictionary = {}

## Current party
@export var max_party_num: int = 3
@export var current_party: Array[UnitData] = []
@export var reserves: Array[UnitData] = []
