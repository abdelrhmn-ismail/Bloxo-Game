class_name CellPainter
extends RefCounted
## Draws one block cell in the current theme's style (Palette.block_style):
##   neon   – dark glass, bright glowing border
##   candy  – glossy rounded candy with a 3D bottom edge
##   gems   – cut jewel with light/dark facets and a sparkle
##   nature – leaf-green style tile with a vein and soft shadow
## Change a style here to restyle every block in the game.
##
## Speed: every cell is drawn at one base size and scaled with
## draw_set_transform, so the cached StyleBoxes are reused even while a
## piece grows or shrinks in an animation (otherwise each new pixel size
## built new StyleBoxes every frame and made animations stutter on phones).

const K_NEON := 1
const K_CANDY := 2
const K_GEM_GLOW := 3
const K_NATURE := 4
const K_SHINE := 5

## Size every cell is drawn at before scaling. GameScreen sets it to the
## board cell size, so board cells are drawn 1:1.
static var base_size := 128.0
static var _styles := {}
static var _empty_style: StyleBoxFlat
static var _empty_sig: Array = []


## Called when the board cell size changes (new screen size).
static func set_base_size(size: float) -> void:
	if size > 1.0 and not is_equal_approx(size, base_size):
		base_size = size
		_styles.clear()


static func draw_cell(ci: CanvasItem, rect: Rect2, color: Color, alpha: float = 1.0) -> void:
	var a := snappedf(clampf(alpha, 0.0, 1.0), 0.05)
	if a <= 0.0 or rect.size.x <= 0.0:
		return
	var k := rect.size.x / base_size
	var local := Rect2(Vector2.ZERO, rect.size / k)
	ci.draw_set_transform(rect.position, 0.0, Vector2(k, k))
	match Palette.block_style:
		"candy":
			_candy(ci, local, color, a)
		"gems":
			_gem(ci, local, color, a)
		"nature":
			_nature(ci, local, color, a)
		_:
			_neon(ci, local, color, a)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Empty board cells are always drawn at the board size, so one style.
static func draw_empty(ci: CanvasItem, rect: Rect2) -> void:
	var sig := [Palette.cell_empty, Palette.cell_empty_edge, Palette.cell_radius, rect.size.x]
	if _empty_style == null or sig != _empty_sig:
		var radius := int(rect.size.x * Palette.cell_radius)
		_empty_style = _new_style(Palette.cell_empty, radius)
		_empty_style.set_border_width_all(maxi(1, int(rect.size.x * 0.03)))
		_empty_style.border_color = Palette.cell_empty_edge
		_empty_sig = sig
	ci.draw_style_box(_empty_style, rect)


## Number key for the style cache (much cheaper than building strings).
static func _key(kind: int, color: Color, a: float, w: float) -> int:
	return ((kind * 4096 + clampi(int(w), 0, 4095)) * 32 + roundi(a * 20.0)) * 4294967296 \
		+ color.to_rgba32()


# --- styles ----------------------------------------------------------------

static func _neon(ci: CanvasItem, rect: Rect2, color: Color, a: float) -> void:
	var w := rect.size.x
	var key := _key(K_NEON, color, a, w)
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
	var key := _key(K_CANDY, color, a, w)
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
	var key := _key(K_GEM_GLOW, color, a, w)
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
	var key := _key(K_NATURE, color, a, w)
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
	var key := _key(K_SHINE, Color.WHITE, snappedf(alpha, 0.05), r.size.y * 0.5)
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


static func _store(key: int, s: StyleBoxFlat) -> void:
	if _styles.size() > 1500:
		_styles.clear()
	_styles[key] = s
