class_name MenuScreen
extends Control
## Start screen: logo, title, best score, play button, settings.

signal play_pressed


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 40)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var logo := LogoBlocks.new()
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)

	var title_text := str(ProjectSettings.get_setting("application/config/name", "Bloxo"))
	box.add_child(UIKit.label(title_text.to_upper(), 120, Palette.text))
	box.add_child(UIKit.label("BEST  %d" % SaveData.best_score, 56, Palette.accent))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	box.add_child(spacer)

	var play := UIKit.button("PLAY", Vector2(600, 180), 80, Palette.button_primary)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func(): play_pressed.emit())
	box.add_child(play)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	row.add_child(_toggle("Sound", "sound_on"))
	row.add_child(_toggle("Music", "music_on"))
	row.add_child(_toggle("Vibrate", "vibration_on"))

	Audio.play_music()


func _toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(250, 110), 36, Palette.button.darkened(0.2))
	var refresh := func(): b.text = "%s\n%s" % [title, "ON" if SaveData.get(setting) else "OFF"]
	refresh.call()
	b.pressed.connect(func():
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	return b
