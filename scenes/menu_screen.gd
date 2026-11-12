class_name MenuScreen
extends Control
## Start screen: logo, best score, Continue / Play, settings, theme and
## language. Main rebuilds it when the theme or language changes.

## resume = true when the player picked "Continue".
signal play_pressed(resume: bool)
signal how_to_play_pressed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var logo := NeonLogo.new(32.0)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)
	box.add_child(UIKit.label(Lang.t("BLOCK_PUZZLE"), 44, Palette.text_dim))
	box.add_child(UIKit.label("%s  %d" % [Lang.t("BEST"), SaveData.best_score], 56, Palette.accent))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	box.add_child(spacer)

	if SaveData.has_saved_game():
		box.add_child(_big_button(Lang.t("CONTINUE"), Palette.button_primary, true))
		box.add_child(_big_button(Lang.t("NEW_GAME"), Palette.button, false))
	else:
		box.add_child(_big_button(Lang.t("PLAY"), Palette.button_primary, false))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	row.add_child(_toggle(Lang.t("SOUND"), "sound_on"))
	row.add_child(_toggle(Lang.t("MUSIC"), "music_on"))
	row.add_child(_toggle(Lang.t("VIBRATION"), "vibration_on"))

	# Theme / language switches: the menu is rebuilt in the new style (see Main).
	var theme_btn := _wide_button("%s: %s" % [Lang.t("THEME"), Palette.display_name()], Palette.accent)
	theme_btn.pressed.connect(func(): Palette.cycle_theme())
	box.add_child(theme_btn)
	var lang_btn := _wide_button("%s: %s" % [Lang.t("LANGUAGE"), Lang.language_name()], Palette.button)
	lang_btn.pressed.connect(func(): Lang.cycle_language())
	box.add_child(lang_btn)
	var help_btn := _wide_button(Lang.t("HOW_TO_PLAY"), Palette.text_dim)
	help_btn.pressed.connect(func(): how_to_play_pressed.emit())
	box.add_child(help_btn)

	Audio.play_music()


func _big_button(text: String, color: Color, resume: bool) -> Button:
	var b := UIKit.button(text, Vector2(620, 170), 68, color)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): play_pressed.emit(resume))
	return b


func _wide_button(text: String, color: Color) -> Button:
	var b := UIKit.button(text.to_upper(), Vector2(700, 110), 40, color)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b


func _toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(280, 120), 32, Palette.text_dim)
	var refresh := func(): b.text = "%s\n%s" % [title, Lang.t("ON") if SaveData.get(setting) else Lang.t("OFF")]
	refresh.call()
	b.pressed.connect(func():
		if not UIKit.accept_action():
			return
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	return b
