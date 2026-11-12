class_name SettingsPanel
extends OverlayPanel
## Settings behind the gear icon, grouped in sections:
##   Sound & vibration – Sound / Music / Vibration toggles side by side
##   Look & language   – Theme, Language
##   Gameplay          – Hints (+ How to play, from the menu only)
## Theme / language changes rebuild the screen; the owner re-opens this
## panel afterwards so the player stays in Settings.

signal back_pressed
signal how_to_play_pressed


## show_how_to_play: true in the main menu (in a game it would leave the board).
func setup(show_how_to_play: bool) -> void:
	box.add_theme_constant_override("separation", 18)
	add_text(Lang.t("SETTINGS"), 88, Palette.text)

	_section(Lang.t("SECTION_AUDIO"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	row.add_child(_small_toggle(Lang.t("SOUND"), "sound_on"))
	row.add_child(_small_toggle(Lang.t("MUSIC"), "music_on"))
	row.add_child(_small_toggle(Lang.t("VIBRATION"), "vibration_on"))

	_section(Lang.t("SECTION_LOOK"))
	var theme_btn := UIKit.button(("%s: %s" % [Lang.t("THEME"), Palette.display_name()]).to_upper(),
		Vector2(640, 100), 38, Palette.accent)
	theme_btn.pressed.connect(func(): Palette.cycle_theme())
	box.add_child(theme_btn)
	var lang_btn := UIKit.button(("%s: %s" % [Lang.t("LANGUAGE"), Lang.language_name()]).to_upper(),
		Vector2(640, 100), 38, Palette.button)
	lang_btn.pressed.connect(func(): Lang.cycle_language())
	box.add_child(lang_btn)

	_section(Lang.t("SECTION_GAME"))
	var hints := _small_toggle(Lang.t("HINTS"), "hints_on")
	hints.custom_minimum_size = Vector2(640, 100)
	hints.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(hints)
	if show_how_to_play:
		var help := UIKit.button(Lang.t("HOW_TO_PLAY").to_upper(), Vector2(640, 100), 38, Palette.text_dim)
		help.pressed.connect(func(): how_to_play_pressed.emit())
		box.add_child(help)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)
	add_button(Lang.t("BACK"), func(): back_pressed.emit(), Palette.button_primary)


func _section(title: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	box.add_child(gap)
	add_text(title.to_upper(), 34, Palette.text_dim)


## Compact on/off button ("Music\nON") that flips a SaveData setting.
func _small_toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(205, 120), 30, Palette.text_dim)
	var refresh := func():
		var state := Lang.t("ON") if SaveData.get(setting) else Lang.t("OFF")
		b.text = "%s\n%s" % [title, state] if setting != "hints_on" else "%s: %s" % [title, state]
	refresh.call()
	b.pressed.connect(func():
		if not UIKit.accept_action():
			return
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	return b
