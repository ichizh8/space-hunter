extends Control

var contracts: Array[Dictionary] = []
var button_rects: Array[Rect2] = []
var refresh_rect: Rect2 = Rect2()
var back_rect: Rect2 = Rect2()

func _ready() -> void:
	contracts = GameData.generate_contracts(3)
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.06, 0.06, 0.1))

	var font: Font = ThemeDB.fallback_font
	var y: float = 30.0
	var left: float = 20.0
	var card_w: float = vp_size.x - 40.0

	# Title
	_dt(Vector2(left, y), "CONTRACT BOARD", Color.WHITE, 20)
	y += 28.0

	# Stats
	var d := SaveManager.data
	_dt(Vector2(left, y), "Credits: %d | Contracts: %d" % [d.total_credits, d.contracts_completed], Color(0.6, 0.6, 0.7), 12)
	y += 22.0

	draw_line(Vector2(left, y), Vector2(left + card_w, y), Color(0.3, 0.3, 0.4), 1.0)
	y += 10.0

	_dt(Vector2(left, y), "Select a contract:", Color(0.7, 0.7, 0.8), 13)
	y += 22.0

	# Contract cards
	button_rects.clear()
	for i in contracts.size():
		var contract: Dictionary = contracts[i]
		var card_h: float = 110.0
		var card_rect := Rect2(left, y, card_w, card_h)
		button_rects.append(card_rect)

		# Card background
		draw_rect(card_rect, Color(0.1, 0.1, 0.15, 0.9))
		draw_rect(card_rect, Color(0.3, 0.3, 0.4), false, 1.0)

		# Icon circle (left side)
		var icon_color: Color = contract.get("icon_color", Color.WHITE)
		var icon_center := Vector2(left + 25.0, y + card_h * 0.5)
		draw_circle(icon_center, 14.0, icon_color)

		# Contract type label
		var type_label: String = contract.get("label", "Hunt")
		_dt(Vector2(left + 48.0, y + 4.0), type_label, icon_color, 11)

		# Contract name
		_dt(Vector2(left + 48.0, y + 20.0), contract.get("name", "Unknown"), Color.WHITE, 14)

		# Description
		var desc: String = contract.get("desc", "")
		_dt(Vector2(left + 48.0, y + 40.0), desc, Color(0.6, 0.6, 0.7), 11)

		# Difficulty stars
		var difficulty: int = contract.get("difficulty", 1)
		var stars: String = ""
		for _s in difficulty:
			stars += "* "
		_dt(Vector2(left + 48.0, y + 56.0), "Difficulty: %s" % stars.strip_edges(), Color(0.9, 0.8, 0.2), 11)

		# Reward
		_dt(Vector2(left + 48.0, y + 72.0), "Reward: %d cr" % contract.get("reward", 0), Color(0.9, 0.8, 0.2), 12)

		# Special reward
		var special: String = contract.get("special_reward", "")
		if not special.is_empty():
			_dt(Vector2(left + 48.0, y + 88.0), special, Color(0.4, 0.8, 1.0), 10)

		# Accept label
		_dt(Vector2(left + card_w - 70.0, y + card_h * 0.5 - 8.0), "ACCEPT", Color(0.3, 0.9, 0.3), 13)

		y += card_h + 10.0

	# Refresh button
	var btn_w: float = (card_w - 12.0) * 0.5
	var btn_h: float = 44.0
	refresh_rect = Rect2(left, y + 8.0, btn_w, btn_h)
	draw_rect(refresh_rect, Color(0.2, 0.2, 0.4, 0.9))
	_dt(refresh_rect.position + Vector2(btn_w * 0.5 - 35.0, 10.0), "REFRESH", Color.WHITE, 15)

	# Back button
	back_rect = Rect2(left + btn_w + 12.0, y + 8.0, btn_w, btn_h)
	draw_rect(back_rect, Color(0.3, 0.2, 0.15, 0.9))
	_dt(back_rect.position + Vector2(btn_w * 0.5 - 55.0, 10.0), "RETURN TO SHIP", Color.WHITE, 15)

func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return

	# Check contract buttons
	for i in button_rects.size():
		if button_rects[i].has_point(pos):
			GameData.set_current_contract(contracts[i])
			get_tree().change_scene_to_file("res://scenes/Loadout.tscn")
			return

	# Refresh
	if refresh_rect.has_point(pos):
		contracts = GameData.generate_contracts(3)
		queue_redraw()
		return

	# Back
	if back_rect.has_point(pos):
		get_tree().change_scene_to_file("res://scenes/ShipHub.tscn")

func _dt(pos: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
