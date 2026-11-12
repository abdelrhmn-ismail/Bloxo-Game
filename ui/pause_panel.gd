class_name PausePanel
extends OverlayPanel
## Pause: only the essentials. Settings are behind the gear icon.

signal resume_pressed
signal restart_pressed
signal home_pressed
signal settings_pressed


func _init() -> void:
	super()
	# Title row: "Paused" + gear button.
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	box.add_child(title_row)
	var title := UIKit.label(Lang.t("PAUSED"), 88, Palette.text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var gear := IconButton.new("gear", 120.0, Palette.text_dim)
	gear.pressed.connect(func(): settings_pressed.emit())
	title_row.add_child(gear)

	add_button(Lang.t("RESUME"), func(): resume_pressed.emit(), Palette.button_primary)
	add_button(Lang.t("RESTART"), func(): restart_pressed.emit())
	add_button(Lang.t("HOME"), func(): home_pressed.emit())
