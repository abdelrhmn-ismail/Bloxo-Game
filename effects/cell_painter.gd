class_name CellPainter
extends RefCounted
## Draws one block cell in the current theme's style (Palette.block_style):
##   neon   – dark glass, bright glowing border
##   candy  – glossy rounded candy with a 3D bottom edge
##   gems   – cut jewel with light/dark facets and a sparkle
##   nature – leaf-green style tile with a vein and soft shadow
## Change a style here to restyle every block in the game.

static var _styles := {}


static func draw_cell(ci: CanvasItem, rect: Rect2, color: Color, alpha: float = 1.0) -> void:
	var a := snappedf(clampf(alpha, 0.0, 1.0), 0.05)
	if a <= 0.0:
		return
	match Palette.block_style:
		"candy":
			_candy(ci, rect, color, a)
		"gems":
			_gem(ci, rect, color, a)
		"nature":
			_nature(ci, rect, color, a)
		_:
			_neon(ci, rect, color, a)


static func draw_empty(ci: CanvasItem, rect: Rect2) -> void:
	var radius := int(rect.size.x * Palette.cell_radius)
	var key := "empty|%s|%s|%d" % [Palette.cell_empty.to_html(), Palette.cell_empty_edge.to_html(), radius]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Palette.cell_empty, radius)
		s.set_border_width_all(maxi(1, int(rect.size.x * 0.03)))
		s.border_color = Palette.cell_empty_edge
		_store(key, s)
	ci.draw_style_box(s, rect)


# --- styles ----------------------------------------------------------------

static func _neon(ci: CanvasItem, rect: Rect2, color: Color, a: float) -> void:
	var w := rect.size.x
	var key := "neon|%s|%s|%d" % [color.to_html(), a, int(w)]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Color(color.darkened(0.45), 0.85 * a), int(w * Palette.cell_radius))
		s.set_border_width_all(maxi(2, int(w * 0.09)))
		s.border_color = Color(color.lightened(0.15), a)
		s.shadow_color = Color(color, 0.55 * a)
		s.shadow_size = maxi(2, int(w * 0.12))
		_store(key, s)
	ci.draw_style_box(s, rect)
	_shine(ci, rect, Vector2(0.22, 0.2), Vector2(0.4, 0.1), 0.45 * a)


static func _candy(ci: CanvasItem, rect: Rect2, color: Color, a: float) -> void:
	var w := rect.size.x
	var key := "candy|%s|%s|%d" % [color.to_html(), a, int(w)]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Color(color, a), int(w * Palette.cell_radius))
		s.border_width_bottom = maxi(2, int(w * 0.12))
		s.border_color = Color(color.darkened(0.25), a)
		s.shadow_color = Color(0.3, 0.1, 0.3, 0.18 * a)
		s.shadow_size = maxi(1, int(w * 0.05))
		s.shadow_offset = Vector2(0, w * 0.06)
		_store(key, s)
	ci.draw_style_box(s, rect)
	_shine(ci, rect, Vector2(0.16, 0.1), Vector2(0.68, 0.26), 0.5 * a)
	# little sugar dot
	ci.draw_circle(rect.position + rect.size * Vector2(0.74, 0.62), w * 0.06, Color(1, 1, 1, 0.55 * a))


static func _gem(ci: CanvasItem, rect: Rect2, color: Color, a: float) -> void:
	var w := rect.size.x
	# soft glow behind the jewel
	var key := "gemglow|%s|%s|%d" % [color.to_html(), a, int(w)]
	var g: StyleBoxFlat = _styles.get(key)
	if g == null:
		g = _new_style(Color(color.darkened(0.5), a), int(w * Palette.cell_radius))
		g.shadow_color = Color(color, 0.4 * a)
		g.shadow_size = maxi(2, int(w * 0.1))
		_store(key, g)
	ci.draw_style_box(g, rect)

	var o := [rect.position, rect.position + Vector2(w, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	var inner := rect.grow(-w * 0.24)
	var i := [inner.position, inner.position + Vector2(inner.size.x, 0), inner.end, inner.position + Vector2(0, inner.size.y)]
	_poly(ci, [o[0], o[1], i[1], i[0]], Color(color.lightened(0.35), a)) # top
	_poly(ci, [o[1], o[2], i[2], i[1]], Color(color.darkened(0.15), a)) # right
	_poly(ci, [o[2], o[3], i[3], i[2]], Color(color.darkened(0.35), a)) # bottom
	_poly(ci, [o[3], o[0], i[0], i[3]], Color(color.lightened(0.12), a)) # left
	_poly(ci, i, Color(color.lightened(0.05), a)) # table
	ci.draw_polyline(PackedVector2Array([o[0], o[1], o[2], o[3], o[0]]),
		Color(color.darkened(0.55), a), maxf(1.0, w * 0.03))
	# sparkle
	var c: Vector2 = i[0] + Vector2(w * 0.08, w * 0.08)
	var r := w * 0.09
	_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.25, 0), c + Vector2(0, r), c + Vector2(-r * 0.25, 0)], Color(1, 1, 1, 0.85 * a))
	_poly(ci, [c + Vector2(-r, 0), c + Vector2(0, -r * 0.25), c + Vector2(r, 0), c + Vector2(0, r * 0.25)], Color(1, 1, 1, 0.85 * a))


static func _nature(ci: CanvasItem, rect: Rect2, color: Color, a: float) -> void:
	var w := rect.size.x
	var key := "nature|%s|%s|%d" % [color.to_html(), a, int(w)]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Color(color, a), int(w * Palette.cell_radius))
		s.set_border_width_all(maxi(1, int(w * 0.05)))
		s.border_color = Color(color.darkened(0.3), a)
		s.shadow_color = Color(0.15, 0.1, 0.0, 0.25 * a)
		s.shadow_size = maxi(1, int(w * 0.03))
		s.shadow_offset = Vector2(0, w * 0.05)
		_store(key, s)
	ci.draw_style_box(s, rect)
	# leaf vein
	var vein := Color(color.lightened(0.35), 0.6 * a)
	var p0 := rect.position + rect.size * Vector2(0.25, 0.75)
	var p1 := rect.position + rect.size * Vector2(0.75, 0.25)
	var t := maxf(1.0, w * 0.035)
	ci.draw_line(p0, p1, vein, t)
	for k in [0.35, 0.6]:
		var m := p0.lerp(p1, k)
		ci.draw_line(m, m + Vector2(-w * 0.14, -w * 0.02), vein, t * 0.8)
		ci.draw_line(m, m + Vector2(w * 0.02, w * 0.14), vein, t * 0.8)
	_shine(ci, rect, Vector2(0.14, 0.12), Vector2(0.3, 0.09), 0.35 * a)


# --- helpers -----------------------------------------------------------------

static func _shine(ci: CanvasItem, rect: Rect2, pos: Vector2, size: Vector2, alpha: float) -> void:
	var r := Rect2(rect.position + rect.size * pos, rect.size * size)
	var key := "shine|%s|%d" % [snappedf(alpha, 0.05), int(r.size.y * 0.5)]
	var s: StyleBoxFlat = _styles.get(key)
	if s == null:
		s = _new_style(Color(1, 1, 1, alpha), int(r.size.y * 0.5))
		_store(key, s)
	ci.draw_style_box(s, r)


static func _poly(ci: CanvasItem, points: Array, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(points), color)


static func _new_style(bg: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s


static func _store(key: String, s: StyleBoxFlat) -> void:
	if _styles.size() > 1500:
		_styles.clear()
	_styles[key] = s
