class_name GradientBackground
extends Node2D
## Animated background for the current theme (Palette.background_style):
##   neon   – scrolling synthwave grid
##   candy  – floating bubbles
##   gems   – twinkling sparkles
##   nature – rolling hills and falling leaves
## All use the vertical gradient from Palette.background_top → bottom.

var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _bubbles: Array = []
var _sparkles: Array = []
var _leaves: Array = []


func _ready() -> void:
	_rng.seed = 7
	for i in 18:
		_bubbles.append({"x": _rng.randf(), "r": _rng.randf_range(14, 60),
			"speed": _rng.randf_range(0.02, 0.06), "phase": _rng.randf()})
	for i in 45:
		_sparkles.append({"pos": Vector2(_rng.randf(), _rng.randf()),
			"size": _rng.randf_range(6, 18), "phase": _rng.randf() * TAU,
			"speed": _rng.randf_range(1.0, 2.5)})
	for i in 12:
		_leaves.append({"x": _rng.randf(), "speed": _rng.randf_range(0.03, 0.07),
			"phase": _rng.randf(), "size": _rng.randf_range(16, 30),
			"spin": _rng.randf_range(-2.0, 2.0)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	var top := Palette.background_top
	var bottom := Palette.background_bottom
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	match Palette.background_style:
		"candy":
			_draw_bubbles(s)
		"gems":
			_draw_sparkles(s)
		"nature":
			_draw_nature(s)
		_:
			_draw_grid(s)


func _draw_grid(s: Vector2) -> void:
	var horizon := s.y * 0.6
	var cx := s.x * 0.5
	var c := Palette.decor
	for i in range(-14, 15):
		draw_line(Vector2(cx + i * 6.0, horizon), Vector2(cx + i * s.x / 14.0 * 1.6, s.y), c, 2.0)
	var scroll := fmod(_t * 0.15, 1.0)
	for i in 10:
		var k := (i + scroll) / 10.0
		var y := horizon + (s.y - horizon) * k * k
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(c, c.a * k), 2.0)


func _draw_bubbles(s: Vector2) -> void:
	var c := Palette.decor
	for b in _bubbles:
		var k := fmod(_t * b["speed"] + b["phase"], 1.0)
		var r: float = b["r"]
		var pos := Vector2(b["x"] * s.x + sin(_t + b["phase"] * 9.0) * 20.0, s.y + r - k * (s.y + r * 2.0))
		draw_circle(pos, r, c)
		draw_circle(pos + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, c.a * 1.2))


func _draw_sparkles(s: Vector2) -> void:
	var c := Palette.decor
	for sp in _sparkles:
		var a := pow(maxf(0.0, sin(_t * sp["speed"] + sp["phase"])), 3.0)
		if a < 0.02:
			continue
		var p: Vector2 = sp["pos"] * s
		var r: float = sp["size"] * (0.6 + 0.4 * a)
		var col := Color(c, c.a * a)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.2, 0), p + Vector2(0, r), p + Vector2(-r * 0.2, 0)]), col)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(0, -r * 0.2), p + Vector2(r, 0), p + Vector2(0, r * 0.2)]), col)


func _draw_nature(s: Vector2) -> void:
	var far := Palette.decor.lightened(0.25)
	var near := Palette.decor
	_hill(s, s.y * 0.72, 70.0, 0.004, 1.3, far)
	_hill(s, s.y * 0.82, 55.0, 0.006, 0.2, near)
	for leaf in _leaves:
		var k := fmod(_t * leaf["speed"] + leaf["phase"], 1.0)
		var size: float = leaf["size"]
		var pos := Vector2(leaf["x"] * s.x + sin(_t * 1.3 + leaf["phase"] * 7.0) * 40.0, -size + k * (s.y + size * 2.0))
		_leaf(pos, size, _t * leaf["spin"], Color(near.darkened(0.1), 0.8))


func _hill(s: Vector2, base: float, height: float, freq: float, phase: float, color: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, s.y))
	var x := 0.0
	while x <= s.x + 40.0:
		pts.append(Vector2(x, base - sin(x * freq + phase) * height))
		x += 40.0
	pts.append(Vector2(s.x, s.y))
	draw_colored_polygon(pts, color)


func _leaf(pos: Vector2, size: float, angle: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var t := float(i) / 12.0 * TAU
		var p := Vector2(cos(t) * size, sin(t) * size * 0.45)
		pts.append(pos + p.rotated(angle))
	draw_colored_polygon(pts, color)
	draw_line(pos + Vector2(-size, 0).rotated(angle), pos + Vector2(size, 0).rotated(angle), color.darkened(0.3), 2.0)
