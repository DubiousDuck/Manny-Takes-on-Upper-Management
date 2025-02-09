extends Node

enum BattleResult {PLAYER_VICTORY, ENEMY_VICTORY, TIE}

#Cell Highlights
signal show_cell_highlights(positions : Array, color : Color, emitter_name : String)
signal remove_cell_highlights(emitter_name : String) #remove highlight requested by a specific entity
signal remove_all_cell_highlights() #remove all highlight on the board

#Cell Information
signal occupy_cell(pos : Vector2i, unit_type : String)
signal clear_cells()
signal update_cell_status()

#Attack/Skill System
signal attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i])
signal skill_chosen(skill: SkillInfo)

#Battle Information
signal unit_died()
signal battle_ended(result: int)
signal unit_on_standby()

#Skill Tree
signal talent_node_pressed()
signal disable_all_nodes()
signal reset_talent_levels()
