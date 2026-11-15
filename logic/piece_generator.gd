class_name PieceGenerator
extends RefCounted
## Picks random pieces. Small pieces are more common at the start,
## big pieces become more common as the score (difficulty) goes up.
## A piece is a Dictionary: {"shape": Array[Vector2i], "color": int}

const COLOR_COUNT := 8 # must match Palette.piece_colors.size()

var rng := RandomNumberGenerator.new()


## seed_value >= 0 gives the same pieces every time (used by tests).
func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## How common big pieces (5+ cells) are at the start (difficulty 0).
## Lower = easier start. Was 0.4 before the difficulty was lowered.
const BIG_PIECE_START := 0.25
## How common awkward shapes (diagonals, big corners) are at the start.
## Was 0.35 before the difficulty was lowered.
const AWKWARD_START := 0.25
## Chance that a new tray includes one "helper" piece that can complete
## a line somewhere: high at the start, lower as the game gets harder.
const HELPER_CHANCE_START := 0.4
const HELPER_CHANCE_END := 0.15


## difficulty goes from 0.0 (easy) to 1.0 (hard).
func weight_for(shape: Array, difficulty: float) -> float:
	var n := shape.size()
	var w: float
	if n <= 2:
		w = lerpf(1.2, 0.7, difficulty)
	elif n == 3:
		w = lerpf(1.2, 0.9, difficulty)
	elif n == 4:
		w = 1.0
	else:
		w = lerpf(BIG_PIECE_START, 0.9, difficulty)
	# Awkward shapes (diagonals, big corners) fill little of their box;
	# make them rarer, especially early on.
	var b := Shapes.bounds(shape)
	if float(n) / (b.x * b.y) < 0.6:
		w *= lerpf(AWKWARD_START, 0.7, difficulty)
	return w


func random_shape(difficulty: float) -> Array:
	var shapes := Shapes.all()
	var total := 0.0
	for s in shapes:
		total += weight_for(s, difficulty)
	var pick := rng.randf() * total
	for s in shapes:
		pick -= weight_for(s, difficulty)
		if pick <= 0.0:
			return s
	return shapes[shapes.size() - 1]


func random_piece(difficulty: float) -> Dictionary:
	return {"shape": random_shape(difficulty), "color": rng.randi_range(0, COLOR_COUNT - 1)}


## Makes a new tray of pieces. Prefers a tray where EVERY piece fits
## somewhere on the current board; otherwise one where at least one
## fits; and as a last resort forces one fitting piece in. So the player
## never loses unfairly right after a refill. Sometimes one piece is
## swapped for a helper that can complete a line (see HELPER_CHANCE_*).
func make_tray(board: Board, difficulty: float, count: int = 3) -> Array:
	var tray := _random_tray(board, difficulty, count)
	if rng.randf() < lerpf(HELPER_CHANCE_START, HELPER_CHANCE_END, difficulty):
		var helper := helper_shape(board)
		if not helper.is_empty():
			tray[rng.randi_range(0, count - 1)] = {"shape": helper, "color": rng.randi_range(0, COLOR_COUNT - 1)}
	return tray


## A random shape that completes at least one row or column somewhere on
## the board, or [] if no shape can.
func helper_shape(board: Board) -> Array:
	var row_empty: Array[int] = []
	var col_empty: Array[int] = []
	row_empty.resize(Board.SIZE)
	col_empty.resize(Board.SIZE)
	for r in Board.SIZE:
		for c in Board.SIZE:
			if board.get_cell(c, r) == Board.EMPTY:
				row_empty[r] += 1
				col_empty[c] += 1
	# Try the shapes in random order and stop at the first that works
	# (keeps refills fast on phones).
	var shapes := Shapes.all().duplicate()
	_shuffle(shapes)
	for shape in shapes:
		if _completes_a_line(board, shape, row_empty, col_empty):
			return shape
	return []


func _completes_a_line(board: Board, shape: Array, row_empty: Array[int], col_empty: Array[int]) -> bool:
	# How many cells of the shape sit in each of its rows / columns.
	var b := Shapes.bounds(shape)
	var row_counts: Array[int] = []
	var col_counts: Array[int] = []
	row_counts.resize(b.y)
	col_counts.resize(b.x)
	for p in shape:
		row_counts[p.y] += 1
		col_counts[p.x] += 1
	for row in Board.SIZE - b.y + 1:
		for col in Board.SIZE - b.x + 1:
			# Cheap test first: would some row or column end up full?
			var fills := false
			for dy in b.y:
				if row_empty[row + dy] == row_counts[dy]:
					fills = true
					break
			if not fills:
				for dx in b.x:
					if col_empty[col + dx] == col_counts[dx]:
						fills = true
						break
			if fills and board.can_place(shape, col, row):
				return true
	return false


func _random_tray(board: Board, difficulty: float, count: int) -> Array:
	var fallback := []
	for attempt in 30:
		var candidate := []
		for i in count:
			candidate.append(random_piece(difficulty))
		var fitting := 0
		for piece in candidate:
			if board.can_fit_anywhere(piece["shape"]):
				fitting += 1
		if fitting == count:
			return candidate
		if fitting > 0 and fallback.is_empty():
			fallback = candidate
	if not fallback.is_empty():
		return fallback

	# The board is very full: force one piece that fits.
	var result := []
	for i in count:
		result.append(random_piece(difficulty))
	var shapes := Shapes.all().duplicate()
	_shuffle(shapes)
	for shape in shapes:
		if board.can_fit_anywhere(shape):
			result[0] = {"shape": shape, "color": rng.randi_range(0, COLOR_COUNT - 1)}
			break
	return result


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
