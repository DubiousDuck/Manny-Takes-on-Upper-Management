extends AudioStreamPlayer

const _battle_music = preload("res://assets/music/HR1 Full.wav")

const _47 = preload("res://assets/test_songs/4758872798134272.wav")
const _53 = preload("res://assets/test_songs/5388408074141696.wav")
const _54 = preload("res://assets/test_songs/5452190569857024.wav")
const _59 = preload("res://assets/test_songs/5946900010893312.wav")
const _64 = preload("res://assets/test_songs/6405233909039104.wav")

var lastTrack: int = 99
var volValue: int = 69

func _ready():
	EventBus.connect("start_battle", _on_start_battle)
	EventBus.connect("back_to_overworld", _on_back_to_overworld)
	var i: int = randi_range(0,4)
	if i == 0:
		stream = _47
	elif i == 1:
		stream = _53
	elif i == 2:
		stream = _54
	elif i == 3:
		stream = _59
	elif i == 4:
		stream = _64
	lastTrack = i
	play()

func _on_finished():
	var i: int = randi_range(0,4)
	
	while i == lastTrack:
		i = randi_range(0,4)
	
	if i == 0:
		stream = _47
	elif i == 1:
		stream = _53
	elif i == 2:
		stream = _54
	elif i == 3:
		stream = _59
	elif i == 4:
		stream = _64
	
	lastTrack = i
	
	play()

func volChange(vol):
	volume_db = vol

func _on_start_battle():
	stream = _battle_music
	play()

func _on_back_to_overworld():
	if stream == _battle_music:
		_on_finished()
