extends Node
## 🎨 The CURRENT theme's colors and style. Every screen reads its colors
## from here. Themes themselves are defined in logic/themes.gd.
## Palette.set_theme("candy") switches theme and saves the choice.

signal theme_changed

var theme_id := ""
var theme_name := ""
var block_style := "neon"
var background_style := "neon"
var glow_ui := true
var solid_buttons := false
var cell_radius := 0.18
var ghost_alpha := 0.45

var background_top := Color.BLACK
var background_bottom := Color.BLACK
var decor := Color.WHITE
var board_bg := Color.BLACK
var board_edge := Color.WHITE
var cell_empty := Color.BLACK
var cell_empty_edge := Color.WHITE
var panel := Color.BLACK
var panel_edge := Color.WHITE
var button := Color.BLUE
var button_primary := Color.GREEN
var text := Color.WHITE
var text_dim := Color.GRAY
var accent := Color.YELLOW
var outline := Color.BLACK
var piece_colors: Array[Color] = []


func _ready() -> void:
	apply(SaveData.theme)


## Switches theme without saving (used at start-up and for previews).
func apply(id: String) -> void:
	if not Themes.DATA.has(id):
		id = Themes.ORDER[0]
	var d: Dictionary = Themes.DATA[id]
	theme_id = id
	theme_name = d["name"]
	block_style = d["block_style"]
	background_style = d["background_style"]
	glow_ui = d["glow_ui"]
	solid_buttons = d["solid_buttons"]
	cell_radius = d["cell_radius"]
	ghost_alpha = d["ghost_alpha"]
	for key in Themes.COLOR_KEYS:
		set(key, Color(d[key]))
	piece_colors.clear()
	for hex in d["piece_colors"]:
		piece_colors.append(Color(hex))
	RenderingServer.set_default_clear_color(background_bottom)
	theme_changed.emit()


## Switches theme and remembers it.
func set_theme(id: String) -> void:
	apply(id)
	SaveData.theme = theme_id
	SaveData.write()


## The current theme's name in the current language.
func display_name() -> String:
	return Lang.t("THEME_" + theme_id.to_upper())


## Next theme (used by the THEME buttons). Ignores a duplicated click.
func cycle_theme() -> void:
	if not UIKit.accept_action():
		return
	set_theme(Themes.next(theme_id))
