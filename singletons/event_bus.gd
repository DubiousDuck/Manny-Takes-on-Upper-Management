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
signal set_cell(pos: Vector2i, id: int)
signal set_cell_done()

#Attack/Skill System
signal attack_used(attack: SkillInfo, attacker: Unit, targets: Array[Vector2i])
signal skill_chosen(skill: SkillInfo)
signal action_command_used(position: Vector2)
signal camera_done()
signal attack_resolved()

#Battle Information
signal unit_died(unit: Unit)
signal battle_ended(result: int)  #0 is win, 1 is lose
signal unit_on_standby()
signal pass_turn()
signal battle_started()
signal units_left_changed

# Unit Preview
signal unit_hovered(unit: Unit)
signal unit_unhovered(unit: Unit)
signal unit_right_clicked(unit: Unit)
signal clear_preview()

signal show_skill_select(unit: Unit, valid_skills: Array[SkillInfo])
signal hide_skill_select()
signal cancel_select_unit()

#Party management
signal dragging_start(type: String)
signal dragging_stop(type: String)
signal remove_item()

#UI
signal ui_element_started
signal ui_element_ended

signal dialogue(text : Array[String])
signal dialogue_finished

signal ui_choice_chosen(text : String)

#global player inputs
signal input_advance
signal input_back

#Transition
signal start_battle
signal back_to_overworld

# Tutorial triggers
signal tutorial_trigger(trigger: String)
signal tutorial_finished
