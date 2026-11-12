class_name GameState
extends RefCounted
## The whole game in one object: board, tray, score, combo.
## The screen only calls try_place() and draws what is here.

const TRAY_SIZE := 3
## The combo stays alive while you clear at least once every N pieces.
const MOVES_TO_KEEP_COMBO := 3
## Score at which the game reaches full difficulty.
const MAX_DIFFICULTY_SCORE := 4000.0

var board := Board.new()
var generator: PieceGenerator
var tray: Array = [] # each entry: piece Dictionary or null (already used)
var score := 0
var streak := 0
var moves_since_clear := 0
var game_over := false


func _init(seed_value: int = -1) -> void:
	generator = PieceGenerator.new(seed_value)
	new_game()


func new_game() -> void:
	board.reset()
	score = 0
	streak = 0
	moves_since_clear = 0
	game_over = false
	refill_tray()


func difficulty() -> float:
	return clampf(score / MAX_DIFFICULTY_SCORE, 0.0, 1.0)


func refill_tray() -> void:
	tray = generator.make_tray(board, difficulty(), TRAY_SIZE)


func can_place(slot: int, col: int, row: int) -> bool:
	if slot < 0 or slot >= tray.size() or tray[slot] == null:
		return false
	return board.can_place(tray[slot]["shape"], col, row)


func has_any_move() -> bool:
	for piece in tray:
		if piece != null and board.can_fit_anywhere(piece["shape"]):
			return true
	return false


## Snapshot of the game as plain data (for saving to JSON).
func to_dict() -> Dictionary:
	var tray_data := []
	for piece in tray:
		if piece == null:
			tray_data.append(null)
			continue
		var cells := []
		for p in piece["shape"]:
			cells.append([p.x, p.y])
		tray_data.append({"shape": cells, "color": piece["color"]})
	return {
		"cells": Array(board.cells),
		"tray": tray_data,
		"score": score,
		"streak": streak,
		"moves_since_clear": moves_since_clear,
	}


## Restores a snapshot made by to_dict(). Returns false if the data is
## broken (then the state is left as a fresh game).
func from_dict(data: Dictionary) -> bool:
	var cells = data.get("cells")
	var tray_data = data.get("tray")
	if typeof(cells) != TYPE_ARRAY or cells.size() != Board.SIZE * Board.SIZE:
		return false
	if typeof(tray_data) != TYPE_ARRAY or tray_data.size() != TRAY_SIZE:
		return false

	var new_tray := []
	for item in tray_data:
		if item == null:
			new_tray.append(null)
			continue
		if typeof(item) != TYPE_DICTIONARY or typeof(item.get("shape")) != TYPE_ARRAY:
			return false
		var shape: Array[Vector2i] = []
		for pair in item["shape"]:
			shape.append(Vector2i(int(pair[0]), int(pair[1])))
		var color := clampi(int(item.get("color", 0)), 0, PieceGenerator.COLOR_COUNT - 1)
		new_tray.append({"shape": shape, "color": color})

	for i in cells.size():
		board.cells[i] = clampi(int(cells[i]), Board.EMPTY, PieceGenerator.COLOR_COUNT - 1)
	tray = new_tray
	score = int(data.get("score", 0))
	streak = int(data.get("streak", 0))
	moves_since_clear = int(data.get("moves_since_clear", 0))
	if tray.all(func(p): return p == null):
		refill_tray()
	game_over = not has_any_move()
	return true


## Tries to put the piece from tray[slot] at (col, row).
## Returns {"ok": false} or a Dictionary describing what happened.
func try_place(slot: int, col: int, row: int) -> Dictionary:
	if game_over or not can_place(slot, col, row):
		return {"ok": false}

	var piece: Dictionary = tray[slot]
	board.place(piece["shape"], col, row, piece["color"])
	tray[slot] = null

	var lines := board.find_full_lines()
	var line_count: int = lines["rows"].size() + lines["cols"].size()
	var cleared := board.clear_lines(lines)

	if line_count > 0:
		streak += 1
		moves_since_clear = 0
	else:
		moves_since_clear += 1
		if moves_since_clear >= MOVES_TO_KEEP_COMBO:
			streak = 0

	var points := Scoring.place_points(piece["shape"].size())
	points += Scoring.clear_points(cleared.size(), line_count, streak)
	var board_cleared := line_count > 0 and board.is_empty()
	if board_cleared:
		points += Scoring.BOARD_CLEAR_BONUS
	score += points

	var refilled := false
	if tray.all(func(p): return p == null):
		refill_tray()
		refilled = true

	game_over = not has_any_move()

	return {
		"ok": true,
		"piece": piece,
		"col": col,
		"row": row,
		"lines": lines,
		"line_count": line_count,
		"cleared": cleared,
		"points": points,
		"streak": streak,
		"board_cleared": board_cleared,
		"refilled": refilled,
		"game_over": game_over,
	}
