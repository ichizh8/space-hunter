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

	# Persist ingredients
	if not ingredients.is_empty():
		SaveManager.add_ingredients(ingredients)

	# Build the full results UI dynamically via _draw
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	var result := GameData.hunt_result

	# Background
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.06, 0.06, 0.1))

	var font: Font = ThemeDB.fallback_font
	var y: float = 20.0
	var left: float = 24.0
	var right_col: float = vp_size.x - 24.0

	# --- Header: contract name + result badge ---
	var contract_name: String = result.get("contract_name", "Hunt")
	var hunt_status: String = result.get("hunt_status", "COMPLETED")
	var badge_color: Color
	match hunt_status:
		"COMPLETED": badge_color = Color(0.2, 0.9, 0.2)
		"FAILED": badge_color = Color(0.9, 0.2, 0.2)
		_: badge_color = Color(0.6, 0.6, 0.6)

	_dt(Vector2(left, y), contract_name, Color.WHITE, 18)
	y += 26.0
	_dt(Vector2(left, y), hunt_status, badge_color, 22)
	y += 34.0

	# Separator
	draw_line(Vector2(left, y), Vector2(right_col, y), Color(0.3, 0.3, 0.4), 1.0)
	y += 10.0

	# --- Stats block ---
	_dt(Vector2(left, y), "STATS", Color(0.7, 0.7, 0.8), 13)
	y += 20.0

	var time_s: float = result.get("time_survived", 0.0)
	var minutes: int = int(time_s) / 60
	var seconds: int = int(time_s) % 60
	_stat_row(left, y, "Time survived", "%d:%02d" % [minutes, seconds])
	y += 18.0

	var total_kills: int = result.get("total_kills", 0)
	_stat_row(left, y, "Enemies killed", str(total_kills))
	y += 18.0

	var elite_kills: int = result.get("elite_kills", 0)
	_stat_row(left, y, "Elite kills", str(elite_kills))
	y += 18.0

	var apex_kills: int = result.get("apex_kills", 0)
	_stat_row(left, y, "Apex kills", str(apex_kills))
	y += 18.0

	var peak_c: int = result.get("peak_corruption", 0)
	var peak_name: String = CORRUPTION_NAMES[clampi(peak_c, 0, 3)]
	var peak_color: Color = CORRUPTION_COLORS[clampi(peak_c, 0, 3)]
	_stat_row_color(left, y, "Peak corruption", peak_name, peak_color)
	y += 18.0

	var dmg_dealt: int = result.get("damage_dealt", 0)
	var dmg_taken: int = result.get("damage_taken", 0)
	_stat_row(left, y, "Damage dealt", str(dmg_dealt))
	y += 18.0
	_stat_row(left, y, "Damage taken", str(dmg_taken))
	y += 24.0

	# Separator
	draw_line(Vector2(left, y), Vector2(right_col, y), Color(0.3, 0.3, 0.4), 1.0)
	y += 10.0

	# --- Score breakdown ---
	_dt(Vector2(left, y), "SCORE", Color(0.7, 0.7, 0.8), 13)
	y += 20.0

	var base_score: int = total_kills * 10
	_score_row(left, y, "Base (kills x10)", base_score)
	y += 18.0

	var elite_bonus: int = elite_kills * 150
	_score_row(left, y, "Elite bonus (x150)", elite_bonus)
	y += 18.0

	var apex_bonus: int = apex_kills * 500
	_score_row(left, y, "Apex bonus (x500)", apex_bonus)
	y += 18.0

	var contract_bonus: int = 500 if hunt_status == "COMPLETED" else 0
	_score_row(left, y, "Contract bonus", contract_bonus)
	y += 18.0

	var subtotal: int = base_score + elite_bonus + apex_bonus + contract_bonus

	# Time bonus
	var par_time: float = result.get("par_time", 300.0)
	var time_bonus: int = 0
	if time_s > 0.0 and time_s < par_time:
		time_bonus = int(base_score * 0.2)
	_score_row(left, y, "Time bonus (+20%)", time_bonus)
	y += 18.0

	# Corruption bonus
	var corr_bonus: int = 0
	var corr_desc: String = ""
	if peak_c == 0:
		corr_bonus = int(base_score * 0.3)
		corr_desc = "Never left CLEAN (+30%)"
	elif peak_c >= 3 and hunt_status == "COMPLETED":
		corr_bonus = int(base_score * 0.25)
		corr_desc = "VOID survivor (+25%)"
	elif peak_c >= 3 and hunt_status == "ABANDONED":
		corr_bonus = int(base_score * 0.5)
		corr_desc = "VOID extracted (+50%)"
	if corr_desc != "":
		_score_row(left, y, corr_desc, corr_bonus)
	else:
		_score_row(left, y, "Corruption bonus", 0)
	y += 22.0

	var total_score: int = subtotal + time_bonus + corr_bonus
	if hunt_status == "ABANDONED":
		total_score = int(total_score * 0.5)

	# TOTAL
	_dt(Vector2(left, y), "TOTAL", Color(1.0, 0.9, 0.3), 16)
	_dt(Vector2(right_col - 80.0, y), str(total_score), Color(1.0, 0.9, 0.3), 16)
	y += 28.0

	# Separator
	draw_line(Vector2(left, y), Vector2(right_col, y), Color(0.3, 0.3, 0.4), 1.0)
	y += 10.0

	# --- Loot section ---
	var ingredients: Array = result.get("ingredients", [])
	if not ingredients.is_empty():
		_dt(Vector2(left, y), "LOOT", Color(0.7, 0.7, 0.8), 13)
		y += 20.0
		# Aggregate by type
		var loot_counts: Dictionary = {}
		for ing in ingredients:
			var iname: String = ing.get("name", "Unknown")
			loot_counts[iname] = loot_counts.get(iname, 0) + 1
		for iname in loot_counts:
			_stat_row(left, y, iname, "x%d" % loot_counts[iname])
			y += 16.0
		y += 8.0
	else:
		_dt(Vector2(left, y), "LOOT: (none)", Color(0.5, 0.5, 0.5), 13)
		y += 24.0

	# --- Credits earned ---
	var credits: int = result.get("credits", 0)
	_dt(Vector2(left, y), "Credits earned: %d" % credits, Color(0.9, 0.8, 0.2), 14)
	y += 24.0

	# --- Buttons ---
	var btn_w: float = (vp_size.x - 60.0) * 0.5
	var btn_h: float = 50.0
	var btn_y: float = vp_size.y - 80.0
	_draw_button_rect = [
		Rect2(left, btn_y, btn_w, btn_h),
		Rect2(left + btn_w + 12.0, btn_y, btn_w, btn_h),
	]
	draw_rect(_draw_button_rect[0], Color(0.15, 0.4, 0.15, 0.9))
	_dt(_draw_button_rect[0].position + Vector2(12.0, 12.0), "Cook & Upgrade", Color.WHITE, 15)
	draw_rect(_draw_button_rect[1], Color(0.15, 0.25, 0.5, 0.9))
	_dt(_draw_button_rect[1].position + Vector2(12.0, 12.0), "New Contract", Color.WHITE, 15)

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

func _stat_row(x: float, y: float, label: String, value: String) -> void:
	_dt(Vector2(x, y), label, Color(0.7, 0.7, 0.7), 13)
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), value, Color.WHITE, 13)

func _stat_row_color(x: float, y: float, label: String, value: String, color: Color) -> void:
	_dt(Vector2(x, y), label, Color(0.7, 0.7, 0.7), 13)
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), value, color, 13)

func _score_row(x: float, y: float, label: String, value: int) -> void:
	_dt(Vector2(x, y), label, Color(0.6, 0.6, 0.7), 12)
	var val_str: String = "+%d" % value if value > 0 else "0"
	var val_color: Color = Color(0.9, 0.9, 0.3) if value > 0 else Color(0.5, 0.5, 0.5)
	_dt(Vector2(get_viewport_rect().size.x - 100.0, y), val_str, val_color, 12)
