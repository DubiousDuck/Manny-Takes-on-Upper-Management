extends Control

@onready var sun_image = $SunImage
@onready var h_slider = $HSlider
@onready var color_rect = $"../../ColorRect"

func _ready():
	print(Global.brightness_val)
	setBrightness(Global.brightness_val)
	h_slider.value = Global.brightness_val

func _on_h_slider_value_changed(value):
	setBrightness(value)

func setBrightness(value):
	color_rect.color.a = min(1.0 - (float(value) / 100.0),0.95)
	Global.brightness_val = value
	if value <= 0:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (4).png")
	elif value <= 25:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (3).png")
	elif value <= 50:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (2).png")
	elif value <= 75:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (1).png")
	elif value < 100:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider.png")
	else:
		sun_image.texture = preload("res://ui/VolumeSprites/Splatcho Volume Slider (6).png")
