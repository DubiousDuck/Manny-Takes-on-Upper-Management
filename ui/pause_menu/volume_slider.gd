extends Control

@onready var speaker_image = $SpeakerImage
@onready var h_slider = $HSlider

func _ready():
	setMusicVol(AudioPreload.volValue)
	h_slider.value = AudioPreload.volValue

func _on_h_slider_value_changed(value):
	setMusicVol(value)

func setMusicVol(value):
	AudioPreload.volume_db = log(value / 100) * 20.0 + 5.0
	AudioPreload.volValue = value
	if value <= 0:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (4).png")
	elif value <= 25:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (3).png")
	elif value <= 50:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (2).png")
	elif value <= 75:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (1).png")
	elif value < 100:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider.png")
	else:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (6).png")
