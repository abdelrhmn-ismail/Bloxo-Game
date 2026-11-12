class_name LogoBlocks
extends Control
## A small decorative block pattern for the menu (placeholder logo).

const PATTERN := [
	"XX.X",
	"X.XX",
	"XXX.",
]
const CELL := 90.0


func _init() -> void:
	custom_minimum_size = Vector2(PATTERN[0].length(), PATTERN.size()) * CELL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var i := 0
	for y in PATTERN.size():
		for x in PATTERN[y].length():
			if PATTERN[y][x] != "X":
				continue
			var bob := sin(t * 2.0 + i * 0.7) * 6.0
			var rect := Rect2(Vector2(x, y) * CELL + Vector2(4, 4 + bob), Vector2(CELL - 8, CELL - 8))
			CellPainter.draw_cell(self, rect, Palette.piece_colors[i % Palette.piece_colors.size()])
			i += 1
