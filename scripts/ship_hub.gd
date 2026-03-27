extends Control

# Tab containers built in _ready
var ship_tab_content: VBoxContainer
var upgrades_tab_content: VBoxContainer
var kits_tab_content: VBoxContainer
var stats_label: Label
var pantry_label: Label
var cook_status_label: Label
var credits_label: Label
var kits_credits_label: Label
var kits_equipped_label: Label
var kits_scroll_vbox: VBoxContainer

# Tab buttons
var ship_tab_btn: Button
var upgrades_tab_btn: Button
var kits_tab_btn: Button

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
	{id="pulse_cannon", name="Unlock Pulse Cannon", desc="Starting weapon", cost=180},
	{id="chain_rifle", name="Unlock Chain Rifle", desc="Starting weapon", cost=160},
]

const KIT_NAMES: Dictionary = {
	"stim_pack": "Stim Pack",
	"flash_trap": "Flash Trap",
	"blink_kit": "Blink",
	"chain_kit": "Chain",
	"charge_kit": "Charge",
	"mirage_kit": "Mirage",
	"turret_kit": "Turret",
	"smoke_kit": "Smoke",
	"anchor_kit": "Anchor",
	"drone_kit": "Drone",
	"familiar_kit": "Familiar",
	"pack_kit": "Pack",
	"void_surge": "Void Surge",
	"rupture_kit": "Rupture",
}

const KIT_DESCS: Dictionary = {
	"stim_pack": "Heal HP, gain corruption",
	"flash_trap": "Stun trap, 2 charges",
	"blink_kit": "Teleport 200px",
	"chain_kit": "Tether enemy 3s",
	"charge_kit": "Knockback blast",
	"mirage_kit": "Decoy draws aggro",
	"turret_kit": "Auto-turret",
	"smoke_kit": "Smoke screen",
	"anchor_kit": "Gravity pull",
	"drone_kit": "Intercept bullets",
	"familiar_kit": "Void familiar",
	"pack_kit": "Summon allies",
	"void_surge": "Speed burst",
	"rupture_kit": "Corruption AOE",
}

const KIT_UNLOCK_COSTS: Dictionary = {
	"stim_pack": 0, "flash_trap": 0,
	"blink_kit": 120, "chain_kit": 150, "charge_kit": 120, "mirage_kit": 180,
	"turret_kit": 150, "smoke_kit": 100, "anchor_kit": 180,
	"drone_kit": 200, "familiar_kit": 160, "pack_kit": 180,
	"void_surge": 220, "rupture_kit": 250,
}

const KIT_TIER_COSTS: Dictionary = {
	"stim_pack": [0,60,120], "flash_trap": [0,80,160],
	"blink_kit": [120,100,200], "chain_kit": [150,120,220], "charge_kit": [120,100,200],
	"mirage_kit": [180,140,260], "turret_kit": [150,120,220], "smoke_kit": [100,80,180],
	"anchor_kit": [180,150,280], "drone_kit": [200,150,300], "familiar_kit": [160,130,250],
	"pack_kit": [180,150,280], "void_surge": [220,180,320], "rupture_kit": [250,200,380],
}

const ALL_KIT_IDS: Array[String] = [
	"stim_pack", "flash_trap", "blink_kit", "chain_kit", "charge_kit",
	"mirage_kit", "turret_kit", "smoke_kit", "anchor_kit", "drone_kit",
	"familiar_kit", "pack_kit", "void_surge", "rupture_kit",
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
	ship_tab_btn.custom_minimum_size = Vector2(100, 40)
	ship_tab_btn.pressed.connect(_show_ship_tab)
	tab_bar.add_child(ship_tab_btn)

	upgrades_tab_btn = Button.new()
	upgrades_tab_btn.text = "UPGRADES"
	upgrades_tab_btn.custom_minimum_size = Vector2(100, 40)
	upgrades_tab_btn.pressed.connect(_show_upgrades_tab)
	tab_bar.add_child(upgrades_tab_btn)

	kits_tab_btn = Button.new()
	kits_tab_btn.text = "KITS"
	kits_tab_btn.custom_minimum_size = Vector2(100, 40)
	kits_tab_btn.pressed.connect(_show_kits_tab)
	tab_bar.add_child(kits_tab_btn)

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

	# === KITS TAB CONTENT ===
	kits_tab_content = VBoxContainer.new()
	kits_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(kits_tab_content)

	kits_credits_label = Label.new()
	kits_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kits_tab_content.add_child(kits_credits_label)

	kits_equipped_label = Label.new()
	kits_equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kits_tab_content.add_child(kits_equipped_label)

	var kits_sep := HSeparator.new()
	kits_tab_content.add_child(kits_sep)

	var kits_scroll := ScrollContainer.new()
	kits_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kits_scroll.custom_minimum_size = Vector2(0, 300)
	kits_tab_content.add_child(kits_scroll)

	kits_scroll_vbox = VBoxContainer.new()
	kits_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kits_scroll.add_child(kits_scroll_vbox)

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

func _build_kits_list() -> void:
	# Clear existing kit rows
	for child in kits_scroll_vbox.get_children():
		child.queue_free()

	kits_credits_label.text = "Credits: %d" % SaveManager.data.total_credits
	var eq: Array[String] = SaveManager.data.equipped_kits
	if eq.is_empty():
		eq = ["stim_pack", "flash_trap"]
	var slot1_name: String = KIT_NAMES.get(eq[0], eq[0]) if eq.size() > 0 else "None"
	var slot2_name: String = KIT_NAMES.get(eq[1], eq[1]) if eq.size() > 1 else "None"
	kits_equipped_label.text = "Slot 1: %s  |  Slot 2: %s" % [slot1_name, slot2_name]

	for kit_id in ALL_KIT_IDS:
		var owned: bool = SaveManager.data.unlocked_kits.has(kit_id)
		var tier: int = SaveManager.data.kit_tiers.get(kit_id, 0)
		var kit_name: String = KIT_NAMES.get(kit_id, kit_id)
		var kit_desc: String = KIT_DESCS.get(kit_id, "")
		var t3_choice: String = SaveManager.data.kit_t3_choices.get(kit_id, "")

		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		# Kit name and info
		var info_lbl := Label.new()
		if owned:
			info_lbl.text = "%s (T%d) - %s" % [kit_name, tier, kit_desc]
		else:
			info_lbl.text = "%s - %s" % [kit_name, kit_desc]
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info_lbl)

		# Action buttons
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		row.add_child(btn_row)

		if not owned:
			var cost: int = KIT_UNLOCK_COSTS.get(kit_id, 999)
			var unlock_btn := Button.new()
			unlock_btn.text = "Unlock (%dcr)" % cost
			unlock_btn.custom_minimum_size = Vector2(120, 36)
			unlock_btn.disabled = SaveManager.data.total_credits < cost
			unlock_btn.pressed.connect(_on_kit_unlock.bind(kit_id, cost))
			btn_row.add_child(unlock_btn)
		else:
			if tier < 2:
				var costs: Array = KIT_TIER_COSTS.get(kit_id, [0, 100, 200])
				var t2_cost: int = costs[1] if costs.size() > 1 else 100
				var t2_btn := Button.new()
				t2_btn.text = "Upgrade T2 (%dcr)" % t2_cost
				t2_btn.custom_minimum_size = Vector2(140, 36)
				t2_btn.disabled = SaveManager.data.total_credits < t2_cost
				t2_btn.pressed.connect(_on_kit_tier_upgrade.bind(kit_id, 2, t2_cost))
				btn_row.add_child(t2_btn)
			elif tier == 2:
				var costs: Array = KIT_TIER_COSTS.get(kit_id, [0, 100, 200])
				var t3_cost: int = costs[2] if costs.size() > 2 else 200
				var clean_btn := Button.new()
				clean_btn.text = "T3 Clean (%dcr)" % t3_cost
				clean_btn.custom_minimum_size = Vector2(120, 36)
				clean_btn.disabled = SaveManager.data.total_credits < t3_cost
				clean_btn.pressed.connect(_on_kit_t3_choice.bind(kit_id, "clean", t3_cost))
				btn_row.add_child(clean_btn)

				var void_btn := Button.new()
				void_btn.text = "T3 Void (%dcr)" % t3_cost
				void_btn.custom_minimum_size = Vector2(120, 36)
				void_btn.disabled = SaveManager.data.total_credits < t3_cost
				void_btn.pressed.connect(_on_kit_t3_choice.bind(kit_id, "void", t3_cost))
				btn_row.add_child(void_btn)
			else:
				var maxed_lbl := Label.new()
				maxed_lbl.text = "MAXED (T3 %s)" % t3_choice.capitalize()
				btn_row.add_child(maxed_lbl)

			# Assign to slot buttons
			var s1_btn := Button.new()
			s1_btn.text = "Slot 1"
			s1_btn.custom_minimum_size = Vector2(60, 36)
			s1_btn.pressed.connect(_on_kit_assign.bind(kit_id, 0))
			btn_row.add_child(s1_btn)

			var s2_btn := Button.new()
			s2_btn.text = "Slot 2"
			s2_btn.custom_minimum_size = Vector2(60, 36)
			s2_btn.pressed.connect(_on_kit_assign.bind(kit_id, 1))
			btn_row.add_child(s2_btn)

		var kit_sep := HSeparator.new()
		row.add_child(kit_sep)

		kits_scroll_vbox.add_child(row)

func _on_kit_unlock(kit_id: String, cost: int) -> void:
	if SaveManager.data.total_credits < cost:
		return
	SaveManager.data.total_credits -= cost
	SaveManager.data.unlocked_kits.append(kit_id)
	SaveManager.data.kit_tiers[kit_id] = 1
	SaveManager.save_game()
	_build_kits_list()
	_update_stats()

func _on_kit_tier_upgrade(kit_id: String, new_tier: int, cost: int) -> void:
	if SaveManager.data.total_credits < cost:
		return
	SaveManager.data.total_credits -= cost
	SaveManager.data.kit_tiers[kit_id] = new_tier
	SaveManager.save_game()
	_build_kits_list()
	_update_stats()

func _on_kit_t3_choice(kit_id: String, choice: String, cost: int) -> void:
	if SaveManager.data.total_credits < cost:
		return
	SaveManager.data.total_credits -= cost
	SaveManager.data.kit_tiers[kit_id] = 3
	SaveManager.data.kit_t3_choices[kit_id] = choice
	SaveManager.save_game()
	_build_kits_list()
	_update_stats()

func _on_kit_assign(kit_id: String, slot: int) -> void:
	var eq: Array[String] = SaveManager.data.equipped_kits
	if eq.is_empty():
		eq = ["stim_pack", "flash_trap"]
	while eq.size() < 2:
		eq.append("")
	# Avoid duplicate
	var other_slot: int = 1 - slot
	if eq[other_slot] == kit_id:
		eq[other_slot] = eq[slot]
	eq[slot] = kit_id
	SaveManager.data.equipped_kits = eq
	SaveManager.save_game()
	_build_kits_list()

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
	kits_tab_content.visible = false
	ship_tab_btn.disabled = true
	upgrades_tab_btn.disabled = false
	kits_tab_btn.disabled = false

func _show_upgrades_tab() -> void:
	ship_tab_content.visible = false
	upgrades_tab_content.visible = true
	kits_tab_content.visible = false
	ship_tab_btn.disabled = false
	upgrades_tab_btn.disabled = true
	kits_tab_btn.disabled = false
	_refresh_shop()

func _show_kits_tab() -> void:
	ship_tab_content.visible = false
	upgrades_tab_content.visible = false
	kits_tab_content.visible = true
	ship_tab_btn.disabled = false
	upgrades_tab_btn.disabled = false
	kits_tab_btn.disabled = true
	_build_kits_list()

func _update_stats() -> void:
	var d := SaveManager.data
	stats_label.text = "Credits: %d | Corruption: %d | Contracts: %d" % [
		d.total_credits, d.total_corruption, d.contracts_completed
	]

const PANTRY_COLORS: Dictionary = {
	"rift_dust": Color(0.9, 0.8, 0.3),
	"void_crystal": Color(0.6, 0.2, 0.9),
	"cave_moss": Color(0.3, 0.7, 0.4),
	"river_silt": Color(0.3, 0.6, 0.9),
	"elite_core": Color(1.0, 0.85, 0.0),
}

func _update_pantry() -> void:
	var pantry: Dictionary = SaveManager.data.pantry
	var has_any: bool = false
	for key in pantry:
		if pantry[key] > 0:
			has_any = true
			break
	var text := ""
	if not has_any:
		text = "  (empty — kill elites to collect ingredients)"
	else:
		for ing_id in pantry:
			var count: int = pantry.get(ing_id, 0)
			var display_name: String = ing_id.replace("_", " ").capitalize()
			text += "  %s: %d\n" % [display_name, count]
	pantry_label.text = text.strip_edges()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _on_cook() -> void:
	cook_status_label.text = "Kitchen coming soon"
