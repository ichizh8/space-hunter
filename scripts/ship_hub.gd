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
var kitchen_scroll_vbox: VBoxContainer
var rep_label: Label

const RECIPES: Dictionary = {
	"field_ration":     {tier = 1, track = "contractor",  cost = {"rift_dust": 1},                   rep = 10, bonus = ""},
	"void_brew":        {tier = 1, track = "void_walker",  cost = {"void_crystal": 1},                rep = 10, bonus = ""},
	"cave_jerky":       {tier = 1, track = "tactician",    cost = {"cave_moss": 1},                   rep = 10, bonus = ""},
	"silt_stew":        {tier = 1, track = "scrapper",     cost = {"river_silt": 1},                  rep = 10, bonus = ""},
	"silt_cured_meat":  {tier = 2, track = "contractor",  cost = {"river_silt": 2},                  rep = 25, bonus = "credits_boost"},
	"void_infusion":    {tier = 2, track = "void_walker",  cost = {"void_crystal": 2},                rep = 25, bonus = "start_corrupted"},
	"cave_broth":       {tier = 2, track = "tactician",    cost = {"cave_moss": 2},                   rep = 25, bonus = "trap_charge"},
	"gland_tonic":      {tier = 2, track = "scrapper",     cost = {"rift_dust": 2},                   rep = 25, bonus = "stim_boost"},
	"purified_extract": {tier = 3, track = "contractor",  cost = {"elite_core": 1, "river_silt": 1}, rep = 60, bonus = "reveal_elites"},
	"void_communion":   {tier = 3, track = "void_walker",  cost = {"elite_core": 1, "void_crystal": 1}, rep = 60, bonus = "early_mutation"},
	"tactical_compound":{tier = 3, track = "tactician",    cost = {"elite_core": 1, "cave_moss": 1},  rep = 60, bonus = "kit_charge_all"},
	"ironblood_draught":{tier = 3, track = "scrapper",     cost = {"elite_core": 1, "rift_dust": 1},  rep = 60, bonus = "temp_hp"},
}

const RECIPE_DISPLAY_NAMES: Dictionary = {
	"field_ration": "Field Ration", "void_brew": "Void Brew", "cave_jerky": "Cave Jerky",
	"silt_stew": "Silt Stew", "silt_cured_meat": "Silt-Cured Meat", "void_infusion": "Void Infusion",
	"cave_broth": "Cave Broth", "gland_tonic": "Gland Tonic", "purified_extract": "Purified Extract",
	"void_communion": "Void Communion", "tactical_compound": "Tactical Compound",
	"ironblood_draught": "Ironblood Draught",
}

const BONUS_DESCS: Dictionary = {
	"credits_boost": "+20% credits next hunt",
	"start_corrupted": "Start at corruption 10",
	"trap_charge": "+1 trap charge next hunt",
	"stim_boost": "Stim cooldown -20% next hunt",
	"reveal_elites": "Reveal elite spawns on map",
	"early_mutation": "Void mutation from Lv4",
	"kit_charge_all": "All kits +1 charge",
	"temp_hp": "Start with 30 temp HP",
}

const TRACK_COLORS: Dictionary = {
	"contractor": Color(0.3, 0.8, 0.3),
	"void_walker": Color(0.6, 0.2, 0.9),
	"tactician": Color(0.3, 0.5, 0.9),
	"scrapper": Color(0.9, 0.5, 0.2),
}

const TRACK_ORDER: Array[String] = ["contractor", "void_walker", "tactician", "scrapper"]

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

	var contract_button := Button.new()
	contract_button.text = "Contract Board"
	contract_button.custom_minimum_size = Vector2(0, 50)
	contract_button.pressed.connect(_on_contract_board)
	ship_tab_content.add_child(contract_button)

	# --- Pantry section ---
	var pantry_title := Label.new()
	pantry_title.text = "PANTRY"
	pantry_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(pantry_title)

	pantry_label = Label.new()
	pantry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ship_tab_content.add_child(pantry_label)

	# --- Rep tracks ---
	rep_label = Label.new()
	rep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ship_tab_content.add_child(rep_label)

	var sep2 := HSeparator.new()
	ship_tab_content.add_child(sep2)

	# --- Kitchen section ---
	var kitchen_title := Label.new()
	kitchen_title.text = "KITCHEN"
	kitchen_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(kitchen_title)

	cook_status_label = Label.new()
	cook_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cook_status_label.text = ""
	ship_tab_content.add_child(cook_status_label)

	var kitchen_scroll := ScrollContainer.new()
	kitchen_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kitchen_scroll.custom_minimum_size = Vector2(0, 250)
	ship_tab_content.add_child(kitchen_scroll)

	kitchen_scroll_vbox = VBoxContainer.new()
	kitchen_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kitchen_scroll.add_child(kitchen_scroll_vbox)

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

	# Auto-unlock Tier 2 recipes at rep level 1
	_check_tier2_unlocks()

	# Start on ship tab
	_update_stats()
	_update_pantry()
	_update_rep_display()
	_build_kitchen()
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
	_update_pantry()
	_update_rep_display()
	_build_kitchen()

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
			var count_str: String = "%d" % count if count > 0 else "0"
			text += "  %s: %s\n" % [display_name, count_str]
	pantry_label.text = text.strip_edges()

func _update_rep_display() -> void:
	var rep: Dictionary = SaveManager.data.reputation
	var text := ""
	for track in TRACK_ORDER:
		var pts: int = rep.get(track, 0)
		var level: int = SaveData.get_rep_level(track, rep)
		var display_name: String = track.replace("_", " ").capitalize()
		var next_threshold: int = 0
		if level < SaveData.REP_THRESHOLDS.size() - 1:
			next_threshold = SaveData.REP_THRESHOLDS[level + 1]
		var progress_str: String = ""
		if next_threshold > 0:
			progress_str = " (%d/%d)" % [pts, next_threshold]
		else:
			progress_str = " (MAX)"
		text += "  %s: Lv%d%s\n" % [display_name, level, progress_str]
	rep_label.text = text.strip_edges()

func _check_tier2_unlocks() -> void:
	var rep: Dictionary = SaveManager.data.reputation
	var changed := false
	for recipe_id in RECIPES:
		var recipe: Dictionary = RECIPES[recipe_id]
		if recipe.tier != 2:
			continue
		if SaveManager.data.unlocked_recipes.has(recipe_id):
			continue
		var track: String = recipe.track
		if SaveData.get_rep_level(track, rep) >= 1:
			SaveManager.data.unlocked_recipes.append(recipe_id)
			changed = true
	if changed:
		SaveManager.save_game()

func _is_recipe_unlocked(recipe_id: String) -> bool:
	var recipe: Dictionary = RECIPES[recipe_id]
	if recipe.tier == 1:
		return true
	if recipe.tier == 2:
		if SaveManager.data.unlocked_recipes.has(recipe_id):
			return true
		var rep: Dictionary = SaveManager.data.reputation
		return SaveData.get_rep_level(recipe.track, rep) >= 1
	# Tier 3: only via contract unlock
	return SaveManager.data.unlocked_recipes.has(recipe_id)

func _can_afford_recipe(recipe_id: String) -> bool:
	var recipe: Dictionary = RECIPES[recipe_id]
	var pantry: Dictionary = SaveManager.data.pantry
	for ing_id in recipe.cost:
		var needed: int = recipe.cost[ing_id]
		if pantry.get(ing_id, 0) < needed:
			return false
	return true

func _build_kitchen() -> void:
	for child in kitchen_scroll_vbox.get_children():
		child.queue_free()

	for track in TRACK_ORDER:
		var track_label := Label.new()
		track_label.text = track.replace("_", " ").capitalize()
		track_label.add_theme_color_override("font_color", TRACK_COLORS.get(track, Color.WHITE))
		kitchen_scroll_vbox.add_child(track_label)

		for recipe_id in RECIPES:
			var recipe: Dictionary = RECIPES[recipe_id]
			if recipe.track != track:
				continue
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var info := Label.new()
			var display_name: String = RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id)
			var cost_str := ""
			for ing_id in recipe.cost:
				if not cost_str.is_empty():
					cost_str += ", "
				cost_str += "%s x%d" % [ing_id.replace("_", " ").capitalize(), recipe.cost[ing_id]]
			var bonus_str: String = BONUS_DESCS.get(recipe.bonus, "")
			var rep_str: String = "+%d rep" % recipe.rep
			info.text = "%s [%s] %s" % [display_name, cost_str, rep_str]
			if not bonus_str.is_empty():
				info.text += " | %s" % bonus_str
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			var unlocked: bool = _is_recipe_unlocked(recipe_id)
			var can_afford: bool = _can_afford_recipe(recipe_id)

			if not unlocked:
				info.text = "%s — Contract reward required" % display_name
				info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			elif not can_afford:
				info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

			row.add_child(info)

			var btn := Button.new()
			btn.text = "Cook"
			btn.custom_minimum_size = Vector2(60, 36)
			btn.disabled = not unlocked or not can_afford
			btn.pressed.connect(_on_cook_recipe.bind(recipe_id))
			row.add_child(btn)

			kitchen_scroll_vbox.add_child(row)

		var track_sep := HSeparator.new()
		kitchen_scroll_vbox.add_child(track_sep)

func _on_cook_recipe(recipe_id: String) -> void:
	var recipe: Dictionary = RECIPES[recipe_id]
	if not _is_recipe_unlocked(recipe_id) or not _can_afford_recipe(recipe_id):
		return

	# Deduct ingredients
	for ing_id in recipe.cost:
		var needed: int = recipe.cost[ing_id]
		SaveManager.data.pantry[ing_id] = SaveManager.data.pantry.get(ing_id, 0) - needed

	# Award rep
	var track: String = recipe.track
	var old_level: int = SaveData.get_rep_level(track, SaveManager.data.reputation)
	SaveManager.data.reputation[track] = SaveManager.data.reputation.get(track, 0) + recipe.rep
	var new_level: int = SaveData.get_rep_level(track, SaveManager.data.reputation)

	# Store bonus
	if not recipe.bonus.is_empty():
		SaveManager.data.active_bonuses[recipe.bonus] = true

	# Check for tier 2 auto-unlocks
	_check_tier2_unlocks()

	SaveManager.save_game()

	# Show feedback
	var display_name: String = RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id)
	cook_status_label.text = "Cooked %s! +%d %s rep" % [display_name, recipe.rep, track.replace("_", " ").capitalize()]

	if new_level > old_level:
		cook_status_label.text += " — %s Level Up! -> Level %d" % [track.replace("_", " ").capitalize(), new_level]

	# Refresh UI
	_update_pantry()
	_update_rep_display()
	_build_kitchen()
	_update_stats()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")
