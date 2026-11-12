class_name OverlayPanel
extends Control
## Base for pop-up windows (pause, game over): dims the screen and
## shows a centered neon panel. Subclasses add rows with add_*().

var box: VBoxContainer
var panel: PanelContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.0, 0.04, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel",
		UIKit.neon_panel_style(Palette.panel, Palette.panel_edge, 48, 56, 5, 30))
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
	var b := UIKit.button(text, Vector2(640, 140), 52, color)
	b.pressed.connect(on_press)
	box.add_child(b)
	return b


## A button that switches to the next theme (the screen rebuilds itself).
func add_theme_button() -> Button:
	var b := UIKit.button("%s: %s" % [Lang.t("THEME"), Palette.display_name()], Vector2(640, 110), 40, Palette.accent)
	b.pressed.connect(func(): Palette.cycle_theme())
	box.add_child(b)
	return b


## A button that switches to the next language (the screen rebuilds itself).
func add_language_button() -> Button:
	var b := UIKit.button("%s: %s" % [Lang.t("LANGUAGE"), Lang.language_name()], Vector2(640, 110), 40, Palette.button)
	b.pressed.connect(func(): Lang.cycle_language())
	box.add_child(b)
	return b


## A button that flips an on/off setting stored in SaveData.
func add_toggle(title: String, setting: String) -> Button:
	var b := UIKit.button("", Vector2(640, 110), 40, Palette.text_dim)
	var refresh := func(): b.text = "%s: %s" % [title, Lang.t("ON") if SaveData.get(setting) else Lang.t("OFF")]
	refresh.call()
	b.pressed.connect(func():
		if not UIKit.accept_action():
			return
		SaveData.set(setting, not SaveData.get(setting))
		SaveData.write()
		Audio.refresh_music()
		refresh.call())
	box.add_child(b)
	return b
