class_name GameScreen
extends Node2D
## The play screen: draws the board + tray, handles dragging with the
## finger, and plays the effects. The rules live in GameState.

signal exit_to_menu

## How high above the finger the dragged piece floats (in cells).
const LIFT_CELLS := 0.9
## Size of the waiting pieces in the tray compared to the board.
const TRAY_SCALE := 0.55
## How far (game units) the finger must move before it counts as a drag.
const DRAG_THRESHOLD := 24.0
## Seconds without touching the screen before a hint appears.
const HINT_DELAY := 8.0
## Length of one animated-hand demonstration (seconds).
const GUIDE_CYCLE := 1.8

var state := GameState.new()
## Set by Main before adding the screen: continue the saved game?
var resume_saved := false
## Developer option: auto-play this many moves at start (for screenshots).
var demo_moves := 0
## Set by Main: play the 3-step tutorial before the real game.
var tutorial := false

# --- tutorial / hints ---
var tutorial_step := 0 # 0 = off, 1 = drag a piece, 2 = clear a line
## Text key shown above the board instead of the score ("" = none):
## tutorial steps, power-up instructions, rescue message.
var banner_key := ""
var tutorial_kept_save := false # started from "How to play" with a game to continue
var guide_slot := -1 # tray piece the animated hand demonstrates (-1 = none)
var guide_cell := Vector2i(-1, -1) # where it should go (top-left cell)
var hint_active := false
var idle_time := 0.0

# --- power-ups ---
var aim_mode := "" # "hammer" / "bomb" while waiting for a tap on the board
var rescue_mode := false # out of moves, player chose to use a power-up
var undo_snapshot := {} # game before the last move (for Undo)
var power_buttons := {} # kind -> PowerupButton
const POWER_BAR_HEIGHT := 160.0

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
var drag_start := Vector2.ZERO
var drag_moved := false
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
var hud_layer: CanvasLayer
var overlay_layer: CanvasLayer
var hud: Control
var score_label: Label
var best_label: Label
var pause_button: Button
var tutorial_label: Label
var skip_button: Button
var overlay: OverlayPanel
var board_style: StyleBoxFlat


func _ready() -> void:
	if tutorial:
		# Keep any unfinished game; the tutorial uses its own boards.
		tutorial_kept_save = SaveData.has_saved_game()
	elif resume_saved and SaveData.has_saved_game():
		if not state.from_dict(SaveData.saved_game) or state.game_over:
			# Broken or finished save: start fresh and forget it, so the
			# menu doesn't keep offering "Continue" for it.
			state.new_game()
			SaveData.saved_game = {}
			SaveData.write()
	elif demo_moves == 0:
		# Starting fresh replaces any unfinished game.
		SaveData.saved_game = {}
		SaveData.write()
	if demo_moves > 0:
		# Developer preview: never touches the player's saved game.
		_play_demo_moves(demo_moves)
	displayed_score = float(state.score)
	best_at_start = SaveData.best_score
	effects = Node2D.new()
	add_child(effects)
	# UI goes on CanvasLayers so it always covers the full screen
	# (Controls inside a Node2D don't get the screen size).
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 1
	add_child(hud_layer)
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 2
	add_child(overlay_layer)
	_build_hud()
	get_viewport().size_changed.connect(_layout)
	Palette.theme_changed.connect(_on_theme_changed)
	Lang.language_changed.connect(_on_theme_changed)
	if tutorial:
		_tutorial_setup(1)
	_layout()
	_animate_tray_in()


## Rebuild everything that baked in the old theme's colors or language.
func _on_theme_changed() -> void:
	board_style = null
	hud.queue_free()
	_build_hud()
	_layout()
	if overlay is SettingsPanel:
		_close_overlay()
		_open_settings() # stay in Settings after switching theme/language
	elif overlay is PausePanel:
		_close_overlay()
		_open_pause()


## Developer option: fill the board a bit (first-fit) for screenshots.
func _play_demo_moves(count: int) -> void:
	for n in count:
		var done := false
		for slot in state.tray.size():
			if done or state.tray[slot] == null:
				continue
			for row in Board.SIZE:
				for col in Board.SIZE:
					if not done and state.can_place(slot, (col * 3) % Board.SIZE, row):
						state.try_place(slot, (col * 3) % Board.SIZE, row)
						done = true
		if state.game_over:
			state.new_game()


func _process(delta: float) -> void:
	score_label.text = str(roundi(displayed_score))
	_update_hint(delta)
	queue_redraw()


# =====================================================================
# Layout
# =====================================================================

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)

	score_label = UIKit.label("0", 120, Palette.text)
	hud.add_child(score_label)

	best_label = UIKit.label("", 48, Palette.accent)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_update_best_label()
	hud.add_child(best_label)

	pause_button = UIKit.button("II", Vector2(130, 130), 56)
	pause_button.pressed.connect(_open_pause)
	hud.add_child(pause_button)

	# Tutorial: instruction text above the board + a Skip button.
	tutorial_label = UIKit.label("", 54, Palette.text)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Give it its real width BEFORE any text is set: a wrapping label with
	# no width puts every word on its own line and grows very tall.
	tutorial_label.size = Vector2(get_viewport_rect().size.x - 100, 200)
	hud.add_child(tutorial_label)
	skip_button = UIKit.button(Lang.t("SKIP"), Vector2(260, 110), 40, Palette.text_dim)
	skip_button.pressed.connect(_finish_tutorial)
	hud.add_child(skip_button)

	# Power-up bar (under the tray).
	power_buttons.clear()
	for kind in Rewards.KINDS:
		var b := PowerupButton.new(kind)
		b.pressed.connect(_on_power_pressed.bind(kind))
		hud.add_child(b)
		power_buttons[kind] = b
	_refresh_hud_mode()


## Shows the normal HUD, the tutorial HUD, or a banner message, and
## updates the power-up buttons.
func _refresh_hud_mode() -> void:
	var in_tutorial := tutorial_step > 0
	var has_banner := banner_key != ""
	score_label.visible = not has_banner
	best_label.visible = not in_tutorial
	pause_button.visible = not in_tutorial
	tutorial_label.visible = has_banner
	skip_button.visible = in_tutorial
	if has_banner:
		tutorial_label.text = Lang.t(banner_key)
	for kind in power_buttons:
		var b: PowerupButton = power_buttons[kind]
		b.visible = not in_tutorial
		b.set_state(SaveData.powerup_count(kind), aim_mode == kind)


func _layout() -> void:
	view_size = get_viewport_rect().size
	# Keep clear of notches / system bars on phones.
	var insets := UIKit.safe_insets(get_viewport())
	var top_safe := 60.0 + insets.x
	var screen_bottom := view_size.y - insets.y
	# The power-up bar sits at the very bottom; the board and tray share
	# the space above it.
	var bottom_safe := screen_bottom - POWER_BAR_HEIGHT

	var board_px := minf(view_size.x - 80.0, 1000.0)
	board_px = minf(board_px, (bottom_safe - top_safe) * 0.55)
	cell_size = board_px / Board.SIZE
	board_style = null # rebuilt at the new size
	board_origin = Vector2(
		(view_size.x - board_px) * 0.5,
		maxf(top_safe + 290.0, top_safe + (bottom_safe - top_safe) * 0.45 - board_px * 0.5))

	var board_bottom := board_origin.y + board_px
	var tray_y := board_bottom + (bottom_safe - board_bottom) * 0.5
	var spacing := minf(view_size.x / 3.0, 360.0)
	tray_centers.clear()
	for i in GameState.TRAY_SIZE:
		tray_centers.append(Vector2(view_size.x * 0.5 + (i - 1) * spacing, tray_y))
	tray_slot_size = Vector2(spacing, minf(bottom_safe - board_bottom, 460.0))

	var bar_gap := 30.0
	var bar_w := Rewards.KINDS.size() * 200.0 + (Rewards.KINDS.size() - 1) * bar_gap
	var bar_x := (view_size.x - bar_w) * 0.5
	var order: Array = Rewards.KINDS.duplicate()
	if Lang.is_rtl():
		order.reverse()
	for i in order.size():
		var b: PowerupButton = power_buttons[order[i]]
		b.size = Vector2(200, 130)
		b.position = Vector2(bar_x + i * (200.0 + bar_gap), screen_bottom - POWER_BAR_HEIGHT + 10)

	best_label.size = Vector2(view_size.x * 0.6, 130)
	if Lang.is_rtl():
		# Right-to-left: best score on the right, pause button on the left.
		best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		best_label.position = Vector2(view_size.x - best_label.size.x - 50, top_safe)
		pause_button.position = Vector2(50, top_safe)
	else:
		best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		best_label.position = Vector2(50, top_safe)
		pause_button.position = Vector2(view_size.x - 180, top_safe)
	score_label.size = Vector2(view_size.x, 160)
	score_label.position = Vector2(0, board_origin.y - 220)
	tutorial_label.size = Vector2(view_size.x - 100, 200)
	tutorial_label.position = Vector2(50, board_origin.y - 240)
	# Long words (e.g. German "Überspringen") make the button wider.
	var skip_w := maxf(skip_button.size.x, skip_button.get_combined_minimum_size().x)
	skip_button.position = Vector2(50 if Lang.is_rtl() else view_size.x - 50 - skip_w, top_safe)


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
	if aim_mode != "":
		_draw_aim()
	_draw_tray()
	if drag_slot != -1:
		_draw_dragged()
	elif overlay == null:
		_draw_guide()


func _draw_board() -> void:
	var board_px := cell_size * Board.SIZE
	var pad := cell_size * 0.14
	if board_style == null:
		board_style = UIKit.neon_panel_style(Palette.board_bg, Palette.board_edge,
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


func _draw_piece(piece: Dictionary, center: Vector2, csize: float, alpha: float = 1.0) -> void:
	if csize <= 1.0:
		return
	var b := Vector2(Shapes.bounds(piece["shape"]))
	var origin := center - b * csize * 0.5
	var gap := csize * 0.06
	var color: Color = Palette.piece_colors[piece["color"]]
	for p in piece["shape"]:
		var rect := Rect2(origin + Vector2(p) * csize + Vector2(gap, gap) * 0.5,
			Vector2(csize - gap, csize - gap))
		CellPainter.draw_cell(self, rect, color, alpha)


## While the hammer/bomb waits for a target: pulse the filled cells.
func _draw_aim() -> void:
	var glow := 0.18 + 0.14 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
	for row in Board.SIZE:
		for col in Board.SIZE:
			if state.board.get_cell(col, row) != Board.EMPTY:
				var r := _cell_rect(col, row)
				draw_rect(r, Color(1, 1, 1, glow))
				draw_rect(r, Color(Palette.accent, glow * 2.0), false, 3.0)


## Animated hand showing a piece moving from the tray to guide_cell
## (tutorial steps and idle hints), plus a pulsing shadow at the target.
func _draw_guide() -> void:
	if guide_slot < 0 or guide_slot >= state.tray.size() or state.tray[guide_slot] == null:
		return
	var piece: Dictionary = state.tray[guide_slot]
	var t := Time.get_ticks_msec() / 1000.0
	var color: Color = Palette.piece_colors[piece["color"]]

	# Pulsing shadow where the piece should go.
	var glow := 0.3 + 0.25 * sin(t * 5.0)
	for p in piece["shape"]:
		var cell: Vector2i = guide_cell + p
		CellPainter.draw_cell(self, _cell_rect(cell.x, cell.y), color, glow)

	# Hand path: tray → above the target (same lift as a real drag).
	var b := Vector2(Shapes.bounds(piece["shape"]))
	var start: Vector2 = tray_centers[guide_slot]
	var target_top_left := board_origin + Vector2(guide_cell) * cell_size
	var finger := target_top_left + Vector2(b.x * 0.5, b.y + LIFT_CELLS) * cell_size
	var phase := fmod(t, GUIDE_CYCLE) / GUIDE_CYCLE
	var move := smoothstep(0.15, 0.75, phase)
	var fade := minf(smoothstep(0.0, 0.1, phase), 1.0 - smoothstep(0.85, 1.0, phase))
	var pos := start.lerp(finger, move)

	# Ghost of the piece being carried (appears once the hand starts
	# moving, so it doesn't overlap the piece still in the tray).
	var csize := lerpf(cell_size * TRAY_SCALE, cell_size, move)
	var carried_center := pos - Vector2(0, (b.y * 0.5 + LIFT_CELLS) * csize)
	_draw_piece(piece, carried_center, csize, 0.6 * fade * smoothstep(0.0, 0.3, move))

	# The "finger": a soft disc with a ring.
	var r := cell_size * 0.32
	draw_circle(pos, r * 1.25, Color(Palette.accent, 0.25 * fade))
	draw_circle(pos, r, Color(1, 1, 1, 0.85 * fade))
	draw_arc(pos, r, 0, TAU, 32, Color(Palette.accent, fade), maxf(2.0, r * 0.18), true)


# =====================================================================
# Touch input
# =====================================================================

func _unhandled_input(event: InputEvent) -> void:
	if overlay != null or state.game_over:
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_clear_hint()
			if aim_mode != "":
				_aim_tap(event.position)
				return
			_try_pick(event.position)
		elif drag_slot != -1:
			_drop()
	elif event is InputEventScreenDrag and event.index == 0 and drag_slot != -1:
		drag_pos = event.position
		if not drag_moved and drag_pos.distance_to(drag_start) > DRAG_THRESHOLD:
			drag_moved = true
		_update_ghost()


func _try_pick(pos: Vector2) -> void:
	for i in state.tray.size():
		if state.tray[i] == null:
			continue
		var rect := Rect2(tray_centers[i] - tray_slot_size * 0.5, tray_slot_size)
		if rect.has_point(pos):
			drag_slot = i
			drag_pos = pos
			drag_start = pos
			drag_moved = false
			drag_scale = TRAY_SCALE
			if return_slot == i:
				return_slot = -1
			create_tween().tween_property(self, "drag_scale", 1.0, 0.12) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_update_ghost()
			Audio.play("pick")
			return


## Idle hints: after HINT_DELAY seconds without touching, show the best
## move (logic/hint.gd) with the animated hand.
func _update_hint(delta: float) -> void:
	var can_hint := SaveData.hints_on and tutorial_step == 0 and overlay == null \
		and not state.game_over and drag_slot == -1 and aim_mode == "" and not rescue_mode
	if not can_hint:
		idle_time = 0.0
		return
	idle_time += delta
	if idle_time >= HINT_DELAY and not hint_active:
		var m := Hint.best_move(state)
		if not m.is_empty():
			hint_active = true
			guide_slot = m["slot"]
			guide_cell = Vector2i(m["col"], m["row"])


func _clear_hint() -> void:
	idle_time = 0.0
	if hint_active:
		hint_active = false
		guide_slot = -1


## Top-left corner of the dragged piece (it floats above the finger).
func _drag_top_left() -> Vector2:
	var b := Vector2(Shapes.bounds(state.tray[drag_slot]["shape"])) * cell_size
	return drag_pos - Vector2(b.x * 0.5, b.y + cell_size * LIFT_CELLS)


func _update_ghost() -> void:
	var shape: Array = state.tray[drag_slot]["shape"]
	var top_left := _drag_top_left()
	var col := roundi((top_left.x - board_origin.x) / cell_size)
	var row := roundi((top_left.y - board_origin.y) / cell_size)
	# No landing spot until the finger has really moved: a tap must never
	# drop the piece onto the board.
	has_ghost = drag_moved and state.board.can_place(shape, col, row)
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
	var was_tap := not drag_moved

	drag_slot = -1
	drag_moved = false
	has_ghost = false
	preview_lines = {"rows": [], "cols": []}

	if could_place:
		var before := state.to_dict()
		var result := state.try_place(slot, target.x, target.y)
		if result["ok"] and tutorial_step == 0:
			undo_snapshot = before
		if result["ok"]:
			_on_placed(result)
			return

	# Not a valid spot: fly back to the tray.
	return_slot = slot
	return_from = dragged_center
	return_t = 0.0
	create_tween().tween_property(self, "return_t", 1.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not was_tap:
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

	_clear_hint()
	if tutorial_step > 0:
		_tutorial_after_move(result)
		return

	create_tween().tween_property(self, "displayed_score", float(state.score), 0.35)

	if state.score > SaveData.best_score:
		SaveData.best_score = state.score
		_update_best_label()
	if best_at_start > 0 and state.score > best_at_start and not celebrated_best:
		celebrated_best = true
		_popup(Lang.t("NEW_BEST"), _board_center() - Vector2(0, 260), 90, Palette.accent, 0.3)
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
	if demo_moves > 0:
		return # developer preview: leave the real save alone
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
	# Bigger clears and longer combos shake the phone longer and harder.
	var lines: int = result["line_count"]
	var power := clampi((lines - 1) + (streak - 1), 0, 6)
	Audio.vibrate(40 + power * 25, lerpf(0.5, 1.0, power / 6.0))

	var center := _board_center()
	var word := Scoring.praise_word(result["line_count"])
	if word != "":
		_popup(Lang.t(word), center - Vector2(0, 60), 120, Palette.accent)
	if streak >= 2:
		_popup(Lang.t("COMBO") % streak, center + Vector2(0, 80), 76, Palette.text, 0.1)
	_popup("+%d" % result["points"], board_origin + piece_center * cell_size, 64, Palette.text)
	if result["board_cleared"]:
		_popup(Lang.t("BOARD_CLEAR"), center + Vector2(0, 200), 96, Palette.accent, 0.25)

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
	best_label.text = "%s  %d" % [Lang.t("BEST"), SaveData.best_score]


func _on_game_over() -> void:
	SaveData.saved_game = {}
	SaveData.write()
	var is_new_best := state.score > best_at_start
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		Audio.play("game_over")
		_popup(Lang.t("NO_SPACE"), _board_center(), 90, Palette.text))
	tw.tween_interval(1.2)
	tw.tween_callback(_show_game_over_panel.bind(is_new_best))


func _show_game_over_panel(is_new_best: bool) -> void:
	var panel := GameOverPanel.new()
	panel.setup(state.score, SaveData.best_score, is_new_best, _can_rescue())
	panel.play_again_pressed.connect(_restart)
	panel.home_pressed.connect(func(): exit_to_menu.emit())
	panel.keep_playing_pressed.connect(_start_rescue)
	_show_overlay(panel)


# =====================================================================
# Power-ups: hammer, bomb, shuffle, undo
# =====================================================================

func _on_power_pressed(kind: String) -> void:
	if overlay != null or tutorial_step > 0 or drag_slot != -1:
		return
	_clear_hint()
	if aim_mode == kind:
		_cancel_aim() # tapping the active button again cancels it
		return
	if SaveData.powerup_count(kind) <= 0:
		return
	match kind:
		"shuffle":
			SaveData.use_powerup(kind)
			state.shuffle_tray()
			Audio.play("pick", 0.8)
			_animate_tray_in()
			_after_powerup()
		"undo":
			if undo_snapshot.is_empty():
				_popup(Lang.t("NOTHING_TO_UNDO"), _board_center(), 64, Palette.text)
				return
			SaveData.use_powerup(kind)
			state.from_dict(undo_snapshot)
			undo_snapshot = {}
			Audio.play("pick", 0.7)
			create_tween().tween_property(self, "displayed_score", float(state.score), 0.3)
			_animate_tray_in()
			_after_powerup()
		"hammer", "bomb":
			aim_mode = kind
			banner_key = "TAP_HAMMER" if kind == "hammer" else "TAP_BOMB"
			_refresh_hud_mode()


func _cancel_aim() -> void:
	aim_mode = ""
	banner_key = "RESCUE" if rescue_mode else ""
	_refresh_hud_mode()


## The board cell under a screen position, or (-1, -1).
func _cell_at(pos: Vector2) -> Vector2i:
	var col := floori((pos.x - board_origin.x) / cell_size)
	var row := floori((pos.y - board_origin.y) / cell_size)
	if col < 0 or row < 0 or col >= Board.SIZE or row >= Board.SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, row)


## A tap while the hammer or bomb is waiting for a target.
func _aim_tap(pos: Vector2) -> void:
	var cell := _cell_at(pos)
	if cell.x < 0:
		_cancel_aim() # tapped outside the board
		return
	var targets: Array = [cell] if aim_mode == "hammer" else Rewards.bomb_area(cell)
	var removed := state.remove_cells(targets)
	if removed.is_empty():
		return # nothing to break there; keep aiming
	SaveData.use_powerup(aim_mode)
	for item in removed:
		var p: Vector2i = item["pos"]
		var fx := ClearEffect.new()
		fx.setup(_cell_rect(p.x, p.y), Palette.piece_colors[item["color"]], Vector2(p - cell).length() * 0.04)
		effects.add_child(fx)
	Audio.play("clear", 0.75 if aim_mode == "bomb" else 0.9)
	Audio.vibrate(90 if aim_mode == "bomb" else 40, 1.0 if aim_mode == "bomb" else 0.6)
	if aim_mode == "bomb":
		_shake()
	aim_mode = ""
	_after_powerup()


## Common bookkeeping after any power-up was used.
func _after_powerup() -> void:
	if aim_mode == "":
		banner_key = ""
	# Hammer / bomb / shuffle change the game: an older Undo would also
	# silently cancel them, so it is no longer offered.
	undo_snapshot = {}
	state.game_over = not state.has_any_move()
	if rescue_mode:
		if not state.game_over:
			rescue_mode = false # saved!
		elif not _can_rescue():
			rescue_mode = false
			_refresh_hud_mode()
			_on_game_over()
			return
		else:
			banner_key = "RESCUE"
	_refresh_hud_mode()
	if not state.game_over:
		_save_progress()


## Is there any power-up that could still help after running out of moves?
func _can_rescue() -> bool:
	for kind in ["hammer", "bomb", "shuffle"]:
		if SaveData.powerup_count(kind) > 0:
			return true
	return SaveData.powerup_count("undo") > 0 and not undo_snapshot.is_empty()


## "Keep playing" on the game-over panel: stay on the board and use a power-up.
func _start_rescue() -> void:
	_close_overlay()
	rescue_mode = true
	state.game_over = false # lets the power-up buttons and board taps work
	banner_key = "RESCUE"
	_refresh_hud_mode()


# =====================================================================
# Tutorial (3 steps: drag a piece → clear a line → how the game ends)
# =====================================================================

func _tutorial_piece(pattern: String, color: int) -> Dictionary:
	return {"shape": Shapes.parse(pattern), "color": color}


func _tutorial_setup(step: int) -> void:
	if not tutorial:
		return # skipped while a step change was pending
	tutorial_step = step
	state.board.reset()
	state.score = 0
	state.streak = 0
	state.moves_since_clear = 0
	state.game_over = false
	if step == 1:
		# Step 1: just drag the square onto the board.
		state.tray = [null, _tutorial_piece("XX\nXX", 4), null]
		guide_cell = Vector2i(3, 3)
		banner_key = "TUT_DRAG"
	else:
		# Step 2: a row with a 3-cell gap and the exact piece to fill it.
		var colors := [0, 1, 2, 5, 6]
		var k := 0
		for c in Board.SIZE:
			if c < 2 or c > 4:
				state.board.set_cell(c, 5, colors[k % colors.size()])
				k += 1
		state.tray = [null, _tutorial_piece("XXX", 3), null]
		guide_cell = Vector2i(2, 5)
		if banner_key != "TUT_TRY_AGAIN":
			banner_key = "TUT_CLEAR"
	guide_slot = 1
	_refresh_hud_mode()
	_animate_tray_in()


func _tutorial_after_move(result: Dictionary) -> void:
	# The rules refilled the tray with random pieces; hide them.
	state.tray = [null, null, null]
	state.game_over = false
	guide_slot = -1
	var tw := create_tween()
	tw.tween_interval(0.7)
	if tutorial_step == 1:
		tw.tween_callback(_tutorial_setup.bind(2))
	elif result["line_count"] > 0:
		tw.tween_callback(_tutorial_show_end)
	else:
		banner_key = "TUT_TRY_AGAIN"
		_refresh_hud_mode()
		tw.tween_callback(_tutorial_setup.bind(2))


func _tutorial_show_end() -> void:
	if not tutorial:
		return
	var panel := OverlayPanel.new()
	panel.add_text(Lang.t("TUT_END"), 56, Palette.text)
	panel.add_button(Lang.t("TUT_START"), _finish_tutorial, Palette.button_primary)
	_show_overlay(panel)


## Ends (or skips) the tutorial and starts the real game.
func _finish_tutorial() -> void:
	if tutorial_step == 0 and not tutorial:
		return
	tutorial = false
	tutorial_step = 0
	guide_slot = -1
	SaveData.tutorial_done = true
	SaveData.write()
	_close_overlay()
	if tutorial_kept_save:
		# Opened from "How to play" while a game was in progress: go back
		# to the menu so it can still be continued.
		exit_to_menu.emit()
		return
	_refresh_hud_mode()
	_restart()


# =====================================================================
# Pause / restart
# =====================================================================

func _open_pause() -> void:
	if overlay != null or state.game_over or tutorial_step > 0:
		return
	drag_slot = -1
	has_ghost = false
	var panel := PausePanel.new()
	panel.resume_pressed.connect(_close_overlay)
	panel.restart_pressed.connect(_restart)
	panel.home_pressed.connect(func():
		SaveData.write()
		exit_to_menu.emit())
	panel.settings_pressed.connect(func():
		_close_overlay()
		_open_settings())
	_show_overlay(panel)


## Settings (from the pause gear). "Back" returns to the pause screen.
func _open_settings() -> void:
	var panel := SettingsPanel.new()
	panel.setup(false)
	panel.back_pressed.connect(func():
		_close_overlay()
		_open_pause())
	_show_overlay(panel)


func _show_overlay(panel: OverlayPanel) -> void:
	_close_overlay()
	overlay = panel
	overlay_layer.add_child(panel)


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
	_clear_hint()
	aim_mode = ""
	rescue_mode = false
	undo_snapshot = {}
	if tutorial_step == 0:
		banner_key = ""
	_refresh_hud_mode()
	_animate_tray_in()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if tutorial_step > 0 or tutorial:
			_finish_tutorial()
		elif overlay is SettingsPanel:
			_close_overlay()
			_open_pause()
		elif overlay is PausePanel:
			_close_overlay()
		elif overlay == null:
			_open_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveData.write()
		if what == NOTIFICATION_APPLICATION_PAUSED:
			_open_pause()
