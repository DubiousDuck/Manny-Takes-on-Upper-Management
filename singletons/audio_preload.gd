extends AudioStreamPlayer

const _battle_music = preload("res://assets/music/HR1 Full.wav")
const _OW_ONE_MUSIC = preload("res://assets/music/HR Overworld 1.wav")

const _47 = preload("res://assets/test_songs/4758872798134272.wav")
const _53 = preload("res://assets/test_songs/5388408074141696.wav")
const _54 = preload("res://assets/test_songs/5452190569857024.wav")
const _59 = preload("res://assets/test_songs/5946900010893312.wav")
const _64 = preload("res://assets/test_songs/6405233909039104.wav")

var lastTrack: int = 99
# Sorry I have listened to the music too many times. I will change it back later QAQ
var volValue: int = 0

func _ready():
	EventBus.connect("start_battle", _on_start_battle)
	EventBus.connect("back_to_overworld", _on_back_to_overworld)
	stream = _OW_ONE_MUSIC
	play()

func _on_finished():
	stream = _OW_ONE_MUSIC
	
	play()

func volChange(vol):
	volume_db = vol

func _on_start_battle():
	stream = _battle_music
	play()

func _on_back_to_overworld():
	if stream == _battle_music:
		_on_finished()

# Sound effects
const pof_sfx = preload("res://assets/sfx/sword_clash_pof.mp3")

func play_sfx(name: String):
	match name:
		"pof":
			$SfxPlayer.stream = pof_sfx
			$SfxPlayer.play()
