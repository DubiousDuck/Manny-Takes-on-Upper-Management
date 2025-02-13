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
	if value <= 16.7:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconPitchBlack.png")
	elif value <= 33.3:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconTeenyWeeny.png")
	elif value <= 50.0:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconVerySmall.png")
	elif value <= 66.7:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconSmall.png")
	elif value <= 83.3:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconMedium.png")
	else:
		sun_image.texture = preload("res://ui/BrightnessSprites/BrightnessIconBig.png")
