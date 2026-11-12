class_name Themes
extends RefCounted
## All visual themes. Each theme sets the colors, how blocks are drawn
## (block_style) and the animated background (background_style).
## The first theme in ORDER is the default.
##
## To add a theme: copy one entry, give it a new id, add the id to ORDER.
## Colors are hex strings ("#RRGGBB" or "#RRGGBBAA"). Keep 8 piece colors.

const ORDER := ["neon", "candy", "gems", "nature"]

const DATA := {
	"neon": {
		"name": "Neon",
		"block_style": "neon",
		"background_style": "neon",
		"glow_ui": true, # glowing text / borders
		"solid_buttons": false, # false = dark glass buttons with glowing edge
		"cell_radius": 0.18,
		"ghost_alpha": 0.45,
		"background_top": "#150A33",
		"background_bottom": "#04020C",
		"decor": "#8C4DFF1A",
		"board_bg": "#0A0620",
		"board_edge": "#7B2CFF",
		"cell_empty": "#160E36",
		"cell_empty_edge": "#2A1D5C",
		"panel": "#0F0828",
		"panel_edge": "#B026FF",
		"button": "#3D7BFF",
		"button_primary": "#39FF88",
		"text": "#FFFFFF",
		"text_dim": "#A99CFF",
		"accent": "#FFE600",
		"outline": "#04020C",
		"piece_colors": ["#FF2E88", "#FF9F1C", "#FFE600", "#39FF88",
			"#00F0FF", "#3D7BFF", "#B026FF", "#FF3B5C"],
	},
	"candy": {
		"name": "Candy",
		"block_style": "candy",
		"background_style": "candy",
		"glow_ui": false,
		"solid_buttons": true,
		"cell_radius": 0.3,
		"ghost_alpha": 0.4,
		"background_top": "#FFD3E6",
		"background_bottom": "#BFE3FF",
		"decor": "#FFFFFF59",
		"board_bg": "#FFF4F9",
		"board_edge": "#FF8FC1",
		"cell_empty": "#FBE0EC",
		"cell_empty_edge": "#F2C4D8",
		"panel": "#FFF6FB",
		"panel_edge": "#FF7EB6",
		"button": "#8C7CFF",
		"button_primary": "#FF5FA2",
		"text": "#4A2360",
		"text_dim": "#9A6FB0",
		"accent": "#FF4F96",
		"outline": "#FFFFFF",
		"piece_colors": ["#FF6FA8", "#FF9F5A", "#FFD447", "#5FD68A",
			"#4FC3F7", "#8C7CFF", "#C77DFF", "#FF7A7A"],
	},
	"gems": {
		"name": "Gems",
		"block_style": "gems",
		"background_style": "gems",
		"glow_ui": true,
		"solid_buttons": false,
		"cell_radius": 0.06,
		"ghost_alpha": 0.45,
		"background_top": "#0E2347",
		"background_bottom": "#030814",
		"decor": "#CFE8FFCC",
		"board_bg": "#07112A",
		"board_edge": "#4FD1FF",
		"cell_empty": "#0F1E3D",
		"cell_empty_edge": "#1E3566",
		"panel": "#0B1630",
		"panel_edge": "#4FD1FF",
		"button": "#2E86FF",
		"button_primary": "#19D3A2",
		"text": "#FFFFFF",
		"text_dim": "#9FB7E8",
		"accent": "#FFD54A",
		"outline": "#030814",
		"piece_colors": ["#E0115F", "#FF8C1A", "#FFC820", "#10C27A",
			"#19D3D3", "#2E6BFF", "#9B4DFF", "#C8264A"],
	},
	"nature": {
		"name": "Nature",
		"block_style": "nature",
		"background_style": "nature",
		"glow_ui": false,
		"solid_buttons": true,
		"cell_radius": 0.22,
		"ghost_alpha": 0.4,
		"background_top": "#E3F4C9",
		"background_bottom": "#9CCB7E",
		"decor": "#5E9E4E",
		"board_bg": "#7A5235",
		"board_edge": "#5A3A22",
		"cell_empty": "#94694A",
		"cell_empty_edge": "#7C5638",
		"panel": "#F6ECD6",
		"panel_edge": "#8A5E3B",
		"button": "#5E9E4E",
		"button_primary": "#E58B2E",
		"text": "#3E2A1A",
		"text_dim": "#7A6048",
		"accent": "#C2621B",
		"outline": "#FFF8E8",
		"piece_colors": ["#6DBE45", "#3E9A5A", "#F2C14E", "#E8833A",
			"#C9485B", "#5BB4D9", "#8E7CC3", "#B5793F"],
	},
}

## Color fields every theme must define (used by Palette and the tests).
const COLOR_KEYS := ["background_top", "background_bottom", "decor", "board_bg",
	"board_edge", "cell_empty", "cell_empty_edge", "panel", "panel_edge", "button",
	"button_primary", "text", "text_dim", "accent", "outline"]


static func next(id: String) -> String:
	var i := ORDER.find(id)
	return ORDER[(i + 1) % ORDER.size()]
