extends AudioStreamPlayer

const _BATTLE_1_MUSIC = preload("res://assets/music/HR Level 1.ogg")
const _BATTLE_2_MUSIC = preload("res://assets/music/HR Level 2.ogg")
const _OW_ONE_MUSIC = preload("res://assets/music/HR Overworld 1.ogg")

var volValue: int = 0:
	set(new_val):
		volValue = new_val
		volume_db = volValue

## Dictionary that matches overworld to its theme
var overworld_themes: Dictionary = {
	"res://overworld/area_1.tscn": _OW_ONE_MUSIC,
	"res://overworld/area_2.tscn": _OW_ONE_MUSIC,
	"res://overworld/area_3.tscn": _OW_ONE_MUSIC
}

## Dictionary that matches battle level to its music
var battle_theme: Dictionary = {
	"level1-1": _BATTLE_1_MUSIC,
	"level1-2": _BATTLE_1_MUSIC,
	"level1-3": _BATTLE_1_MUSIC,
	"level1-4": _BATTLE_1_MUSIC,
	"level2-1": _BATTLE_2_MUSIC,
	"level2-2": _BATTLE_2_MUSIC,
	"level2-3": _BATTLE_2_MUSIC,
	"level2-4": _BATTLE_2_MUSIC
}

func _ready():
	EventBus.connect("start_battle", _on_start_battle)
	EventBus.connect("back_to_overworld", _on_back_to_overworld)
	volume_db = volValue
	stream = _OW_ONE_MUSIC
	play()

func _on_start_battle():
	stream = battle_theme.get(Global.current_level, _BATTLE_1_MUSIC)
	play()

func _on_back_to_overworld():
	var overworld_music: AudioStream = overworld_themes.get(Global.last_overworld_path, _OW_ONE_MUSIC)
	if stream != overworld_music:
		stream = overworld_music
		play()

# Sound effects
const pof_sfx = preload("res://assets/sfx/sword_clash_pof.mp3")
const BUTTON_CLICK_SFX = preload("res://assets/sfx/menu_click.mp3")

func play_sfx(name: String):
	match name:
		"pof":
			$SfxPlayer.stream = pof_sfx
			$SfxPlayer.play()
		"menu_click":
			$SfxPlayer.stream = BUTTON_CLICK_SFX
			$SfxPlayer.play()
		
