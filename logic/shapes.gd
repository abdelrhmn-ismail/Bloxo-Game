class_name Shapes
extends RefCounted
## All piece shapes, drawn as text: X = filled cell, . = empty.
## Rows are separated by \n. Add, remove or edit shapes freely.

const PATTERNS := [
	# single + lines
	"X",
	"XX", "X\nX",
	"XXX", "X\nX\nX",
	"XXXX", "X\nX\nX\nX",
	"XXXXX", "X\nX\nX\nX\nX",
	# squares / rectangles
	"XX\nXX",
	"XXX\nXXX\nXXX",
	"XX\nXX\nXX", "XXX\nXXX",
	# small corners (3 cells)
	"XX\nX.", "XX\n.X", "X.\nXX", ".X\nXX",
	# L and J (4 cells)
	"X.\nX.\nXX", "XXX\nX..", "XX\n.X\n.X", "..X\nXXX",
	".X\n.X\nXX", "X..\nXXX", "XX\nX.\nX.", "XXX\n..X",
	# big corners (5 cells)
	"X..\nX..\nXXX", "XXX\nX..\nX..", "XXX\n..X\n..X", "..X\n..X\nXXX",
	# T
	"XXX\n.X.", ".X\nXX\n.X", ".X.\nXXX", "X.\nXX\nX.",
	# S / Z
	".XX\nXX.", "X.\nXX\n.X", "XX.\n.XX", ".X\nXX\nX.",
	# diagonals
	"X.\n.X", ".X\nX.",
]

static var _cache: Array = []


static func all() -> Array:
	if _cache.is_empty():
		for pattern in PATTERNS:
			_cache.append(parse(pattern))
	return _cache


static func parse(pattern: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var rows := pattern.split("\n")
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			if line[x] == "X":
				cells.append(Vector2i(x, y))
	return cells


## Width and height of a shape in cells.
static func bounds(shape: Array) -> Vector2i:
	var w := 0
	var h := 0
	for p in shape:
		w = maxi(w, p.x + 1)
		h = maxi(h, p.y + 1)
	return Vector2i(w, h)
