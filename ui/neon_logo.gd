class_name NeonLogo
extends Control
## The BLOXO logo, built from neon blocks (5x5 pixel letters).
## `reveal` (0..1) makes the blocks pop in one after another.
## The same letters are used by tools/make_logo.py for the PNG logo/icon.

const LETTERS := {
	"B": ["XXXX.", "X...X", "XXXX.", "X...X", "XXXX."],
	"L": ["X....", "X....", "X....", "X....", "XXXXX"],
	"O": [".XXX.", "X...X", "X...X", "X...X", ".XXX."],
	"X": ["X...X", ".X.X.", "..X..", ".X.X.", "X...X"],
}
const WORD := "BLOXO"
const LETTER_COLORS := [0, 4, 2, 3, 6] # indexes into Palette.piece_colors

var cell := 32.0
var reveal := 1.0
var _cells: Array = [] # [{"pos": Vector2, "color": int, "order": float}]


func _init(cell_size: float = 32.0) -> void:
	cell = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := 0
	for li in WORD.length():
		var rows: Array = LETTERS[WORD[li]]
		for y in rows.size():
			for x in rows[y].length():
				if rows[y][x] == "X":
					_cells.append({
						"pos": Vector2(col + x, y),
						"color": LETTER_COLORS[li],
						"order": float(col + x) / (WORD.length() * 6.0),
					})
		col += 6
	custom_minimum_size = Vector2(WORD.length() * 6 - 1, 5) * cell


## Plays the pop-in animation.
func play_intro(duration: float = 0.9) -> void:
	reveal = 0.0
	create_tween().tween_property(self, "reveal", 1.0, duration)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var gap := cell * 0.12
	for c in _cells:
		var k := clampf((reveal - c["order"] * 0.7) / 0.3, 0.0, 1.0)
		if k <= 0.0:
			continue
		var pop := 1.0 + 0.25 * sin(k * PI)
		var side := (cell - gap) * k * pop
		var center: Vector2 = (c["pos"] + Vector2(0.5, 0.5)) * cell
		center.y += sin(t * 2.2 + c["pos"].x * 0.35) * cell * 0.06
		var color: Color = Palette.piece_colors[c["color"]]
		var glow := 0.85 + 0.15 * sin(t * 3.0 + c["pos"].x * 0.2)
		CellPainter.draw_cell(self, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)),
			color.lightened(0.1 * glow), k)
