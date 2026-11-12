class_name UIKit
extends RefCounted
## Small helpers to build themed labels, buttons and panels from code.
## Colors and style come from Palette (the current theme).
## The font (Audiowide) is set for the whole project in project.godot.


## Text with an outline; glowing themes also get a soft colored halo.
static func style_label(l: Label, font_size: int, color: Color) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.outline)
	l.add_theme_constant_override("outline_size", maxi(4, int(font_size * 0.1)))
	if Palette.glow_ui:
		l.add_theme_color_override("font_shadow_color", Color(color, 0.35))
		l.add_theme_constant_override("shadow_outline_size", maxi(6, int(font_size * 0.3)))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
	else:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.15))
		l.add_theme_constant_override("shadow_outline_size", 0)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", maxi(2, int(font_size * 0.05)))


static func label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, font_size, color)
	return l


## Plain rounded box.
static func panel_style(color: Color, radius: int, padding: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(padding)
	s.anti_aliasing = true
	return s


## Box with a colored border. Glowing themes get a colored glow around it,
## the others a soft drop shadow.
static func neon_panel_style(fill: Color, edge: Color, radius: int, padding: int = 0, border: int = 4, glow: int = 18) -> StyleBoxFlat:
	var s := panel_style(fill, radius, padding)
	s.set_border_width_all(border)
	s.border_color = edge
	if Palette.glow_ui:
		s.shadow_color = Color(edge, 0.45)
		s.shadow_size = glow
	else:
		s.shadow_color = Color(0, 0, 0, 0.18)
		s.shadow_size = maxi(4, int(glow * 0.6))
		s.shadow_offset = Vector2(0, glow * 0.4)
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
	b.add_theme_constant_override("outline_size", maxi(4, int(font_size * 0.1)))

	if Palette.solid_buttons:
		# Solid colored button with a darker 3D bottom edge.
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(state, Color.WHITE)
		b.add_theme_color_override("font_outline_color", color.darkened(0.4))
		b.add_theme_stylebox_override("normal", _solid_style(color, 10))
		b.add_theme_stylebox_override("hover", _solid_style(color.lightened(0.08), 10))
		b.add_theme_stylebox_override("pressed", _solid_style(color.darkened(0.08), 3))
	else:
		# Dark glass button with a glowing colored edge.
		b.add_theme_color_override("font_color", color.lightened(0.35))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_outline_color", Palette.outline)
		var fill := Color(color.darkened(0.75), 0.92)
		b.add_theme_stylebox_override("normal", neon_panel_style(fill, color, 36, 20, 5, 16))
		b.add_theme_stylebox_override("hover", neon_panel_style(fill.lightened(0.08), color.lightened(0.2), 36, 20, 5, 22))
		b.add_theme_stylebox_override("pressed", neon_panel_style(Color(color.darkened(0.4), 0.95), Color.WHITE, 36, 20, 5, 26))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): Audio.play("click"))
	return b


static func _solid_style(color: Color, edge: int) -> StyleBoxFlat:
	var s := panel_style(color, 36, 20)
	s.border_width_bottom = edge
	s.border_color = color.darkened(0.3)
	s.content_margin_top = 20 + (10 - edge)
	s.shadow_color = Color(0, 0, 0, 0.15)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 4)
	return s


## How much of the top/bottom of the screen is covered by a notch or
## system bars, in game units. Zero on desktop.
static func safe_insets(viewport: Viewport) -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if screen.y <= 0.0 or safe.size.y <= 0:
		return Vector2.ZERO
	var scale := viewport.get_visible_rect().size.y / screen.y
	var top := safe.position.y * scale
	var bottom := (screen.y - (safe.position.y + safe.size.y)) * scale
	return Vector2(maxf(top, 0.0), maxf(bottom, 0.0))
