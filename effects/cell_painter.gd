class_name CellPainter
extends RefCounted
## Draws one block cell: rounded color + darker bottom edge + shine.
## This is the "look" of the blocks – change it here to restyle every block.
## (Later we can swap this for a 128x128 image if you design one.)

static var _styles := {}


static func draw_cell(ci: CanvasItem, rect: Rect2, color: Color, alpha: float = 1.0) -> void:
	var a := snappedf(clampf(alpha, 0.0, 1.0), 0.05)
	if a <= 0.0:
		return
	var radius := int(rect.size.x * 0.2)
	var edge := maxi(1, int(rect.size.y * 0.09))
	var base := Color(color, color.a * a)
	ci.draw_style_box(_style(base, radius, edge, Color(color.darkened(0.3), base.a)), rect)
	var shine := Rect2(
		rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.1),
		Vector2(rect.size.x * 0.68, rect.size.y * 0.18))
	ci.draw_style_box(_style(Color(1, 1, 1, 0.3 * a), int(shine.size.y * 0.5), 0, Color.TRANSPARENT), shine)


static func draw_empty(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_style_box(_style(Palette.cell_empty, int(rect.size.x * 0.2), 0, Color.TRANSPARENT), rect)


static func _style(bg: Color, radius: int, edge: int, edge_color: Color) -> StyleBoxFlat:
	var key := "%s|%d|%d|%s" % [bg.to_html(), radius, edge, edge_color.to_html()]
	if _styles.has(key):
		return _styles[key]
	if _styles.size() > 600:
		_styles.clear()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_width_bottom = edge
	s.border_color = edge_color
	s.anti_aliasing = true
	_styles[key] = s
	return s
