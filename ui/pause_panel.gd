class_name PausePanel
extends OverlayPanel

signal resume_pressed
signal restart_pressed
signal home_pressed


func _init() -> void:
	super()
	add_text("Paused", 96, Palette.text)
	add_button("Resume", func(): resume_pressed.emit(), Palette.button_primary)
	add_button("Restart", func(): restart_pressed.emit())
	add_button("Home", func(): home_pressed.emit())
	add_theme_button()
	add_toggle("Sound", "sound_on")
	add_toggle("Music", "music_on")
	add_toggle("Vibration", "vibration_on")
