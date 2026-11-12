class_name ClearEffect
extends Node2D
## One cleared cell: it pops, shrinks away and throws little sparks.

const DURATION := 0.45
const GRAVITY := Vector2(0, 1400)

var rect: Rect2
var color: Color
var delay := 0.0
var t := 0.0
var sparks: Array = []


func setup(cell_rect: Rect2, cell_color: Color, start_delay: float) -> void:
	rect = cell_rect
	color = cell_color
	delay = start_delay
	for i in 4:
		sparks.append({
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(250.0, 520.0) + Vector2(0, -250),
			"size": randf_range(rect.size.x * 0.1, rect.size.x * 0.2),
		})


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
	else:
		t += delta / DURATION
		if t >= 1.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if delay > 0.0:
		CellPainter.draw_cell(self, rect, color.lightened(0.25))
		return
	var grow := 1.0 + 0.3 * sin(t * PI)
	var cell_size := rect.size * maxf(0.0, 1.0 - t) * grow
	var r := Rect2(rect.get_center() - cell_size * 0.5, cell_size)
	CellPainter.draw_cell(self, r, color.lightened(0.4 * (1.0 - t)), 1.0 - t * 0.4)

	var time := t * DURATION
	for spark in sparks:
		var p: Vector2 = rect.get_center() + spark["vel"] * time + GRAVITY * time * time * 0.5
		var s: float = spark["size"] * (1.0 - t)
		draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), Color(color.lightened(0.2), 1.0 - t))
