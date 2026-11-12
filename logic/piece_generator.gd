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
		w = lerpf(0.4, 0.9, difficulty)
	# Awkward shapes (diagonals, big corners) fill little of their box;
	# make them rarer, especially early on.
	var b := Shapes.bounds(shape)
	if float(n) / (b.x * b.y) < 0.6:
		w *= lerpf(0.35, 0.7, difficulty)
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
## never loses unfairly right after a refill.
func make_tray(board: Board, difficulty: float, count: int = 3) -> Array:
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
