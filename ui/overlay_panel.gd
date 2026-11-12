class_name OverlayPanel
extends Control
## Base for pop-up windows (pause, game over): dims the screen and
## shows a centered rounded panel. Subclasses add rows with add_*().

var box: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", UIKit.panel_style(Palette.panel, 48, 56))
	center.add_child(panel)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func add_text(text: String, font_size: int, color: Color) -> Label:
	var l := UIKit.label(text, font_size, color)
	box.add_child(l)
	return l


func add_button(text: String, on_press: Callable, color: Color = Color.TRANSPARENT) -> Button:
	var b := UIKit.button(text, Vector2(640, 140), 56, color)
	b.pressed.connect(on_press)
	box.add_child(b)
	return b


## A button that flips an on/off setting stored in SaveData.
func add_toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(640, 110), 44, Palette.button.darkened(0.2))
	var refresh := func(): b.text = "%s: %s" % [title, "ON" if SaveData.get(setting) else "OFF"]
	refresh.call()
	b.pressed.connect(func():
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	box.add_child(b)
	return b
