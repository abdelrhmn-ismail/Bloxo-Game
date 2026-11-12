extends SceneTree
## Difficulty check (not a pass/fail test): a simple "smart" player that
## prefers clearing lines and avoids leaving holes plays many games, and
## we print how long games last and the scores reached.
##   godot --headless --path . -s tests/balance_check.gd

const GAMES := 60
const MAX_MOVES := 600


func _init() -> void:
	var lengths: Array[int] = []
	var scores: Array[int] = []
	var capped := 0
	for g in GAMES:
		var gs := GameState.new(1000 + g)
		var moves := 0
		while not gs.game_over and moves < MAX_MOVES:
			var best_move := []
			var best_value := -INF
			for slot in gs.tray.size():
				if gs.tray[slot] == null:
					continue
				var shape: Array = gs.tray[slot]["shape"]
				for row in Board.SIZE:
					for col in Board.SIZE:
						if gs.board.can_place(shape, col, row):
							var v := _value(gs.board, shape, col, row)
							if v > best_value:
								best_value = v
								best_move = [slot, col, row]
			gs.try_place(best_move[0], best_move[1], best_move[2])
			moves += 1
		if moves >= MAX_MOVES:
			capped += 1
		if moves <= 8 and OS.get_cmdline_user_args().has("--debug-short"):
			_dump(gs, 1000 + g, moves)
		lengths.append(moves)
		scores.append(gs.score)
	lengths.sort()
	scores.sort()
	print("smart player, %d games:" % GAMES)
	print("  moves per game: min %d, median %d, max %d (%d games hit the %d-move cap)" % [
		lengths[0], lengths[GAMES / 2], lengths[-1], capped, MAX_MOVES])
	print("  score: min %d, median %d, max %d" % [scores[0], scores[GAMES / 2], scores[-1]])
	quit()


func _dump(gs: GameState, seed_value: int, moves: int) -> void:
	print("--- short game seed %d after %d moves, score %d" % [seed_value, moves, gs.score])
	for r in Board.SIZE:
		var line := ""
		for c in Board.SIZE:
			line += "#" if gs.board.get_cell(c, r) != Board.EMPTY else "."
		print("    " + line)
	for p in gs.tray:
		if p != null:
			var b := Shapes.bounds(p["shape"])
			var rows := []
			for y in b.y:
				var line := ""
				for x in b.x:
					line += "X" if p["shape"].has(Vector2i(x, y)) else "."
				rows.append(line)
			print("  piece: " + " / ".join(rows))


## Higher is better: lines cleared, few isolated holes, touching neighbours.
func _value(board: Board, shape: Array, col: int, row: int) -> float:
	# Contact: edges of the new piece touching walls or existing blocks
	# (real players stack pieces together instead of scattering them).
	var contact := 0
	for p in shape:
		var cell: Vector2i = Vector2i(col, row) + p
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cell + d
			if shape.has(n - Vector2i(col, row)):
				continue
			if not board.is_inside(n.x, n.y) or board.get_cell(n.x, n.y) != Board.EMPTY:
				contact += 1
	var b := board.duplicate_board()
	b.place(shape, col, row, 0)
	var lines := b.find_full_lines()
	var cleared: int = lines["rows"].size() + lines["cols"].size()
	b.clear_lines(lines)
	var holes := 0
	for r in Board.SIZE:
		for c in Board.SIZE:
			if b.get_cell(c, r) != Board.EMPTY:
				continue
			var blocked := 0
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(c, r) + d
				if not b.is_inside(n.x, n.y) or b.get_cell(n.x, n.y) != Board.EMPTY:
					blocked += 1
			if blocked >= 3:
				holes += 1
	return cleared * 100.0 - holes * 25.0 - b.filled_count() * 2.0 + contact * 6.0
