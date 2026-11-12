class_name PausePanel
extends OverlayPanel

signal resume_pressed
signal restart_pressed
signal home_pressed


func _init() -> void:
	super()
	add_text(Lang.t("PAUSED"), 96, Palette.text)
	add_button(Lang.t("RESUME"), func(): resume_pressed.emit(), Palette.button_primary)
	add_button(Lang.t("RESTART"), func(): restart_pressed.emit())
	add_button(Lang.t("HOME"), func(): home_pressed.emit())
	add_theme_button()
	add_language_button()
	add_toggle(Lang.t("SOUND"), "sound_on")
	add_toggle(Lang.t("MUSIC"), "music_on")
	add_toggle(Lang.t("VIBRATION"), "vibration_on")
	add_toggle(Lang.t("HINTS"), "hints_on")
