class_name Board
extends RefCounted
## The 9x9 grid. Pure logic – no drawing here.
## Each cell holds EMPTY (-1) or a color index (0..7).
## Shapes are arrays of Vector2i(x = column, y = row) offsets.

const SIZE := 9
const EMPTY := -1

var cells: Array[int] = []


func _init() -> void:
	reset()


func reset() -> void:
	cells.resize(SIZE * SIZE)
	cells.fill(EMPTY)


func get_cell(col: int, row: int) -> int:
	return cells[row * SIZE + col]


func set_cell(col: int, row: int, value: int) -> void:
	cells[row * SIZE + col] = value


func is_inside(col: int, row: int) -> bool:
	return col >= 0 and col < SIZE and row >= 0 and row < SIZE


func is_empty() -> bool:
	for v in cells:
		if v != EMPTY:
			return false
	return true


func filled_count() -> int:
	var n := 0
	for v in cells:
		if v != EMPTY:
			n += 1
	return n


func can_place(shape: Array, col: int, row: int) -> bool:
	for p in shape:
		var c: int = col + p.x
		var r: int = row + p.y
		if not is_inside(c, r) or get_cell(c, r) != EMPTY:
			return false
	return true


func place(shape: Array, col: int, row: int, color: int) -> void:
	for p in shape:
		set_cell(col + p.x, row + p.y, color)


func can_fit_anywhere(shape: Array) -> bool:
	for row in SIZE:
		for col in SIZE:
			if can_place(shape, col, row):
				return true
	return false


## Returns {"rows": [...], "cols": [...]} of completely filled lines.
func find_full_lines() -> Dictionary:
	var rows: Array[int] = []
	var cols: Array[int] = []
	for i in SIZE:
		var row_full := true
		var col_full := true
		for j in SIZE:
			if get_cell(j, i) == EMPTY:
				row_full = false
			if get_cell(i, j) == EMPTY:
				col_full = false
		if row_full:
			rows.append(i)
		if col_full:
			cols.append(i)
	return {"rows": rows, "cols": cols}


## Which lines WOULD be completed if this shape was placed (for the preview).
func lines_if_placed(shape: Array, col: int, row: int) -> Dictionary:
	var copy := duplicate_board()
	copy.place(shape, col, row, 0)
	return copy.find_full_lines()


## Empties the given lines. Returns the removed cells as
## [{"pos": Vector2i, "color": int}, ...] (each cell only once).
func clear_lines(lines: Dictionary) -> Array:
	var removed := {}
	for r in lines["rows"]:
		for c in SIZE:
			removed[Vector2i(c, r)] = get_cell(c, r)
	for c in lines["cols"]:
		for r in SIZE:
			removed[Vector2i(c, r)] = get_cell(c, r)
	var result := []
	for pos in removed:
		result.append({"pos": pos, "color": removed[pos]})
		set_cell(pos.x, pos.y, EMPTY)
	return result


func duplicate_board() -> Board:
	var b := Board.new()
	b.cells = cells.duplicate()
	return b
