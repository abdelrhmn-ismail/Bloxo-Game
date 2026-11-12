class_name UIKit
extends RefCounted
## Small helpers to build good-looking labels and buttons from code.


static func style_label(l: Label, font_size: int, color: Color) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.outline)
	l.add_theme_constant_override("outline_size", maxi(4, int(font_size * 0.14)))


static func label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, font_size, color)
	return l


static func panel_style(color: Color, radius: int, padding: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(padding)
	s.anti_aliasing = true
	return s


static func button(text: String, min_size: Vector2, font_size: int = 52, color: Color = Color.TRANSPARENT) -> Button:
	if color == Color.TRANSPARENT:
		color = Palette.button
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_outline_color", color.darkened(0.45))
	b.add_theme_constant_override("outline_size", maxi(4, int(font_size * 0.12)))

	b.add_theme_stylebox_override("normal", _button_style(color, 10))
	b.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08), 10))
	b.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.08), 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Audio.play("click"))
	return b


static func _button_style(color: Color, edge: int) -> StyleBoxFlat:
	var s := panel_style(color, 36, 20)
	s.border_width_bottom = edge
	s.border_color = color.darkened(0.35)
	s.content_margin_top = 20 + (10 - edge)
	return s
