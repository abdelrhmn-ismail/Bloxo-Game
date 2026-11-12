class_name CellPainter
extends RefCounted
## Draws one block cell in NEON style: dark glass fill, bright glowing
## border, soft outer glow and a small shine. Change it here to restyle
## every block in the game.

static var _styles := {}


static func draw_cell(ci: CanvasItem, rect: Rect2, color: Color, alpha: float = 1.0) -> void:
	var a := snappedf(clampf(alpha, 0.0, 1.0), 0.05)
	if a <= 0.0:
		return
	var radius := int(rect.size.x * 0.18)
	var edge := maxi(2, int(rect.size.x * 0.09))
	var glow := maxi(2, int(rect.size.x * 0.12))

	# Body: tinted dark glass + bright border + glow (StyleBox shadow).
	var key := "cell|%s|%s|%d|%d|%d" % [color.to_html(), a, radius, edge, glow]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Color(color.darkened(0.45), 0.85 * a), radius)
		s.set_border_width_all(edge)
		s.border_color = Color(color.lightened(0.15), a)
		s.shadow_color = Color(color, 0.55 * a)
		s.shadow_size = glow
		_store(key, s)
	ci.draw_style_box(s, rect)

	# Shine: a thin light bar near the top.
	var shine := Rect2(
		rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.2),
		Vector2(rect.size.x * 0.4, rect.size.y * 0.1))
	ci.draw_style_box(_simple(Color(1, 1, 1, 0.45 * a), int(shine.size.y * 0.5)), shine)


static func draw_empty(ci: CanvasItem, rect: Rect2) -> void:
	var radius := int(rect.size.x * 0.18)
	var key := "empty|%d" % radius
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Palette.cell_empty, radius)
		s.set_border_width_all(maxi(1, int(rect.size.x * 0.03)))
		s.border_color = Palette.cell_empty_edge
		_store(key, s)
	ci.draw_style_box(s, rect)


static func _simple(color: Color, radius: int) -> StyleBoxFlat:
	var key := "simple|%s|%d" % [color.to_html(), radius]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(color, radius)
		_store(key, s)
	return s


static func _new_style(bg: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s


static func _store(key: String, s: StyleBoxFlat) -> void:
	if _styles.size() > 800:
		_styles.clear()
	_styles[key] = s
