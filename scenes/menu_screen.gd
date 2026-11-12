class_name MenuScreen
extends Control
## Start screen: logo, best score, Continue / Play, power-ups and gifts.
## Settings open from the gear icon. Main rebuilds the menu when the theme
## or language changes (and re-opens Settings if it was open).

## resume = true when the player picked "Continue".
signal play_pressed(resume: bool)
signal how_to_play_pressed

var inventory_icons := {} # kind -> PowerupIcon
var gift_button: Button
var settings_panel: SettingsPanel
var settings_open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)

	var logo := NeonLogo.new(32.0)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(logo)
	box.add_child(UIKit.label(Lang.t("BLOCK_PUZZLE"), 44, Palette.text_dim))
	box.add_child(UIKit.label("%s  %d" % [Lang.t("BEST"), SaveData.best_score], 56, Palette.accent))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	box.add_child(spacer)

	if SaveData.has_saved_game():
		box.add_child(_big_button(Lang.t("CONTINUE"), Palette.button_primary, true))
		box.add_child(_big_button(Lang.t("NEW_GAME"), Palette.button, false))
	else:
		box.add_child(_big_button(Lang.t("PLAY"), Palette.button_primary, false))

	# Power-ups you own + the hourly free gift.
	var inventory := HBoxContainer.new()
	inventory.alignment = BoxContainer.ALIGNMENT_CENTER
	inventory.add_theme_constant_override("separation", 30)
	box.add_child(inventory)
	for kind in Rewards.KINDS:
		var icon := PowerupIcon.new(kind, "", 90.0)
		inventory.add_child(icon)
		inventory_icons[kind] = icon
	gift_button = _wide_button(Lang.t("FREE_GIFT"), Palette.accent)
	gift_button.pressed.connect(_claim_hourly_gift)
	box.add_child(gift_button)
	_refresh_gifts()

	# Everything else (sound, theme, language, hints, how to play) lives
	# in Settings, behind the gear in the top corner.
	var gear := IconButton.new("gear", 130.0, Palette.text_dim)
	gear.pressed.connect(open_settings)
	add_child(gear)
	var insets := UIKit.safe_insets(get_viewport())
	var view := get_viewport_rect().size
	gear.position = Vector2(50 if Lang.is_rtl() else view.x - 180, 60 + insets.x)

	Audio.play_music()
	if SaveData.daily_gift_ready():
		_show_daily_gift.call_deferred()


func _process(_delta: float) -> void:
	_refresh_gift_button()


# --- settings -------------------------------------------------------------

func open_settings() -> void:
	if settings_open:
		return
	settings_open = true
	settings_panel = SettingsPanel.new()
	settings_panel.setup(true)
	settings_panel.back_pressed.connect(close_settings)
	settings_panel.how_to_play_pressed.connect(func(): how_to_play_pressed.emit())
	add_child(settings_panel)


func close_settings() -> void:
	settings_open = false
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null


# --- gifts --------------------------------------------------------------------

func _refresh_gifts() -> void:
	for kind in inventory_icons:
		var icon: PowerupIcon = inventory_icons[kind]
		icon.label_text = "x%d" % SaveData.powerup_count(kind)
		icon.queue_redraw()
	_refresh_gift_button()


func _refresh_gift_button() -> void:
	if gift_button == null:
		return
	var left := SaveData.hourly_gift_seconds_left()
	gift_button.disabled = left > 0
	gift_button.modulate.a = 0.6 if left > 0 else 1.0
	var text := Lang.t("FREE_GIFT") if left == 0 else Lang.t("NEXT_GIFT") % Rewards.format_time(left)
	if gift_button.text != text.to_upper():
		gift_button.text = text.to_upper()


func _claim_hourly_gift() -> void:
	if not UIKit.accept_action():
		return
	var kind := SaveData.claim_hourly_gift()
	if kind == "":
		return
	Audio.play("new_best")
	_show_gift_panel(Lang.t("YOU_GOT"), {kind: 1})


func _show_daily_gift() -> void:
	var panel := _gift_panel(Lang.t("DAILY_GIFT"), Rewards.DAILY_GIFT, Lang.t("CLAIM"))
	panel.closed.connect(func():
		SaveData.claim_daily_gift()
		Audio.play("new_best")
		_refresh_gifts())


func _show_gift_panel(title: String, gift: Dictionary) -> void:
	_gift_panel(title, gift, "OK")
	_refresh_gifts()


## A pop-up listing power-ups with "+N" under each icon.
func _gift_panel(title: String, gift: Dictionary, button_text: String) -> GiftPanel:
	var panel := GiftPanel.new()
	panel.add_text(title, 80, Palette.accent)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	panel.box.add_child(row)
	for kind in gift:
		row.add_child(PowerupIcon.new(kind, "+%d" % gift[kind], 140.0))
	panel.add_button(button_text, panel.close, Palette.button_primary)
	add_child(panel)
	return panel


func _big_button(text: String, color: Color, resume: bool) -> Button:
	var b := UIKit.button(text, Vector2(620, 170), 68, color)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): play_pressed.emit(resume))
	return b


func _wide_button(text: String, color: Color) -> Button:
	var b := UIKit.button(text.to_upper(), Vector2(700, 110), 40, color)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b
