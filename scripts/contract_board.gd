extends Control

var contracts: Array = []
var button_rects: Array = []
var refresh_rect: Rect2 = Rect2()
var back_rect: Rect2 = Rect2()

func _ready() -> void:
	contracts = GameData.generate_contracts(3)
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp_size), UITheme.BG_DARK)

	var y: float = 30.0
	var left: float = UITheme.MARGIN_LG
	var card_w: float = vp_size.x - left * 2

	# Title
	_dt(Vector2(left, y), "CONTRACT BOARD", UITheme.ACCENT_GOLD, UITheme.FONT_TITLE)
	y += 32.0

	# Stats
	var d := SaveManager.data
	_dt(Vector2(left, y), "%dcr  |  %d hunts" % [d.total_credits, d.contracts_completed], UITheme.TEXT_SECONDARY, UITheme.FONT_SMALL)
	y += 22.0

	# Separator
	draw_rect(Rect2(left, y, card_w, 2), UITheme.BORDER_DEFAULT)
	y += UITheme.MARGIN_SM

	_dt(Vector2(left, y), "Select a contract:", UITheme.TEXT_SECONDARY, UITheme.FONT_BODY)
	y += 24.0

	# Contract cards
	button_rects.clear()
	for i in contracts.size():
		var contract: Dictionary = contracts[i]
		var card_h: float = 120.0
		var card_rect := Rect2(left, y, card_w, card_h)
		button_rects.append(card_rect)

		# Card background with pixel border
		draw_rect(card_rect, UITheme.BG_MEDIUM)
		draw_rect(card_rect, UITheme.BORDER_DEFAULT, false, 2.0)

		# Accent stripe on left edge
		var icon_color: Color = contract.get("icon_color", UITheme.ACCENT_CYAN)
		draw_rect(Rect2(left, y, 4, card_h), icon_color)

		var cx: float = left + 16.0

		# Contract type label
		var type_label: String = contract.get("label", "Hunt")
		_dt(Vector2(cx, y + 6.0), type_label, icon_color, UITheme.FONT_TINY)

		# Contract name
		_dt(Vector2(cx, y + 22.0), contract.get("name", "Unknown"), UITheme.TEXT_PRIMARY, UITheme.FONT_HEADING)

		# Description
		var desc: String = contract.get("desc", "")
		_dt(Vector2(cx, y + 44.0), desc, UITheme.TEXT_SECONDARY, UITheme.FONT_SMALL)

		# Difficulty dots
		var difficulty: int = contract.get("difficulty", 1)
		for di in range(5):
			var dot_x: float = cx + di * 14.0
			var dot_color: Color = UITheme.ACCENT_ORANGE if di < difficulty else UITheme.BG_LIGHT
			draw_rect(Rect2(dot_x, y + 62.0, 8, 8), dot_color)

		# Reward
		_dt(Vector2(cx, y + 78.0), "%d cr" % contract.get("reward", 0), UITheme.ACCENT_GOLD, UITheme.FONT_BODY)

		# Special reward
		var special: String = contract.get("special_reward", "")
		if not special.is_empty():
			_dt(Vector2(cx, y + 96.0), special, UITheme.ACCENT_CYAN, UITheme.FONT_TINY)

		# Accept indicator on right side
		_dt(Vector2(left + card_w - 72.0, y + card_h * 0.5 - 8.0), "ACCEPT", UITheme.ACCENT_GREEN, UITheme.FONT_SMALL)

		y += card_h + UITheme.MARGIN_SM

	# Bottom buttons
	var btn_w: float = (card_w - 12.0) * 0.5
	var btn_h: float = 48.0
	var btn_y: float = y + UITheme.MARGIN_SM

	# Refresh button
	refresh_rect = Rect2(left, btn_y, btn_w, btn_h)
	draw_rect(refresh_rect, UITheme.BG_MEDIUM)
	draw_rect(refresh_rect, UITheme.ACCENT_CYAN, false, 2.0)
	_dt_center(refresh_rect, "REFRESH", UITheme.ACCENT_CYAN, UITheme.FONT_BODY)

	# Back button
	back_rect = Rect2(left + btn_w + 12.0, btn_y, btn_w, btn_h)
	draw_rect(back_rect, UITheme.BG_MEDIUM)
	draw_rect(back_rect, UITheme.BORDER_LIGHT, false, 2.0)
	_dt_center(back_rect, "RETURN", UITheme.TEXT_SECONDARY, UITheme.FONT_BODY)

func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return

	for i in button_rects.size():
		if button_rects[i].has_point(pos):
			GameData.set_current_contract(contracts[i])
			get_tree().change_scene_to_file("res://scenes/Loadout.tscn")
			return

	if refresh_rect.has_point(pos):
		contracts = GameData.generate_contracts(3)
		queue_redraw()
		return

	if back_rect.has_point(pos):
		get_tree().change_scene_to_file("res://scenes/ShipHub.tscn")

func _dt(pos: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _dt_center(rect: Rect2, text: String, color: Color, font_size: int = 14) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x: float = rect.position.x + (rect.size.x - text_width) * 0.5
	var y: float = rect.position.y + (rect.size.y + font_size) * 0.5 - 4.0
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
