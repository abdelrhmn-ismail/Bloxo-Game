extends Node
## 🎨 ALL game colors live here (NEON theme). Change them to re-theme the
## whole game, like CSS variables. Keep exactly 8 piece colors.

var background_top := Color("#150A33")
var background_bottom := Color("#04020C")
var background_grid := Color(0.55, 0.3, 1.0, 0.10)

var board_bg := Color("#0A0620")
var board_glow := Color("#7B2CFF")
var cell_empty := Color("#160E36")
var cell_empty_edge := Color("#2A1D5C")

var panel := Color("#0F0828")
var panel_edge := Color("#B026FF")
var button := Color("#3D7BFF")
var button_primary := Color("#39FF88")

var text := Color("#FFFFFF")
var text_dim := Color("#A99CFF")
var accent := Color("#FFE600")
var outline := Color("#04020C")

## How visible the "shadow" preview of a piece on the board is (0..1).
var ghost_alpha := 0.45

var piece_colors: Array[Color] = [
	Color("#FF2E88"), # hot pink
	Color("#FF9F1C"), # orange
	Color("#FFE600"), # yellow
	Color("#39FF88"), # neon green
	Color("#00F0FF"), # cyan
	Color("#3D7BFF"), # electric blue
	Color("#B026FF"), # purple
	Color("#FF3B5C"), # neon red
]
