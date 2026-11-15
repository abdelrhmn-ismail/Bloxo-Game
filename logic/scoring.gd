class_name Scoring
extends RefCounted
## All point rules in one place. Tweak the numbers to change the feel.

## Points are about 30% lower than the first version (same rules):
## a full 9-cell line gives 63 (was 80 on the 8x8 board).
const LINE_CELL_POINTS := 7
const BOARD_CLEAR_BONUS := 210
## Placing a piece gives 70% of its cell count (rounded, at least 1).
const PLACE_POINTS_FACTOR := 0.7


## Points for just putting a piece down.
static func place_points(cell_count: int) -> int:
	if cell_count <= 0:
		return 0
	return maxi(1, roundi(cell_count * PLACE_POINTS_FACTOR))


## Points for clearing lines. streak = how many clears in a row (1 = first).
static func clear_points(cleared_cells: int, line_count: int, streak: int) -> int:
	if line_count <= 0:
		return 0
	var points := cleared_cells * LINE_CELL_POINTS * line_count
	if streak >= 2:
		points += int(points * (streak - 1) * 0.5)
	return points


## Text key (see logic/strings.gd) of the word shown after a clear
## ("" = no word).
static func praise_word(line_count: int) -> String:
	match line_count:
		0, 1:
			return ""
		2:
			return "GREAT"
		3:
			return "EXCELLENT"
		_:
			return "AMAZING"
