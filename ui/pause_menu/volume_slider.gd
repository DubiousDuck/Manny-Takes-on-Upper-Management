extends Control

@onready var speaker_image = $SpeakerImage
@onready var h_slider = $HSlider

func _ready():
	var linear_val := db_to_linear(AudioPreload.volValue)
	setMusicVol(linear_val)
	h_slider.value = linear_val

func _on_h_slider_value_changed(value):
	setMusicVol(value)

## Expects a value in linear form
func setMusicVol(value):
	AudioPreload.volValue = linear_to_db(value)
	if value <= 0:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (4).png")
	elif value <= 0.25:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (3).png")
	elif value <= 0.5:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (2).png")
	elif value <= 0.75:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (1).png")
	elif value <= 1:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider.png")
	else:
		speaker_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (6).png")
