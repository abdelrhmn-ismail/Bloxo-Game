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
	check(not b.can_place(square, 7, 0), "square does not fit past right edge")
	check(not b.can_place(square, 0, 7), "square does not fit past bottom edge")
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
	check(removed.size() == 15, "row + column = 15 unique cells (got %d)" % removed.size())
	check(b.is_empty(), "board empty after clear")


func test_cross_clear_counts_cells_once() -> void:
	var b := Board.new()
	fill_row(b, 0)
	fill_row(b, 1)
	var removed := b.clear_lines(b.find_full_lines())
	check(removed.size() == 16, "two rows = 16 cells")


func test_lines_preview_does_not_change_board() -> void:
	var b := Board.new()
	fill_row(b, 3, 7)
	var dot := Shapes.parse("X")
	var preview := b.lines_if_placed(dot, 7, 3)
	check(preview["rows"] == [3], "preview finds the row")
	check(b.get_cell(7, 3) == Board.EMPTY, "preview did not modify board")


func test_scoring() -> void:
	check(Scoring.clear_points(0, 0, 0) == 0, "no lines no points")
	check(Scoring.clear_points(8, 1, 1) == 80, "one line = 80")
	check(Scoring.clear_points(16, 2, 1) == 320, "two lines = 16*10*2")
	check(Scoring.clear_points(8, 1, 3) == 160, "combo x3 doubles")
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
		if "%d" in Strings.TEXT[key]["en"]:
			for lang in Strings.LANGS:
				check("%d" in Strings.TEXT[key][lang], "%s keeps %%d in %s" % [key, lang])
	# Every theme name and praise word used by the game has a text.
	for id in Themes.ORDER:
		check(Strings.TEXT.has("THEME_" + id.to_upper()), "theme %s has a translated name" % id)
	for n in [2, 3, 4]:
		check(Strings.TEXT.has(Scoring.praise_word(n)), "praise word for %d lines is translated" % n)
	check(Strings.from_locale("fr_CA") == "fr", "French phone -> French")
	check(Strings.from_locale("ar_EG") == "ar", "Arabic phone -> Arabic")
	check(Strings.from_locale("ja_JP") == "en", "unsupported language -> English")
	check(Strings.next("ar") == "en", "language list wraps around")


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
