extends Control

var selected_weapon: String = "sidearm"
var chosen_consumables: Dictionary = {}  # item_id -> count chosen
var weapon_buttons: Array[Button] = []
var consumable_labels: Dictionary = {}  # item_id -> Label
var slots_label: Label
var total_slots: int = 4

const STOCK_NAMES: Dictionary = {
	"field_stim": "Field Stim",
	"trap": "Trap",
}

func _ready() -> void:
	var contract: Dictionary = GameData.current_contract
	total_slots = 4 + SaveManager.data.ship_upgrades.get("loadout_slots", 0)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Hunt Loadout"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Contract: %s | Depth %d" % [contract.get("name", "Unknown"), contract.get("depth", 1)]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# Starting weapon section
	var weapon_title := Label.new()
	weapon_title.text = "Starting Weapon:"
	vbox.add_child(weapon_title)

	var weapon_row := HBoxContainer.new()
	weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(weapon_row)

	var unlocked: Array[String] = SaveManager.data.unlocked_weapons
	if unlocked.is_empty():
		unlocked = ["sidearm"]
	selected_weapon = unlocked[0]

	for wid in unlocked:
		var btn := Button.new()
		btn.text = wid.capitalize()
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_weapon_selected.bind(wid))
		weapon_row.add_child(btn)
		weapon_buttons.append(btn)

	_update_weapon_highlight()

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Consumables section
	var consumable_title := Label.new()
	consumable_title.text = "Consumables:"
	vbox.add_child(consumable_title)

	slots_label = Label.new()
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slots_label)
	_update_slots_label()

	var stock: Dictionary = SaveManager.data.stock
	for item_id in stock:
		if stock[item_id] <= 0:
			continue
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(row)

		var display_name: String = STOCK_NAMES.get(item_id, item_id.replace("_", " ").capitalize())
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		consumable_labels[item_id] = lbl

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(40, 40)
		minus_btn.pressed.connect(_on_consumable_change.bind(item_id, -1))
		row.add_child(minus_btn)

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(40, 40)
		plus_btn.pressed.connect(_on_consumable_change.bind(item_id, 1))
		row.add_child(plus_btn)

		chosen_consumables[item_id] = 0
		_update_consumable_label(item_id)

	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	# Credits
	var credits_lbl := Label.new()
	credits_lbl.text = "Credits: %d" % SaveManager.data.total_credits
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(credits_lbl)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(120, 60)
	back_btn.pressed.connect(_on_back)
	btn_row.add_child(back_btn)

	var go_btn := Button.new()
	go_btn.text = "GO HUNT"
	go_btn.custom_minimum_size = Vector2(120, 60)
	go_btn.pressed.connect(_on_go_hunt)
	btn_row.add_child(go_btn)

func _get_total_chosen() -> int:
	var total := 0
	for item_id in chosen_consumables:
		total += chosen_consumables[item_id]
	return total

func _update_slots_label() -> void:
	slots_label.text = "Slots: %d / %d" % [_get_total_chosen(), total_slots]

func _update_consumable_label(item_id: String) -> void:
	var display_name: String = STOCK_NAMES.get(item_id, item_id.replace("_", " ").capitalize())
	var stock_count: int = SaveManager.data.stock.get(item_id, 0)
	var chosen: int = chosen_consumables.get(item_id, 0)
	consumable_labels[item_id].text = "%s: %d chosen (stock: %d)" % [display_name, chosen, stock_count]

func _on_consumable_change(item_id: String, delta: int) -> void:
	var current: int = chosen_consumables.get(item_id, 0)
	var new_val: int = current + delta
	var stock_count: int = SaveManager.data.stock.get(item_id, 0)
	if new_val < 0:
		return
	if new_val > stock_count:
		return
	if delta > 0 and _get_total_chosen() >= total_slots:
		return
	chosen_consumables[item_id] = new_val
	_update_consumable_label(item_id)
	_update_slots_label()

func _on_weapon_selected(weapon_id: String) -> void:
	selected_weapon = weapon_id
	_update_weapon_highlight()

func _update_weapon_highlight() -> void:
	var unlocked: Array[String] = SaveManager.data.unlocked_weapons
	if unlocked.is_empty():
		unlocked = ["sidearm"]
	for i in weapon_buttons.size():
		var wid: String = unlocked[i]
		if wid == selected_weapon:
			weapon_buttons[i].text = "> %s <" % wid.capitalize()
			weapon_buttons[i].disabled = true
		else:
			weapon_buttons[i].text = wid.capitalize()
			weapon_buttons[i].disabled = false

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _on_go_hunt() -> void:
	GameData.starting_weapon = selected_weapon

	# Build loadout array and consume stock
	var loadout_arr: Array[Dictionary] = []
	for item_id in chosen_consumables:
		var count: int = chosen_consumables[item_id]
		for _i in count:
			loadout_arr.append({id=item_id})
			SaveManager.consume_stock(item_id)
	SaveManager.data.loadout = loadout_arr
	SaveManager.save_game()

	get_tree().change_scene_to_file("res://scenes/Hunt.tscn")
