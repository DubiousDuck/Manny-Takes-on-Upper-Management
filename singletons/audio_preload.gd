extends AudioStreamPlayer

const _BATTLE_1_MUSIC = preload("res://assets/music/HR Level 1.ogg")
const _BATTLE_2_MUSIC = preload("res://assets/music/HR Level 2.ogg")
const _OW_ONE_MUSIC = preload("res://assets/music/HR Overworld 1.ogg")

@onready var sfx_player = $SfxPlayer
@onready var second_sfx_player = $SecondSfxPlayer

var volValue: int = 0:
	set(new_val):
		volValue = new_val
		# Currently only one unified volumne for both sfx and music
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), volValue)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volValue)

## Dictionary that matches overworld to its theme
var overworld_themes: Dictionary = {
	"res://overworld/area_1.tscn": [_OW_ONE_MUSIC, 1.0],
	"res://overworld/area_2.tscn": [_OW_ONE_MUSIC, 0.9],
	"res://overworld/area_3.tscn": [_OW_ONE_MUSIC, 0.8]
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
	"level2-4": _BATTLE_2_MUSIC,
	"level3-1": _BATTLE_2_MUSIC,
	"level3-2": _BATTLE_2_MUSIC,
	"level3-3": _BATTLE_2_MUSIC
}

func _ready():
	EventBus.connect("start_battle", _on_start_battle)
	EventBus.connect("back_to_overworld", _on_back_to_overworld)
	volume_db = volValue
	stream = _OW_ONE_MUSIC
	play()

func _on_start_battle():
	stream = battle_theme.get(Global.current_level, _BATTLE_1_MUSIC)
	pitch_scale = 1
	play()

func _on_back_to_overworld():
	var theme_info: Array = overworld_themes.get(Global.last_overworld_path, [_OW_ONE_MUSIC, 1.0])
	var overworld_music: AudioStream = theme_info[0]
	if !playing: play()
	# pause for a bit if the stream or pitch_scale is different
	if abs(theme_info[1] - pitch_scale) > 0.001 or stream != overworld_music:
		#print("pitch was: %f but target pitch is: %f!" %[pitch_scale, theme_info[1]])
		#print("music was %s but target music is %s!" %[stream, overworld_music])
		stop()
		await get_tree().create_timer(0.2).timeout
		pitch_scale = theme_info[1]
		stream = overworld_music
		play()

# Sound effects
const pof_sfx = preload("res://assets/sfx/sword_clash_pof.mp3")
const BUTTON_CLICK_SFX = preload("res://assets/sfx/menu_click.mp3")
const VICTORY_SFX = preload("res://assets/sfx/victory_sfx.mp3")
const ERROR_SFX = preload("res://assets/sfx/Take Ur Meds SFX Level Fail.wav")
const SELECT_SFX = preload("res://assets/sfx/hitHurt.wav")
const CONFIRM_SFX = preload("res://assets/sfx/click.wav")

func play_sfx(name: String):
	match name:
		"pof":
			$SfxPlayer.stream = pof_sfx
			$SfxPlayer.play()
		"menu_click":
			$SfxPlayer.stream = BUTTON_CLICK_SFX
			$SfxPlayer.play()
		"victory":
			# stop music and play victory sfx
			stop()
			second_sfx_player.stream = VICTORY_SFX
			second_sfx_player.play()
		"error":
			$SfxPlayer.stream = ERROR_SFX
			$SfxPlayer.play()
		"select":
			$SfxPlayer.stream = SELECT_SFX
			$SfxPlayer.play()
		"confirm":
			$SfxPlayer.stream = CONFIRM_SFX
			$SfxPlayer.play()

func music_fade_in():
	var a = get_tree().create_tween()
	a.tween_property(self, "volume_linear", 1, 0.3)
	await a.finished
