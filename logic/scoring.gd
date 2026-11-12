class_name Scoring
extends RefCounted
## All point rules in one place. Tweak the numbers to change the feel.

const LINE_CELL_POINTS := 10
const BOARD_CLEAR_BONUS := 300


## Points for just putting a piece down.
static func place_points(cell_count: int) -> int:
	return cell_count


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
