class_name Hint
extends RefCounted
## Finds a good move for the current tray: used by the in-game hint and
## by tests/balance_check.gd. Prefers clearing lines, placing pieces next
## to walls/other blocks, and not leaving isolated holes.


## Returns {"slot": int, "col": int, "row": int} or {} if nothing fits.
static func best_move(state: GameState) -> Dictionary:
	var best := {}
	var best_value := -INF
	for slot in state.tray.size():
		if state.tray[slot] == null:
			continue
		var shape: Array = state.tray[slot]["shape"]
		for row in Board.SIZE:
			for col in Board.SIZE:
				if state.board.can_place(shape, col, row):
					var v := value(state.board, shape, col, row)
					if v > best_value:
						best_value = v
						best = {"slot": slot, "col": col, "row": row}
	return best


## Higher is better.
static func value(board: Board, shape: Array, col: int, row: int) -> float:
	var origin := Vector2i(col, row)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	# Contact: edges of the piece touching walls or existing blocks.
	var contact := 0
	for p in shape:
		var cell: Vector2i = origin + p
		for d in dirs:
			var nb: Vector2i = cell + d
			if shape.has(nb - origin):
				continue
			if not board.is_inside(nb.x, nb.y) or board.get_cell(nb.x, nb.y) != Board.EMPTY:
				contact += 1
	var b := board.duplicate_board()
	b.place(shape, col, row, 0)
	var lines := b.find_full_lines()
	var cleared: int = lines["rows"].size() + lines["cols"].size()
	b.clear_lines(lines)
	# Holes: empty cells boxed in on 3+ sides.
	var holes := 0
	for r in Board.SIZE:
		for c in Board.SIZE:
			if b.get_cell(c, r) != Board.EMPTY:
				continue
			var blocked := 0
			for d in dirs:
				var nb: Vector2i = Vector2i(c, r) + d
				if not b.is_inside(nb.x, nb.y) or b.get_cell(nb.x, nb.y) != Board.EMPTY:
					blocked += 1
			if blocked >= 3:
				holes += 1
	return cleared * 100.0 - holes * 25.0 - b.filled_count() * 2.0 + contact * 6.0
