extends Control

# Tab containers built in _ready
var ship_tab_content: VBoxContainer
var upgrades_tab_content: VBoxContainer
var stats_label: Label
var pantry_label: Label
var cook_status_label: Label
var credits_label: Label

# Tab buttons
var ship_tab_btn: Button
var upgrades_tab_btn: Button

# Upgrade shop buttons (for refresh)
var upgrade_buttons: Array[Button] = []
var upgrade_labels: Array[Label] = []

const UPGRADE_DEFS: Array[Dictionary] = [
	{id="max_hp", name="Reinforced Hull", desc="Max HP +2", cost=80, max_level=3},
	{id="mag_size", name="Extended Magazine", desc="Mag Size +3", cost=60, max_level=3},
	{id="xp_rate", name="Void Attunement", desc="XP Rate +10%", cost=50, max_level=3},
	{id="loadout_slots", name="Extra Loadout Slot", desc="+1 slot", cost=100, max_level=2},
]

const WEAPON_UNLOCK_DEFS: Array[Dictionary] = [
	{id="scatter", name="Unlock Scatter Pistol", desc="Starting weapon", cost=120},
	{id="lance", name="Unlock Void Lance", desc="Starting weapon", cost=150},
	{id="baton", name="Unlock Shock Baton", desc="Starting weapon", cost=130},
	{id="dart", name="Unlock Homing Dart", desc="Starting weapon", cost=80},
]

func _ready() -> void:
	var margin: MarginContainer = $MarginContainer
	var vbox: VBoxContainer = $MarginContainer/VBoxContainer

	# Clear existing children from vbox (scene nodes)
	for child in vbox.get_children():
		child.queue_free()

	# Title
	var title := Label.new()
	title.text = "The Wanderer — Your Ship"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Stats
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tab_bar)

	ship_tab_btn = Button.new()
	ship_tab_btn.text = "SHIP"
	ship_tab_btn.custom_minimum_size = Vector2(120, 40)
	ship_tab_btn.pressed.connect(_show_ship_tab)
	tab_bar.add_child(ship_tab_btn)

	upgrades_tab_btn = Button.new()
	upgrades_tab_btn.text = "UPGRADES"
	upgrades_tab_btn.custom_minimum_size = Vector2(120, 40)
	upgrades_tab_btn.pressed.connect(_show_upgrades_tab)
	tab_bar.add_child(upgrades_tab_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# === SHIP TAB CONTENT ===
	ship_tab_content = VBoxContainer.new()
	ship_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(ship_tab_content)

	var pantry_title := Label.new()
	pantry_title.text = "Pantry"
	pantry_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(pantry_title)

	pantry_label = Label.new()
	pantry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(pantry_label)

	var sep2 := HSeparator.new()
	ship_tab_content.add_child(sep2)

	var contract_button := Button.new()
	contract_button.text = "Contract Board"
	contract_button.custom_minimum_size = Vector2(0, 60)
	contract_button.pressed.connect(_on_contract_board)
	ship_tab_content.add_child(contract_button)

	var cook_button := Button.new()
	cook_button.text = "Cook"
	cook_button.custom_minimum_size = Vector2(0, 60)
	cook_button.pressed.connect(_on_cook)
	ship_tab_content.add_child(cook_button)

	cook_status_label = Label.new()
	cook_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cook_status_label.text = ""
	ship_tab_content.add_child(cook_status_label)

	# === UPGRADES TAB CONTENT ===
	upgrades_tab_content = VBoxContainer.new()
	upgrades_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(upgrades_tab_content)

	credits_label = Label.new()
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_tab_content.add_child(credits_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	upgrades_tab_content.add_child(scroll)

	var shop_vbox := VBoxContainer.new()
	shop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(shop_vbox)

	# Ship upgrades
	for def in UPGRADE_DEFS:
		var row := _make_upgrade_row(def)
		shop_vbox.add_child(row)

	# Weapon unlocks
	for def in WEAPON_UNLOCK_DEFS:
		var row := _make_weapon_unlock_row(def)
		shop_vbox.add_child(row)

	# Start on ship tab
	_update_stats()
	_update_pantry()
	_show_ship_tab()

func _make_upgrade_row(def: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	upgrade_labels.append(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 40)
	btn.pressed.connect(_on_buy_upgrade.bind(def.id, def.cost))
	row.add_child(btn)
	upgrade_buttons.append(btn)

	_update_upgrade_label(lbl, btn, def)
	return row

func _make_weapon_unlock_row(def: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	upgrade_labels.append(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 40)
	btn.pressed.connect(_on_buy_weapon.bind(def.id, def.cost))
	row.add_child(btn)
	upgrade_buttons.append(btn)

	_update_weapon_label(lbl, btn, def)
	return row

func _update_upgrade_label(lbl: Label, btn: Button, def: Dictionary) -> void:
	var level: int = SaveManager.data.ship_upgrades.get(def.id, 0)
	var maxed: bool = level >= def.max_level
	lbl.text = "[%s] %s  Lv %d/%d  Cost: %dcr" % [def.name, def.desc, level, def.max_level, def.cost]
	if maxed:
		btn.text = "MAX"
		btn.disabled = true
	elif SaveManager.data.total_credits < def.cost:
		btn.text = "Buy"
		btn.disabled = true
	else:
		btn.text = "Buy"
		btn.disabled = false

func _update_weapon_label(lbl: Label, btn: Button, def: Dictionary) -> void:
	var owned: bool = SaveManager.data.unlocked_weapons.has(def.id)
	lbl.text = "[%s] %s  Cost: %dcr" % [def.name, def.desc, def.cost]
	if owned:
		btn.text = "OWNED"
		btn.disabled = true
	elif SaveManager.data.total_credits < def.cost:
		btn.text = "Buy"
		btn.disabled = true
	else:
		btn.text = "Buy"
		btn.disabled = false

func _refresh_shop() -> void:
	var idx := 0
	for def in UPGRADE_DEFS:
		_update_upgrade_label(upgrade_labels[idx], upgrade_buttons[idx], def)
		idx += 1
	for def in WEAPON_UNLOCK_DEFS:
		_update_weapon_label(upgrade_labels[idx], upgrade_buttons[idx], def)
		idx += 1
	credits_label.text = "Credits: %d" % SaveManager.data.total_credits
	_update_stats()

func _on_buy_upgrade(upgrade_id: String, cost: int) -> void:
	SaveManager.buy_upgrade(upgrade_id, cost)
	_refresh_shop()

func _on_buy_weapon(weapon_id: String, cost: int) -> void:
	if SaveManager.data.total_credits < cost:
		return
	if SaveManager.data.unlocked_weapons.has(weapon_id):
		return
	SaveManager.data.total_credits -= cost
	SaveManager.data.unlocked_weapons.append(weapon_id)
	SaveManager.save_game()
	_refresh_shop()

func _show_ship_tab() -> void:
	ship_tab_content.visible = true
	upgrades_tab_content.visible = false
	ship_tab_btn.disabled = true
	upgrades_tab_btn.disabled = false

func _show_upgrades_tab() -> void:
	ship_tab_content.visible = false
	upgrades_tab_content.visible = true
	ship_tab_btn.disabled = false
	upgrades_tab_btn.disabled = true
	_refresh_shop()

func _update_stats() -> void:
	var d := SaveManager.data
	stats_label.text = "Credits: %d | Corruption: %d | Contracts: %d" % [
		d.total_credits, d.total_corruption, d.contracts_completed
	]

func _update_pantry() -> void:
	var pantry: Dictionary = SaveManager.data.ingredients
	var text := ""
	if pantry.is_empty():
		text = "  (empty — hunt creatures to collect ingredients)"
	else:
		for ing_id in pantry:
			var display_name: String = ing_id.replace("_", " ").capitalize()
			text += "  %s: %d\n" % [display_name, pantry[ing_id]]
	pantry_label.text = text.strip_edges()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _on_cook() -> void:
	cook_status_label.text = "Kitchen coming soon"
