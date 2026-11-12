class_name GradientBackground
extends Node2D
## Dark neon background: vertical gradient + a faint perspective grid
## at the bottom that slowly scrolls (synthwave style).

const GRID_LINES := 14
const SCROLL_SPEED := 0.15

var _t := 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_t = fmod(_t + delta * SCROLL_SPEED, 1.0)
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	var top := Palette.background_top
	var bottom := Palette.background_bottom
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top, top, bottom, bottom]))

	# Perspective floor grid in the lower 40% of the screen.
	var horizon := s.y * 0.6
	var center_x := s.x * 0.5
	var line_color := Palette.background_grid
	for i in range(-GRID_LINES, GRID_LINES + 1):
		var x_bottom := center_x + i * s.x / GRID_LINES * 1.6
		draw_line(Vector2(center_x + i * 6.0, horizon), Vector2(x_bottom, s.y), line_color, 2.0)
	for i in 10:
		var k := (i + _t) / 10.0
		var y := horizon + (s.y - horizon) * k * k
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(line_color, line_color.a * k), 2.0)
