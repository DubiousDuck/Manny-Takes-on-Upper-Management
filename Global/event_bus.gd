extends Node

enum BattleResult {PLAYER_VICTORY, ENEMY_VICTORY, TIE}

#Cell Highlights
signal show_cell_highlights(positions : Array, color : Color, emitter_name : String)
signal remove_cell_highlights(emitter_name : String) #remove highlight requested by a specific entity
signal remove_all_cell_highlights() #remove all highlight on the board

#Cell Information
signal occupy_cell(pos : Vector2i, unit_type : String)
signal clear_cells()
signal update_cell_status(stacking: bool)

#Attack/Skill System
signal attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i])
signal skill_chosen(skill: SkillInfo)
signal action_command_used(position: Vector2)
signal camera_done()

#Battle Information
signal unit_died()
signal battle_ended(result: int)  #0 is win, 1 is lose
signal unit_on_standby()

#Skill Tree
signal talent_node_pressed()
signal disable_all_nodes()
signal reset_talent_levels()

#Leveling System
signal give_experience(value)

#Party management
signal dragging_start()
signal dragging_stop()

#UI
signal ui_element_started
signal ui_element_ended
signal dialogue(text : Array[String])

#global player inputs
signal input_advance
signal input_back

#Transition
signal start_battle
signal back_to_overworld
