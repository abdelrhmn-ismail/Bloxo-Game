class_name MenuScreen
extends Control
## Start screen: logo, best score, Continue / Play, settings.

## resume = true when the player picked "Continue".
signal play_pressed(resume: bool)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 36)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var logo := NeonLogo.new(32.0)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)
	box.add_child(UIKit.label("BLOCK PUZZLE", 44, Palette.text_dim))
	box.add_child(UIKit.label("BEST  %d" % SaveData.best_score, 56, Palette.accent))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	box.add_child(spacer)

	if SaveData.has_saved_game():
		box.add_child(_big_button("CONTINUE", Palette.button_primary, true))
		box.add_child(_big_button("NEW GAME", Palette.button, false))
	else:
		box.add_child(_big_button("PLAY", Palette.button_primary, false))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	row.add_child(_toggle("Sound", "sound_on"))
	row.add_child(_toggle("Music", "music_on"))
	row.add_child(_toggle("Vibrate", "vibration_on"))

	# Theme switch: the menu rebuilds itself in the new theme (see Main).
	var theme_btn := UIKit.button("THEME: %s" % Palette.theme_name.to_upper(), Vector2(620, 120), 44, Palette.accent)
	theme_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	theme_btn.pressed.connect(func(): Palette.cycle_theme())
	box.add_child(theme_btn)

	Audio.play_music()


func _big_button(text: String, color: Color, resume: bool) -> Button:
	var b := UIKit.button(text, Vector2(620, 170), 72, color)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): play_pressed.emit(resume))
	return b


func _toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(260, 120), 32, Palette.text_dim)
	var refresh := func(): b.text = "%s\n%s" % [title, "ON" if SaveData.get(setting) else "OFF"]
	refresh.call()
	b.pressed.connect(func():
		if not UIKit.accept_action():
			return
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	return b
