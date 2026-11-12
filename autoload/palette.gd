extends Node
## 🎨 ALL game colors live here. Change them to re-theme the whole game
## (like CSS variables). Keep exactly 8 piece colors.

var background_top := Color("#2A2F6B")
var background_bottom := Color("#12142E")

var board_bg := Color("#1A1D45")
var cell_empty := Color("#2B3070")

var panel := Color("#252A60")
var button := Color("#4C5BD4")
var button_primary := Color("#2FBF71")

var text := Color("#FFFFFF")
var text_dim := Color("#AEB4E8")
var accent := Color("#FFD34D")
var outline := Color("#0D0F26")

## How visible the "shadow" preview of a piece on the board is (0..1).
var ghost_alpha := 0.4

var piece_colors: Array[Color] = [
	Color("#FF5E7E"), # pink
	Color("#FFB84C"), # orange
	Color("#FFE14D"), # yellow
	Color("#5CE1A0"), # green
	Color("#4CC9FF"), # sky
	Color("#7B6CFF"), # violet
	Color("#D16CFF"), # purple
	Color("#FF8A5C"), # coral
]
