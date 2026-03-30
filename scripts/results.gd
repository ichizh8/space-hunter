extends Control

const CORRUPTION_NAMES: Array = ["CLEAN", "VALLEY", "CORRUPT", "VOID"]
const CORRUPTION_COLORS: Array = [
	Color(0.3, 0.9, 0.3),
	Color(0.9, 0.8, 0.2),
	Color(0.9, 0.3, 0.2),
	Color(1.0, 0.1, 0.1),
]

func _ready() -> void:
	var result := GameData.hunt_result
	var ingredients: Array = result.get("ingredients", [])
	if not ingredients.is_empty():
		SaveManager.add_ingredients(ingredients)
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	var result := GameData.hunt_result
	var left: float = UITheme.MARGIN_LG
	var right_col: float = vp_size.x - left
	var card_w: float = right_col - left

	# Background
	draw_rect(Rect2(Vector2.ZERO, vp_size), UITheme.BG_DARK)

	var y: float = 24.0

	# Header: contract name + result badge
	var contract_name: String = result.get("contract_name", "Hunt")
	var hunt_status: String = result.get("hunt_status", "COMPLETED")
	var badge_color: Color
	match hunt_status:
		"COMPLETED": badge_color = UITheme.ACCENT_GREEN
		"FAILED": badge_color = UITheme.ACCENT_RED
		_: badge_color = UITheme.TEXT_SECONDARY

	_dt(Vector2(left, y), contract_name, UITheme.TEXT_PRIMARY, UITheme.FONT_HEADING)
	y += 26.0
	_dt(Vector2(left, y), hunt_status, badge_color, UITheme.FONT_TITLE)
	y += 34.0

	# Separator
	draw_rect(Rect2(left, y, card_w, 2), UITheme.BORDER_DEFAULT)
	y += UITheme.MARGIN_SM

	# Stats block
	_dt(Vector2(left, y), "STATS", UITheme.ACCENT_CYAN, UITheme.FONT_SMALL)
	y += 22.0

	var time_s: float = result.get("time_survived", 0.0)
	var minutes: int = int(time_s) / 60
	var seconds: int = int(time_s) % 60
	_stat_row(left, y, "Time survived", "%d:%02d" % [minutes, seconds])
	y += 20.0

	var total_kills: int = result.get("total_kills", 0)
	_stat_row(left, y, "Enemies killed", str(total_kills))
	y += 20.0

	var elite_kills: int = result.get("elite_kills", 0)
	_stat_row(left, y, "Elite kills", str(elite_kills))
	y += 20.0

	var apex_kills: int = result.get("apex_kills", 0)
	_stat_row(left, y, "Apex kills", str(apex_kills))
	y += 20.0

	var peak_c: float = result.get("peak_corruption", 0.0)
	var peak_idx: int = 0
	if peak_c >= 70.0: peak_idx = 3
	elif peak_c >= 36.0: peak_idx = 2
	elif peak_c >= 16.0: peak_idx = 1
	var peak_name: String = CORRUPTION_NAMES[peak_idx]
	var peak_color: Color = CORRUPTION_COLORS[peak_idx]
	_stat_row_color(left, y, "Peak corruption", "%s (%.0f)" % [peak_name, peak_c], peak_color)
	y += 20.0

	var dmg_dealt: int = result.get("damage_dealt", 0)
	var dmg_taken: int = result.get("damage_taken", 0)
	_stat_row(left, y, "Damage dealt", str(dmg_dealt))
	y += 20.0
	_stat_row(left, y, "Damage taken", str(dmg_taken))
	y += 26.0

	# Separator
	draw_rect(Rect2(left, y, card_w, 2), UITheme.BORDER_DEFAULT)
	y += UITheme.MARGIN_SM

	# Score breakdown
	_dt(Vector2(left, y), "SCORE", UITheme.ACCENT_GOLD, UITheme.FONT_SMALL)
	y += 22.0

	var base_score: int = total_kills * 10
	_score_row(left, y, "Base (kills x10)", base_score)
	y += 20.0

	var elite_bonus: int = elite_kills * 150
	_score_row(left, y, "Elite bonus (x150)", elite_bonus)
	y += 20.0

	var apex_bonus: int = apex_kills * 500
	_score_row(left, y, "Apex bonus (x500)", apex_bonus)
	y += 20.0

	var contract_bonus: int = 500 if hunt_status == "COMPLETED" else 0
	_score_row(left, y, "Contract bonus", contract_bonus)
	y += 20.0

	var subtotal: int = base_score + elite_bonus + apex_bonus + contract_bonus

	# Time bonus
	var par_time: float = result.get("par_time", 300.0)
	var time_bonus: int = 0
	if time_s > 0.0 and time_s < par_time:
		time_bonus = int(base_score * 0.2)
	_score_row(left, y, "Time bonus (+20%)", time_bonus)
	y += 20.0

	# Corruption bonus
	var corr_bonus: int = 0
	var corr_desc: String = ""
	if peak_c < 16.0:
		corr_bonus = int(base_score * 0.3)
		corr_desc = "Never left CLEAN (+30%)"
	elif peak_c >= 70.0 and hunt_status == "COMPLETED":
		corr_bonus = int(base_score * 0.25)
		corr_desc = "VOID survivor (+25%)"
	elif peak_c >= 70.0 and hunt_status == "ABANDONED":
		corr_bonus = int(base_score * 0.5)
		corr_desc = "VOID extracted (+50%)"
	if corr_desc != "":
		_score_row(left, y, corr_desc, corr_bonus)
	else:
		_score_row(left, y, "Corruption bonus", 0)
	y += 24.0

	var total_score: int = subtotal + time_bonus + corr_bonus
	if hunt_status == "ABANDONED":
		total_score = int(total_score * 0.5)

	# Total score
	_dt(Vector2(left, y), "TOTAL", UITheme.ACCENT_GOLD, UITheme.FONT_HEADING)
	_dt(Vector2(right_col - 80.0, y), str(total_score), UITheme.ACCENT_GOLD, UITheme.FONT_HEADING)
	y += 30.0

	# Separator
	draw_rect(Rect2(left, y, card_w, 2), UITheme.BORDER_DEFAULT)
	y += UITheme.MARGIN_SM

	# Loot section
	var ingredients: Array = result.get("ingredients", [])
	if not ingredients.is_empty():
		_dt(Vector2(left, y), "LOOT", UITheme.ACCENT_ORANGE, UITheme.FONT_SMALL)
		y += 22.0
		var loot_counts: Dictionary = {}
		for ing in ingredients:
			var iname: String = ing.get("name", "Unknown")
			loot_counts[iname] = loot_counts.get(iname, 0) + 1
		for iname in loot_counts:
			_stat_row(left, y, iname, "x%d" % loot_counts[iname])
			y += 18.0
		y += UITheme.MARGIN_SM
	else:
		_dt(Vector2(left, y), "LOOT: (none)", UITheme.TEXT_MUTED, UITheme.FONT_SMALL)
		y += 24.0

	# Credits earned
	_dt(Vector2(left, y), "Credits earned: %d" % result.get("credits", 0), UITheme.ACCENT_GOLD, UITheme.FONT_BODY)
	y += 28.0

	# Bottom buttons
	var btn_w: float = (card_w - 12.0) * 0.5
	var btn_h: float = 52.0
	var btn_y: float = vp_size.y - 76.0
	_draw_button_rect = [
		Rect2(left, btn_y, btn_w, btn_h),
		Rect2(left + btn_w + 12.0, btn_y, btn_w, btn_h),
	]

	# Cook & Upgrade button
	draw_rect(_draw_button_rect[0], UITheme.BG_MEDIUM)
	draw_rect(_draw_button_rect[0], UITheme.ACCENT_GREEN, false, 2.0)
	_dt_center(_draw_button_rect[0], "Cook & Upgrade", UITheme.ACCENT_GREEN, UITheme.FONT_BODY)

	# New Contract button
	draw_rect(_draw_button_rect[1], UITheme.BG_MEDIUM)
	draw_rect(_draw_button_rect[1], UITheme.ACCENT_CYAN, false, 2.0)
	_dt_center(_draw_button_rect[1], "New Contract", UITheme.ACCENT_CYAN, UITheme.FONT_BODY)

var _draw_button_rect: Array = []

func _input(event: InputEvent) -> void:
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	else:
		return

	if _draw_button_rect.size() < 2:
		return
	if _draw_button_rect[0].has_point(pos):
		get_tree().change_scene_to_file("res://scenes/ShipHub.tscn")
	elif _draw_button_rect[1].has_point(pos):
		get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _dt(pos: Vector2, text: String, color: Color, font_size: int = 14) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _dt_center(rect: Rect2, text: String, color: Color, font_size: int = 14) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x: float = rect.position.x + (rect.size.x - text_width) * 0.5
	var y: float = rect.position.y + (rect.size.y + font_size) * 0.5 - 4.0
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _stat_row(x: float, y: float, label: String, value: String) -> void:
	_dt(Vector2(x, y), label, UITheme.TEXT_SECONDARY, UITheme.FONT_SMALL)
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), value, UITheme.TEXT_PRIMARY, UITheme.FONT_SMALL)

func _stat_row_color(x: float, y: float, label: String, value: String, color: Color) -> void:
	_dt(Vector2(x, y), label, UITheme.TEXT_SECONDARY, UITheme.FONT_SMALL)
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), value, color, UITheme.FONT_SMALL)

func _score_row(x: float, y: float, label: String, value: int) -> void:
	_dt(Vector2(x, y), label, UITheme.TEXT_MUTED, UITheme.FONT_SMALL)
	var val_str: String = "+%d" % value if value > 0 else "0"
	var val_color: Color = UITheme.ACCENT_GOLD if value > 0 else UITheme.TEXT_MUTED
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), val_str, val_color, UITheme.FONT_SMALL)
