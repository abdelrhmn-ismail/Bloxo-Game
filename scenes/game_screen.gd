class_name GameScreen
extends Node2D
## The play screen: draws the board + tray, handles dragging with the
## finger, and plays the effects. The rules live in GameState.

signal exit_to_menu

## How high above the finger the dragged piece floats (in cells).
const LIFT_CELLS := 0.9
## Size of the waiting pieces in the tray compared to the board.
const TRAY_SCALE := 0.55

var state := GameState.new()
## Set by Main before adding the screen: continue the saved game?
var resume_saved := false

# --- layout (recomputed when the screen size changes) ---
var view_size := Vector2.ZERO
var cell_size := 100.0
var board_origin := Vector2.ZERO
var tray_centers: Array[Vector2] = []
var tray_slot_size := Vector2.ZERO

# --- dragging ---
var drag_slot := -1
var drag_pos := Vector2.ZERO
var drag_scale := 1.0
var has_ghost := false
var ghost_cell := Vector2i.ZERO
var preview_lines := {"rows": [], "cols": []}

# --- animation values (changed by tweens) ---
var return_slot := -1
var return_from := Vector2.ZERO
var return_t := 1.0
var tray_appear := 1.0
var pulse_cells: Array[Vector2i] = []
var pulse := 0.0
var displayed_score := 0.0
var best_at_start := 0
var celebrated_best := false

# --- nodes ---
var effects: Node2D
var ui_layer: CanvasLayer
var hud: Control
var score_label: Label
var best_label: Label
var pause_button: Button
var overlay: OverlayPanel
var board_style: StyleBoxFlat


func _ready() -> void:
	if resume_saved and SaveData.has_saved_game():
		if not state.from_dict(SaveData.saved_game) or state.game_over:
			state.new_game()
	else:
		# Starting fresh replaces any unfinished game.
		SaveData.saved_game = {}
		SaveData.write()
	displayed_score = float(state.score)
	best_at_start = SaveData.best_score
	effects = Node2D.new()
	add_child(effects)
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_animate_tray_in()


func _process(_delta: float) -> void:
	score_label.text = str(roundi(displayed_score))
	queue_redraw()


# =====================================================================
# Layout
# =====================================================================

func _build_hud() -> void:
	# UI goes on its own CanvasLayer so it always covers the full screen
	# (Controls inside a Node2D don't get the screen size).
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)

	score_label = UIKit.label("0", 120, Palette.text)
	hud.add_child(score_label)

	best_label = UIKit.label("", 48, Palette.accent)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_update_best_label()
	hud.add_child(best_label)

	pause_button = UIKit.button("II", Vector2(130, 130), 56)
	pause_button.pressed.connect(_open_pause)
	hud.add_child(pause_button)


func _layout() -> void:
	view_size = get_viewport_rect().size
	# Keep clear of notches / system bars on phones.
	var insets := UIKit.safe_insets(get_viewport())
	var top_safe := 60.0 + insets.x
	var bottom_safe := view_size.y - insets.y

	var board_px := minf(view_size.x - 80.0, 1000.0)
	board_px = minf(board_px, (bottom_safe - top_safe) * 0.52)
	cell_size = board_px / Board.SIZE
	board_style = null # rebuilt at the new size
	board_origin = Vector2(
		(view_size.x - board_px) * 0.5,
		maxf(top_safe + 300.0, top_safe + (bottom_safe - top_safe) * 0.45 - board_px * 0.5))

	var board_bottom := board_origin.y + board_px
	var tray_y := board_bottom + (bottom_safe - board_bottom) * 0.5
	var spacing := minf(view_size.x / 3.0, 360.0)
	tray_centers.clear()
	for i in GameState.TRAY_SIZE:
		tray_centers.append(Vector2(view_size.x * 0.5 + (i - 1) * spacing, tray_y))
	tray_slot_size = Vector2(spacing, minf(bottom_safe - board_bottom, 460.0))

	best_label.size = Vector2(view_size.x * 0.6, 130)
	best_label.position = Vector2(50, top_safe)
	pause_button.position = Vector2(view_size.x - 180, top_safe)
	score_label.size = Vector2(view_size.x, 160)
	score_label.position = Vector2(0, board_origin.y - 220)


func _cell_rect(col: int, row: int) -> Rect2:
	var gap := cell_size * 0.06
	return Rect2(
		board_origin + Vector2(col, row) * cell_size + Vector2(gap, gap) * 0.5,
		Vector2(cell_size - gap, cell_size - gap))


func _board_center() -> Vector2:
	return board_origin + Vector2.ONE * cell_size * Board.SIZE * 0.5


# =====================================================================
# Drawing
# =====================================================================

func _draw() -> void:
	_draw_board()
	_draw_tray()
	if drag_slot != -1:
		_draw_dragged()


func _draw_board() -> void:
	var board_px := cell_size * Board.SIZE
	var pad := cell_size * 0.14
	if board_style == null:
		board_style = UIKit.neon_panel_style(Palette.board_bg, Palette.board_glow,
			int(cell_size * 0.3), 0, 4, int(cell_size * 0.25))
	draw_style_box(board_style,
		Rect2(board_origin - Vector2(pad, pad), Vector2.ONE * (board_px + pad * 2)))

	# Cells in lines that would be cleared take the dragged piece's color.
	var lit := {}
	var drag_color := Color.WHITE
	if drag_slot != -1 and has_ghost:
		drag_color = Palette.piece_colors[state.tray[drag_slot]["color"]]
		for r in preview_lines["rows"]:
			for c in Board.SIZE:
				lit[Vector2i(c, r)] = true
		for c in preview_lines["cols"]:
			for r in Board.SIZE:
				lit[Vector2i(c, r)] = true

	for row in Board.SIZE:
		for col in Board.SIZE:
			var rect := _cell_rect(col, row)
			var v := state.board.get_cell(col, row)
			if v == Board.EMPTY:
				CellPainter.draw_empty(self, rect)
				continue
			var color: Color = Palette.piece_colors[v]
			if lit.has(Vector2i(col, row)):
				color = drag_color
			elif pulse > 0.0 and pulse_cells.has(Vector2i(col, row)):
				color = color.lightened(0.45 * pulse)
			CellPainter.draw_cell(self, rect, color)

	# Shadow of where the dragged piece will land.
	if drag_slot != -1 and has_ghost:
		for p in state.tray[drag_slot]["shape"]:
			var cell: Vector2i = ghost_cell + p
			var alpha: float = 1.0 if lit.has(cell) else Palette.ghost_alpha
			CellPainter.draw_cell(self, _cell_rect(cell.x, cell.y), drag_color, alpha)


func _draw_tray() -> void:
	for i in state.tray.size():
		var piece = state.tray[i]
		if piece == null or i == drag_slot:
			continue
		var center: Vector2 = tray_centers[i]
		var scale_now := TRAY_SCALE * tray_appear
		if i == return_slot and return_t < 1.0:
			center = return_from.lerp(center, return_t)
			scale_now = lerpf(1.0, TRAY_SCALE, return_t)
		_draw_piece(piece, center, cell_size * scale_now)


func _draw_dragged() -> void:
	var piece: Dictionary = state.tray[drag_slot]
	var b := Vector2(Shapes.bounds(piece["shape"]))
	var center := _drag_top_left() + b * cell_size * 0.5
	_draw_piece(piece, center, cell_size * drag_scale)


func _draw_piece(piece: Dictionary, center: Vector2, csize: float) -> void:
	if csize <= 1.0:
		return
	var b := Vector2(Shapes.bounds(piece["shape"]))
	var origin := center - b * csize * 0.5
	var gap := csize * 0.06
	var color: Color = Palette.piece_colors[piece["color"]]
	for p in piece["shape"]:
		var rect := Rect2(origin + Vector2(p) * csize + Vector2(gap, gap) * 0.5,
			Vector2(csize - gap, csize - gap))
		CellPainter.draw_cell(self, rect, color)


# =====================================================================
# Touch input
# =====================================================================

func _unhandled_input(event: InputEvent) -> void:
	if overlay != null or state.game_over:
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_try_pick(event.position)
		elif drag_slot != -1:
			_drop()
	elif event is InputEventScreenDrag and event.index == 0 and drag_slot != -1:
		drag_pos = event.position
		_update_ghost()


func _try_pick(pos: Vector2) -> void:
	for i in state.tray.size():
		if state.tray[i] == null:
			continue
		var rect := Rect2(tray_centers[i] - tray_slot_size * 0.5, tray_slot_size)
		if rect.has_point(pos):
			drag_slot = i
			drag_pos = pos
			drag_scale = TRAY_SCALE
			if return_slot == i:
				return_slot = -1
			create_tween().tween_property(self, "drag_scale", 1.0, 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_update_ghost()
			Audio.play("pick")
			return


## Top-left corner of the dragged piece (it floats above the finger).
func _drag_top_left() -> Vector2:
	var b := Vector2(Shapes.bounds(state.tray[drag_slot]["shape"])) * cell_size
	return drag_pos - Vector2(b.x * 0.5, b.y + cell_size * LIFT_CELLS)


func _update_ghost() -> void:
	var shape: Array = state.tray[drag_slot]["shape"]
	var top_left := _drag_top_left()
	var col := roundi((top_left.x - board_origin.x) / cell_size)
	var row := roundi((top_left.y - board_origin.y) / cell_size)
	has_ghost = state.board.can_place(shape, col, row)
	if has_ghost:
		ghost_cell = Vector2i(col, row)
		preview_lines = state.board.lines_if_placed(shape, col, row)
	else:
		preview_lines = {"rows": [], "cols": []}


func _drop() -> void:
	var slot := drag_slot
	var b := Vector2(Shapes.bounds(state.tray[slot]["shape"]))
	var dragged_center := _drag_top_left() + b * cell_size * 0.5
	var target := ghost_cell
	var could_place := has_ghost

	drag_slot = -1
	has_ghost = false
	preview_lines = {"rows": [], "cols": []}

	if could_place:
		var result := state.try_place(slot, target.x, target.y)
		if result["ok"]:
			_on_placed(result)
			return

	# Not a valid spot: fly back to the tray.
	return_slot = slot
	return_from = dragged_center
	return_t = 0.0
	create_tween().tween_property(self, "return_t", 1.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	Audio.play("invalid")


# =====================================================================
# Reactions
# =====================================================================

func _on_placed(result: Dictionary) -> void:
	Audio.play("place")
	Audio.vibrate(15)

	pulse_cells.clear()
	for p in result["piece"]["shape"]:
		pulse_cells.append(Vector2i(result["col"], result["row"]) + p)
	pulse = 1.0
	create_tween().tween_property(self, "pulse", 0.0, 0.3)

	if result["line_count"] > 0:
		_play_clear(result)

	create_tween().tween_property(self, "displayed_score", float(state.score), 0.35)

	if state.score > SaveData.best_score:
		SaveData.best_score = state.score
		_update_best_label()
	if best_at_start > 0 and state.score > best_at_start and not celebrated_best:
		celebrated_best = true
		_popup("New Best!", _board_center() - Vector2(0, 260), 90, Palette.accent, 0.3)
		Audio.play("new_best")

	if result["refilled"]:
		_animate_tray_in()

	if result["game_over"]:
		_on_game_over()
	else:
		_save_progress()


## Saves the unfinished game after every move, so closing the app
## (or the phone killing it) never loses progress.
func _save_progress() -> void:
	SaveData.saved_game = state.to_dict()
	SaveData.write()


func _play_clear(result: Dictionary) -> void:
	var b := Vector2(Shapes.bounds(result["piece"]["shape"]))
	var piece_center := Vector2(result["col"], result["row"]) + b * 0.5
	for item in result["cleared"]:
		var pos: Vector2i = item["pos"]
		var fx := ClearEffect.new()
		var delay := (Vector2(pos) + Vector2(0.5, 0.5)).distance_to(piece_center) * 0.03
		fx.setup(_cell_rect(pos.x, pos.y), Palette.piece_colors[item["color"]], delay)
		effects.add_child(fx)

	var streak: int = result["streak"]
	Audio.play("clear", 1.0 + 0.08 * mini(streak - 1, 8))
	Audio.vibrate(40)

	var center := _board_center()
	var word := Scoring.praise_word(result["line_count"])
	if word != "":
		_popup(word, center - Vector2(0, 60), 120, Palette.accent)
	if streak >= 2:
		_popup("Combo x%d" % streak, center + Vector2(0, 80), 76, Palette.text, 0.1)
	_popup("+%d" % result["points"], board_origin + piece_center * cell_size, 64, Palette.text)
	if result["board_cleared"]:
		_popup("Board Clear!", center + Vector2(0, 200), 96, Palette.accent, 0.25)

	if result["line_count"] >= 3 or streak >= 4:
		_shake()


func _popup(text: String, pos: Vector2, font_size: int, color: Color, delay: float = 0.0) -> void:
	var p := PopupText.new()
	hud.add_child(p)
	p.show_text(text, pos, font_size, color, delay)


func _shake() -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(self, "position", Vector2(randf_range(-14, 14), randf_range(-14, 14)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)


func _animate_tray_in() -> void:
	tray_appear = 0.0
	create_tween().tween_property(self, "tray_appear", 1.0, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_best_label() -> void:
	best_label.text = "BEST  %d" % SaveData.best_score


func _on_game_over() -> void:
	SaveData.saved_game = {}
	SaveData.write()
	var is_new_best := state.score > best_at_start
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		Audio.play("game_over")
		_popup("No more space!", _board_center(), 90, Palette.text))
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		var panel := GameOverPanel.new()
		panel.setup(state.score, SaveData.best_score, is_new_best)
		panel.play_again_pressed.connect(_restart)
		panel.home_pressed.connect(func(): exit_to_menu.emit())
		_show_overlay(panel))


# =====================================================================
# Pause / restart
# =====================================================================

func _open_pause() -> void:
	if overlay != null or state.game_over:
		return
	drag_slot = -1
	has_ghost = false
	var panel := PausePanel.new()
	panel.resume_pressed.connect(_close_overlay)
	panel.restart_pressed.connect(_restart)
	panel.home_pressed.connect(func():
		SaveData.write()
		exit_to_menu.emit())
	_show_overlay(panel)


func _show_overlay(panel: OverlayPanel) -> void:
	_close_overlay()
	overlay = panel
	ui_layer.add_child(panel)


func _close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null


func _restart() -> void:
	_close_overlay()
	SaveData.saved_game = {}
	SaveData.write()
	for fx in effects.get_children():
		fx.queue_free()
	state.new_game()
	best_at_start = SaveData.best_score
	celebrated_best = false
	displayed_score = 0.0
	drag_slot = -1
	return_slot = -1
	pulse = 0.0
	_animate_tray_in()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if overlay is PausePanel:
			_close_overlay()
		elif overlay == null:
			_open_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveData.write()
		if what == NOTIFICATION_APPLICATION_PAUSED:
			_open_pause()
