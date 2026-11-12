extends SceneTree
## Difficulty check (not a pass/fail test): the Hint "smart" player
## (logic/hint.gd) plays many games, and
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
			var m := Hint.best_move(gs)
			gs.try_place(m["slot"], m["col"], m["row"])
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
