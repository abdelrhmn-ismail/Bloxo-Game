extends SceneTree
## Tests for the game rules (no graphics needed). Run from the project folder:
##   godot --headless --path . -s tests/test_runner.gd

var passed := 0
var failed := 0


func _init() -> void:
	test_shapes_parse()
	test_place_and_bounds()
	test_row_and_column_clear()
	test_cross_clear_counts_cells_once()
	test_lines_preview_does_not_change_board()
	test_scoring()
	test_game_state_place_and_refill()
	test_combo_resets_after_three_moves()
	test_game_over_detection()
	test_tray_always_has_a_fitting_piece()
	test_save_and_restore_game()
	test_restore_rejects_broken_data()
	test_themes_are_complete()
	test_translations_are_complete()
	test_restore_rejects_broken_shapes()
	test_random_games_keep_rules()
	test_rewards()
	test_powerups_on_state()
	test_snapshot_is_a_copy()
	test_old_8x8_save_is_migrated()
	test_helper_piece_completes_a_line()
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)


func fill_row(board: Board, row: int, except_col: int = -1) -> void:
	for c in Board.SIZE:
		if c != except_col:
			board.set_cell(c, row, 0)


# ---------------------------------------------------------------------

func test_shapes_parse() -> void:
	var l := Shapes.parse("X.\nX.\nXX")
	check(l == [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], "parse L shape")
	check(Shapes.bounds(l) == Vector2i(2, 3), "bounds of L shape")
	for s in Shapes.all():
		check(s.size() > 0, "every shape has cells")


func test_place_and_bounds() -> void:
	var b := Board.new()
	var square := Shapes.parse("XX\nXX")
	check(b.can_place(square, 0, 0), "square fits at corner")
	check(not b.can_place(square, Board.SIZE - 1, 0), "square does not fit past right edge")
	check(not b.can_place(square, 0, Board.SIZE - 1), "square does not fit past bottom edge")
	check(not b.can_place(square, -1, 0), "negative column is outside")
	b.place(square, 3, 3, 2)
	check(b.get_cell(4, 4) == 2, "placed cell has color")
	check(not b.can_place(square, 4, 4), "cannot overlap")
	check(b.filled_count() == 4, "4 cells filled")


func test_row_and_column_clear() -> void:
	var b := Board.new()
	fill_row(b, 5)
	for r in Board.SIZE:
		b.set_cell(2, r, 1)
	var lines := b.find_full_lines()
	check(lines["rows"] == [5], "row 5 full")
	check(lines["cols"] == [2], "column 2 full")
	var removed := b.clear_lines(lines)
	check(removed.size() == Board.SIZE * 2 - 1, "row + column cells counted once (got %d)" % removed.size())
	check(b.is_empty(), "board empty after clear")


func test_cross_clear_counts_cells_once() -> void:
	var b := Board.new()
	fill_row(b, 0)
	fill_row(b, 1)
	var removed := b.clear_lines(b.find_full_lines())
	check(removed.size() == Board.SIZE * 2, "two rows = 2 x SIZE cells")


func test_lines_preview_does_not_change_board() -> void:
	var b := Board.new()
	var last := Board.SIZE - 1
	fill_row(b, 3, last)
	var dot := Shapes.parse("X")
	var preview := b.lines_if_placed(dot, last, 3)
	check(preview["rows"] == [3], "preview finds the row")
	check(b.get_cell(last, 3) == Board.EMPTY, "preview did not modify board")


func test_scoring() -> void:
	check(Scoring.clear_points(0, 0, 0) == 0, "no lines no points")
	check(Board.SIZE == 9, "board is 9x9")
	check(Scoring.clear_points(9, 1, 1) == 63, "one 9-cell line = 63")
	check(Scoring.clear_points(17, 2, 1) == 238, "row + column = 17*7*2")
	check(Scoring.clear_points(9, 1, 3) == 126, "combo x3 doubles")
	check(Scoring.place_points(0) == 0, "no cells no place points")
	check(Scoring.place_points(1) == 1, "single cell still gives 1 point")
	check(Scoring.place_points(4) == 3, "4 cells = 3 points (70%)")
	check(Scoring.place_points(9) == 6, "9 cells = 6 points (70%)")
	check(Scoring.praise_word(1) == "", "no word for 1 line")
	check(Scoring.praise_word(5) == "AMAZING", "word for 5 lines")


func test_game_state_place_and_refill() -> void:
	var gs := GameState.new(42)
	check(gs.tray.size() == 3, "tray has 3 pieces")
	# Find a valid spot for each piece and place all three.
	for slot in 3:
		var shape: Array = gs.tray[slot]["shape"]
		var placed := false
		for row in Board.SIZE:
			for col in Board.SIZE:
				if not placed and gs.board.can_place(shape, col, row):
					var r := gs.try_place(slot, col, row)
					check(r["ok"], "placement ok")
					placed = true
	check(gs.tray.all(func(p): return p != null), "tray refilled after 3 placements")
	check(gs.score > 0, "score increased")
	check(not gs.try_place(0, 99, 99)["ok"], "invalid placement rejected")


func test_combo_resets_after_three_moves() -> void:
	var gs := GameState.new(1)
	var dot := Shapes.parse("X")
	# Clear a row with a dot -> streak 1
	fill_row(gs.board, 0, 0)
	gs.tray = [{"shape": dot, "color": 0}, {"shape": dot, "color": 0}, {"shape": dot, "color": 0}]
	var r := gs.try_place(0, 0, 0)
	check(r["line_count"] == 1 and r["streak"] == 1, "first clear: streak 1")
	# Clear again -> streak 2
	fill_row(gs.board, 1, 0)
	r = gs.try_place(1, 0, 1)
	check(r["streak"] == 2, "second clear in a row: streak 2")
	# Three placements without clearing -> streak back to 0
	gs.try_place(2, 5, 5)
	gs.tray = [{"shape": dot, "color": 0}, {"shape": dot, "color": 0}, {"shape": dot, "color": 0}]
	gs.try_place(0, 5, 6)
	r = gs.try_place(1, 5, 7)
	check(r["streak"] == 0, "combo reset after 3 moves without clear (got %d)" % r["streak"])


func test_game_over_detection() -> void:
	var gs := GameState.new(7)
	# Checkerboard: no 2 cells touch, so only single dots could fit.
	for row in Board.SIZE:
		for col in Board.SIZE:
			if (row + col) % 2 == 0:
				gs.board.set_cell(col, row, 0)
	var line2 := Shapes.parse("XX")
	var dot := Shapes.parse("X")
	gs.tray = [{"shape": dot, "color": 0}, {"shape": line2, "color": 0}, null]
	check(gs.has_any_move(), "dot still fits")
	var r := gs.try_place(0, 1, 0)
	check(r["ok"], "dot placed")
	check(r["game_over"], "game over: the 2-long piece cannot fit")


func test_save_and_restore_game() -> void:
	var gs := GameState.new(99)
	gs.board.place(Shapes.parse("XX\nXX"), 2, 3, 5)
	gs.score = 1234
	gs.streak = 2
	gs.tray[1] = null
	# Go through JSON like the real save file does.
	var data = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var loaded := GameState.new(1)
	check(loaded.from_dict(data), "restore succeeds")
	check(loaded.board.cells == gs.board.cells, "board restored")
	check(loaded.score == 1234 and loaded.streak == 2, "score and streak restored")
	check(loaded.tray[1] == null, "used tray slot stays empty")
	check(loaded.tray[0]["shape"] == gs.tray[0]["shape"], "tray shape restored")
	check(loaded.tray[0]["color"] == gs.tray[0]["color"], "tray color restored")


func test_restore_rejects_broken_data() -> void:
	var gs := GameState.new(5)
	var before := gs.board.cells.duplicate()
	check(not gs.from_dict({}), "empty data rejected")
	check(not gs.from_dict({"cells": [1, 2], "tray": [null, null, null]}), "short board rejected")
	check(gs.board.cells == before, "board untouched after rejected restore")


func test_themes_are_complete() -> void:
	check(Themes.ORDER[0] == "neon", "neon is the default theme")
	for id in Themes.ORDER:
		check(Themes.DATA.has(id), "theme %s has data" % id)
		var d: Dictionary = Themes.DATA[id]
		for key in Themes.COLOR_KEYS:
			check(d.has(key) and Color.html_is_valid(d[key]), "theme %s has valid %s" % [id, key])
		check(d["piece_colors"].size() == PieceGenerator.COLOR_COUNT, "theme %s has 8 piece colors" % id)
		for hex in d["piece_colors"]:
			check(Color.html_is_valid(hex), "theme %s piece color %s valid" % [id, hex])
		for key in ["name", "block_style", "background_style", "glow_ui", "solid_buttons", "cell_radius", "ghost_alpha"]:
			check(d.has(key), "theme %s has %s" % [id, key])
	check(Themes.next("neon") == "candy", "next theme after neon")
	check(Themes.next("nature") == "neon", "theme list wraps around")


func test_translations_are_complete() -> void:
	check(Strings.LANGS == ["en", "fr", "de", "es", "it", "ar"], "six languages")
	for lang in Strings.LANGS:
		check(Strings.NAMES.has(lang), "language %s has a name" % lang)
	for key in Strings.TEXT:
		for lang in Strings.LANGS:
			var text = Strings.TEXT[key].get(lang)
			check(text is String and text != "", "%s translated to %s" % [key, lang])
		# Texts with a number placeholder must keep it in every language.
		for ph in ["%d", "%s"]:
			if ph in Strings.TEXT[key]["en"]:
				for lang in Strings.LANGS:
					check(ph in Strings.TEXT[key][lang], "%s keeps %s in %s" % [key, ph, lang])
	# Every theme name and praise word used by the game has a text.
	for id in Themes.ORDER:
		check(Strings.TEXT.has("THEME_" + id.to_upper()), "theme %s has a translated name" % id)
	for n in [2, 3, 4]:
		check(Strings.TEXT.has(Scoring.praise_word(n)), "praise word for %d lines is translated" % n)
	check(Strings.from_locale("fr_CA") == "fr", "French phone -> French")
	check(Strings.from_locale("ar_EG") == "ar", "Arabic phone -> Arabic")
	check(Strings.from_locale("ja_JP") == "en", "unsupported language -> English")
	check(Strings.next("ar") == "en", "language list wraps around")


func test_restore_rejects_broken_shapes() -> void:
	var good := GameState.new(3).to_dict()
	var cases := {
		"empty shape": [],
		"not a pair": [5],
		"pair too short": [[1]],
		"negative cell": [[-1, 0]],
		"cell too far": [[0, 99]],
	}
	for name in cases:
		var data: Dictionary = good.duplicate(true)
		data["tray"][0] = {"shape": cases[name], "color": 1}
		check(not GameState.new(3).from_dict(data), "save with %s is rejected" % name)


## Plays many full games with random legal moves and checks the rules
## after every move (no crash, no full line left behind, score never
## goes down, game over exactly when nothing fits, fair refills).
func test_random_games_keep_rules() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var games := 300
	var total_moves := 0
	var best := 0
	var problems := 0
	for g in games:
		var gs := GameState.new(g)
		var guard := 0
		while not gs.game_over and guard < 2000:
			guard += 1
			var options := []
			for slot in gs.tray.size():
				if gs.tray[slot] == null:
					continue
				for row in Board.SIZE:
					for col in Board.SIZE:
						if gs.board.can_place(gs.tray[slot]["shape"], col, row):
							options.append([slot, col, row])
			if options.is_empty():
				problems += 1 # game_over should already be true
				break
			var pick: Array = options[rng.randi_range(0, options.size() - 1)]
			var score_before := gs.score
			var size: int = gs.tray[pick[0]]["shape"].size()
			var r := gs.try_place(pick[0], pick[1], pick[2])
			total_moves += 1
			if not r["ok"]:
				problems += 1
				break
			var lines := gs.board.find_full_lines()
			if lines["rows"].size() + lines["cols"].size() > 0:
				problems += 1 # a full line was left on the board
			if gs.score < score_before + Scoring.place_points(size):
				problems += 1
			if gs.game_over != (not gs.has_any_move()):
				problems += 1
			if r["refilled"] and not gs.game_over:
				var fits := false
				for p in gs.tray:
					if gs.board.can_fit_anywhere(p["shape"]):
						fits = true
				if not fits:
					problems += 1
			for v in gs.board.cells:
				if v < Board.EMPTY or v >= PieceGenerator.COLOR_COUNT:
					problems += 1
					break
		if guard >= 2000:
			problems += 1 # game never ended
		best = maxi(best, gs.score)
	print("random games: %d games, %d moves, best score %d, avg %.1f moves/game" % [
		games, total_moves, best, float(total_moves) / games])
	check(problems == 0, "random games kept every rule (%d problems)" % problems)


func test_rewards() -> void:
	check(Rewards.daily_available("", "2026-11-12"), "first daily gift is available")
	check(not Rewards.daily_available("2026-11-12", "2026-11-12"), "daily gift only once a day")
	check(Rewards.daily_available("2026-11-12", "2026-11-13"), "daily gift again the next day")
	check(Rewards.hourly_seconds_left(0.0, 1000.0) == 0, "first hourly gift is ready")
	check(Rewards.hourly_seconds_left(1000.0, 1000.0) == 3600, "just claimed: wait an hour")
	check(Rewards.hourly_seconds_left(1000.0, 4600.0) == 0, "ready again after an hour")
	check(Rewards.hourly_seconds_left(5000.0, 1000.0) == 0, "clock went back: not stuck")
	var inv := {"hammer": 8}
	check(Rewards.add(inv, "hammer", 5) == Rewards.MAX_EACH, "power-ups are capped")
	check(Rewards.add(inv, "bomb", 1) == 1, "missing kind starts at 0")
	check(Rewards.format_time(125) == "2:05", "countdown format")
	check(Rewards.bomb_area(Vector2i(3, 3)).size() == 9, "bomb hits 3x3")
	check(Rewards.bomb_area(Vector2i(0, 0)).size() == 4, "bomb is clipped at the corner")
	for kind in Rewards.KINDS:
		check(Strings.TEXT.has("POWER_" + kind.to_upper()), "power-up %s has a translated name" % kind)


func test_powerups_on_state() -> void:
	var gs := GameState.new(21)
	gs.board.place(Shapes.parse("XXX"), 2, 2, 3)
	var removed := gs.remove_cells([Vector2i(3, 2), Vector2i(7, 7)])
	check(removed.size() == 1 and gs.board.get_cell(3, 2) == Board.EMPTY, "hammer removes one filled cell")
	check(gs.board.filled_count() == 2, "other cells stay")
	# Left: (2,2) and (4,2). A bomb centred on (3,2) covers both.
	removed = gs.remove_cells(Rewards.bomb_area(Vector2i(3, 2)))
	check(removed.size() == 2 and gs.board.is_empty(), "bomb clears the filled cells in its area")
	var score := gs.score
	gs.tray = [null, null, {"shape": Shapes.parse("X"), "color": 0}]
	gs.shuffle_tray()
	check(gs.tray.all(func(p): return p != null), "shuffle gives three new pieces")
	check(gs.score == score, "power-ups give no points")


## Undo relies on to_dict() being a real copy: later moves must not change it.
func test_snapshot_is_a_copy() -> void:
	var gs := GameState.new(8)
	var snap := gs.to_dict()
	gs.board.set_cell(0, 0, 3)
	gs.score = 999
	check(int(snap["cells"][0]) == Board.EMPTY, "snapshot board is not changed by later moves")
	check(int(snap["score"]) == 0, "snapshot score is not changed by later moves")


func test_tray_always_has_a_fitting_piece() -> void:
	var gen := PieceGenerator.new(123)
	var b := Board.new()
	# Board full except one single cell.
	for i in b.cells.size():
		b.cells[i] = 0
	b.set_cell(4, 4, Board.EMPTY)
	for n in 20:
		var tray := gen.make_tray(b, 1.0)
		var ok := false
		for p in tray:
			if b.can_fit_anywhere(p["shape"]):
				ok = true
		check(ok, "tray has a piece that fits a single hole")


func test_old_8x8_save_is_migrated() -> void:
	# A game saved before the board grew to 9x9 (64 cells).
	var old_cells := []
	old_cells.resize(64)
	old_cells.fill(Board.EMPTY)
	old_cells[0] = 3 # top-left
	old_cells[7] = 4 # top-right of the old board
	old_cells[63] = 5 # bottom-right of the old board
	var data := GameState.new(11).to_dict()
	data["cells"] = old_cells
	var gs := GameState.new(12)
	check(gs.from_dict(data), "old 8x8 save loads")
	check(gs.board.cells.size() == Board.SIZE * Board.SIZE, "migrated board has the new size")
	check(gs.board.get_cell(0, 0) == 3 and gs.board.get_cell(7, 0) == 4 and gs.board.get_cell(7, 7) == 5,
		"old blocks keep their place")
	check(gs.board.get_cell(8, 0) == Board.EMPTY and gs.board.get_cell(0, 8) == Board.EMPTY,
		"new column and row start empty")
	check(gs.board.filled_count() == 3, "no extra blocks appear")
	var odd := data.duplicate()
	odd["cells"] = [1, 2, 3]
	check(not GameState.new(13).from_dict(odd), "non-square board still rejected")


## The helper piece must really complete a line, and must only be missing
## when no shape at all can (checked against a slow brute force).
func test_helper_piece_completes_a_line() -> void:
	var gen := PieceGenerator.new(21)
	check(gen.helper_shape(Board.new()).is_empty(), "empty board: no shape can fill a 9-cell line")
	var b := Board.new()
	fill_row(b, 4, 6)
	var help := gen.helper_shape(b)
	check(not help.is_empty() and _any_clear(b, help), "one gap in a row: helper fills it")

	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var wrong := 0
	for i in 150:
		var board := Board.new()
		var density := rng.randf_range(0.3, 0.85)
		for idx in board.cells.size():
			if rng.randf() < density:
				board.cells[idx] = 0
		# A full line can't stay on a real board.
		board.clear_lines(board.find_full_lines())
		var shape := gen.helper_shape(board)
		if shape.is_empty():
			for s in Shapes.all():
				if _any_clear(board, s):
					wrong += 1
					break
		elif not _any_clear(board, shape):
			wrong += 1
	check(wrong == 0, "helper piece matches brute force on random boards (%d wrong)" % wrong)


func _any_clear(board: Board, shape: Array) -> bool:
	for row in Board.SIZE:
		for col in Board.SIZE:
			if board.can_place(shape, col, row):
				var lines := board.lines_if_placed(shape, col, row)
				if lines["rows"].size() + lines["cols"].size() > 0:
					return true
	return false
