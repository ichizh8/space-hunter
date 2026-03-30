extends Control


# Tab containers built in _ready
var ship_tab_content: VBoxContainer
var upgrades_tab_content: VBoxContainer
var kits_tab_content: VBoxContainer
var stats_label: Label
var pantry_label: Label
var pantry_container: HBoxContainer   # colored ingredient dots
var cook_status_label: Label
var credits_label: Label
var kits_credits_label: Label
var kits_equipped_label: Label
var kits_scroll_vbox: VBoxContainer
var kitchen_scroll_vbox: VBoxContainer
var rep_label: Label
var rep_bars_container: VBoxContainer  # visual rep bars
var hunt_summary_panel: PanelContainer
var hunt_summary_label: Label
var onboarding_label: Label

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

const TRACK_ORDER: Array = ["contractor", "void_walker", "tactician", "scrapper"]

# Tab buttons
var ship_tab_btn: Button
var upgrades_tab_btn: Button
var kits_tab_btn: Button

# Upgrade shop buttons (for refresh)
var upgrade_buttons: Array = []
var upgrade_labels: Array = []

const UPGRADE_DEFS: Array = [
	{id="max_hp", name="Reinforced Hull", desc="Max HP +2", cost=80, max_level=3},
	{id="mag_size", name="Extended Magazine", desc="Mag Size +3", cost=60, max_level=3},
	{id="xp_rate", name="Void Attunement", desc="XP Rate +10%", cost=50, max_level=3},
	{id="loadout_slots", name="Extra Loadout Slot", desc="+1 slot", cost=100, max_level=2},
]

const WEAPON_UNLOCK_DEFS: Array = [
	{id="scatter", name="Unlock Scatter Pistol", desc="Starting weapon", cost=120},
	{id="lance", name="Unlock Void Lance", desc="Starting weapon", cost=150},
	{id="baton", name="Unlock Shock Baton", desc="Starting weapon", cost=130},
	{id="dart", name="Unlock Homing Dart", desc="Starting weapon", cost=80},
	{id="flamethrower", name="Unlock Flamethrower", desc="Starting weapon", cost=180},
	{id="grenade_launcher", name="Unlock Grenade Launcher", desc="Starting weapon", cost=160},
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

const ALL_KIT_IDS: Array = [
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

	# Title row with help button
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "The Wanderer — Your Ship"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.custom_minimum_size = Vector2(36, 36)
	help_btn.tooltip_text = "How to play"
	help_btn.pressed.connect(_show_intro_panel)
	title_row.add_child(help_btn)

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

	# --- Onboarding hint (first visit) ---
	onboarding_label = Label.new()
	onboarding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	onboarding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	onboarding_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	onboarding_label.visible = SaveManager.data.contracts_completed == 0
	onboarding_label.text = "★  Hunt → kill elites → collect ingredients → cook → gain rep → unlock weapons & kits\n   Tap Contract Board to start your first hunt."
	ship_tab_content.add_child(onboarding_label)

	# --- Hunt summary banner ---
	hunt_summary_panel = PanelContainer.new()
	hunt_summary_panel.visible = false
	ship_tab_content.add_child(hunt_summary_panel)

	hunt_summary_label = Label.new()
	hunt_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hunt_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hunt_summary_panel.add_child(hunt_summary_label)

	var contract_button := Button.new()
	contract_button.text = "▶  Contract Board"
	contract_button.custom_minimum_size = Vector2(0, 50)
	contract_button.pressed.connect(_on_contract_board)
	ship_tab_content.add_child(contract_button)

	# --- Pantry section ---
	var pantry_title := Label.new()
	pantry_title.text = "PANTRY"
	pantry_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(pantry_title)

	pantry_container = HBoxContainer.new()
	pantry_container.add_theme_constant_override("separation", 10)
	ship_tab_content.add_child(pantry_container)

	pantry_label = Label.new()
	pantry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pantry_label.visible = false  # fallback only
	ship_tab_content.add_child(pantry_label)

	# --- Rep tracks with progress bars ---
	var rep_title := Label.new()
	rep_title.text = "REPUTATION"
	rep_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(rep_title)

	rep_bars_container = VBoxContainer.new()
	rep_bars_container.add_theme_constant_override("separation", 4)
	ship_tab_content.add_child(rep_bars_container)

	rep_label = Label.new()
	rep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rep_label.visible = false  # fallback

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

	# Show intro on first ever launch
	if SaveManager.data.contracts_completed == 0 and not SaveManager.data.active_bonuses.get("_intro_seen", false):
		call_deferred("_show_intro_panel")

	# Endowed progress — gift starter rep + ingredients on very first launch
	if not SaveManager.data.active_bonuses.get("_endowed_progress", false):
		SaveManager.data.active_bonuses["_endowed_progress"] = true
		for track in ["contractor", "void_walker", "tactician", "scrapper"]:
			SaveManager.data.reputation[track] = SaveManager.data.reputation.get(track, 0) + 5
		for ing in ["rift_dust", "void_crystal", "cave_moss", "river_silt"]:
			SaveManager.data.pantry[ing] = SaveManager.data.pantry.get(ing, 0) + 1
		SaveManager.save_game()
		_update_stats()
		_update_pantry()

# ── INTRO ONBOARDING ──────────────────────────────────────────────────────────

const INTRO_SLIDES: Array = [
	{
		title = "SPACE HUNTER",
		icon = "🚀",
		body = "You are a hunter drifting between dead worlds.\n\nEvery run is a contract — kill, collect, survive.\nWhat you bring back shapes who you become.",
		color = Color(0.4, 0.8, 1.0),
	},
	{
		title = "THE LOOP",
		icon = "🔄",
		body = "① Pick a contract on the board\n② Hunt — kill elites, collect ingredients\n③ Return to your ship\n④ Cook recipes → earn reputation\n⑤ Rep unlocks new weapons and kits\n\nEach run you level up and choose upgrades.",
		color = Color(0.5, 1.0, 0.6),
	},
	{
		title = "CORRUPTION",
		icon = "☠",
		body = "Everything out there corrupts you.\n\nStay clean (low corruption) for precise, powerful abilities.\nEmbrace the void (high corruption) to unlock chaos and scaling damage.\n\nNeither path is wrong. Both demand commitment.",
		color = Color(0.75, 0.3, 1.0),
	},
	{
		title = "KITS",
		icon = "🧰",
		body = "You carry two kits into each hunt.\n\nKits evolve: Tier 2 adds new mechanics, Tier 3 lets you choose a path — Clean or Void.\n\nPlaying against your chosen path doubles your cooldowns. Commit.",
		color = Color(1.0, 0.75, 0.2),
	},
	{
		title = "READY TO HUNT",
		icon = "★",
		body = "Tap Contract Board to pick your first contract.\n\nGood luck out there.",
		color = Color(1.0, 0.9, 0.4),
	},
]

var _intro_slide_index: int = 0

func _show_intro_panel() -> void:
	_intro_slide_index = 0
	_build_intro_slide()

func _build_intro_slide() -> void:
	var existing := get_node_or_null("IntroPanel")
	if existing:
		existing.queue_free()

	var slide: Dictionary = INTRO_SLIDES[_intro_slide_index]
	var vp_size := get_viewport_rect().size

	var panel := Panel.new()
	panel.name = "IntroPanel"
	panel.position = Vector2.ZERO
	panel.size = vp_size

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.08, 0.97)
	panel.add_theme_stylebox_override("panel", bg)

	var outer := VBoxContainer.new()
	outer.position = Vector2(vp_size.x * 0.08, vp_size.y * 0.10)
	outer.size = Vector2(vp_size.x * 0.84, vp_size.y * 0.80)
	outer.add_theme_constant_override("separation", 18)
	panel.add_child(outer)

	# Progress dots
	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 8)
	outer.add_child(dots_row)
	for i in range(INTRO_SLIDES.size()):
		var dot := Label.new()
		dot.text = "●" if i == _intro_slide_index else "○"
		dot.add_theme_font_size_override("font_size", 14)
		dot.add_theme_color_override("font_color", slide.color if i == _intro_slide_index else Color(0.4, 0.4, 0.5))
		dots_row.add_child(dot)

	# Icon
	var icon_lbl := Label.new()
	icon_lbl.text = slide.icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 52)
	outer.add_child(icon_lbl)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = slide.title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", slide.color)
	outer.add_child(title_lbl)

	# Body
	var body_lbl := Label.new()
	body_lbl.text = slide.body
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 15)
	body_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body_lbl)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	outer.add_child(btn_row)

	# Skip on non-last slides, Close on last slide
	var skip_btn := Button.new()
	skip_btn.text = "Skip" if _intro_slide_index < INTRO_SLIDES.size() - 1 else "Close"
	skip_btn.custom_minimum_size = Vector2(90, 44)
	var skip_style := StyleBoxFlat.new()
	skip_style.bg_color = Color(0.15, 0.15, 0.2)
	skip_style.corner_radius_top_left = 6; skip_style.corner_radius_top_right = 6
	skip_style.corner_radius_bottom_left = 6; skip_style.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	skip_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	skip_btn.pressed.connect(_close_intro)
	btn_row.add_child(skip_btn)

	# Next / Let's Go
	var next_btn := Button.new()
	var is_last: bool = _intro_slide_index == INTRO_SLIDES.size() - 1
	next_btn.text = "Let's Go!" if is_last else "Next →"
	next_btn.custom_minimum_size = Vector2(130, 48)
	var next_style := StyleBoxFlat.new()
	next_style.bg_color = Color(slide.color.r * 0.35, slide.color.g * 0.35, slide.color.b * 0.35)
	next_style.border_color = slide.color
	next_style.border_width_left = 2; next_style.border_width_right = 2
	next_style.border_width_top = 2; next_style.border_width_bottom = 2
	next_style.corner_radius_top_left = 6; next_style.corner_radius_top_right = 6
	next_style.corner_radius_bottom_left = 6; next_style.corner_radius_bottom_right = 6
	next_btn.add_theme_stylebox_override("normal", next_style)
	next_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	next_btn.add_theme_font_size_override("font_size", 17)
	next_btn.pressed.connect(_intro_next)
	btn_row.add_child(next_btn)

	add_child(panel)

func _intro_next() -> void:
	if _intro_slide_index < INTRO_SLIDES.size() - 1:
		_intro_slide_index += 1
		call_deferred("_build_intro_slide")
	else:
		call_deferred("_close_intro")

func _close_intro() -> void:
	var panel := get_node_or_null("IntroPanel")
	if is_instance_valid(panel):
		panel.queue_free()
	# Mark intro as seen so it never shows again
	SaveManager.data.active_bonuses["_intro_seen"] = true
	SaveManager.save_game()

# ── END INTRO ONBOARDING ───────────────────────────────────────────────────────

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
	var eq: Array = SaveManager.data.equipped_kits
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
				var t3_btn := Button.new()
				t3_btn.text = "Unlock T3 (%dcr) — path chosen in run" % t3_cost
				t3_btn.custom_minimum_size = Vector2(220, 36)
				t3_btn.disabled = SaveManager.data.total_credits < t3_cost
				t3_btn.pressed.connect(_on_kit_tier_upgrade.bind(kit_id, 3, t3_cost))
				btn_row.add_child(t3_btn)
			else:
				var path_label: String = "(%s path)" % t3_choice.capitalize() if t3_choice != "" else "(path pending)"
				var maxed_lbl := Label.new()
				maxed_lbl.text = "MAXED T3 %s" % path_label
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
	var eq: Array = SaveManager.data.equipped_kits
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
	_show_hunt_summary()
	_update_pantry_visual()
	_update_rep_bars()
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
	stats_label.text = "Credits: %d  ·  Contracts: %d  ·  Corruption: %d" % [
		d.total_credits, d.contracts_completed, d.total_corruption
	]
	if is_instance_valid(onboarding_label):
		onboarding_label.visible = d.contracts_completed == 0 and GameData.hunt_result.is_empty()

const PANTRY_COLORS: Dictionary = {
	"rift_dust": Color(0.9, 0.8, 0.3),
	"void_crystal": Color(0.6, 0.2, 0.9),
	"cave_moss": Color(0.3, 0.7, 0.4),
	"river_silt": Color(0.3, 0.6, 0.9),
	"elite_core": Color(1.0, 0.85, 0.0),
}

func _update_pantry() -> void:
	_update_pantry_visual()

func _update_pantry_visual() -> void:
	# Clear and rebuild colored ingredient display
	for child in pantry_container.get_children():
		child.queue_free()

	var pantry: Dictionary = SaveManager.data.pantry
	var has_any: bool = false
	for key in pantry:
		if pantry[key] > 0:
			has_any = true
			break

	if not has_any:
		var empty_lbl := Label.new()
		empty_lbl.text = "(empty — kill elites to collect ingredients)"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		pantry_container.add_child(empty_lbl)
		return

	const ING_ORDER: Array = ["rift_dust", "void_crystal", "cave_moss", "river_silt", "elite_core"]
	for ing_id in ING_ORDER:
		var count: int = pantry.get(ing_id, 0)
		var color: Color = PANTRY_COLORS.get(ing_id, Color.WHITE)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)

		# Colored square as a ColorRect inside a small container
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(28, 28)
		dot.color = color if count > 0 else Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.5)
		vbox.add_child(dot)

		var count_lbl := Label.new()
		count_lbl.text = str(count)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_color_override("font_color", color if count > 0 else Color(0.4, 0.4, 0.4))
		count_lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(count_lbl)

		var name_lbl := Label.new()
		name_lbl.text = ing_id.replace("_", " ").capitalize().left(8)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(name_lbl)

		pantry_container.add_child(vbox)

func _show_hunt_summary() -> void:
	var result: Dictionary = GameData.hunt_result
	if result.is_empty():
		hunt_summary_panel.visible = false
		return

	hunt_summary_panel.visible = true
	onboarding_label.visible = false  # hide onboarding once a hunt is done

	var lines: Array = ["— Last Hunt —"]

	var credits: int = result.get("credits", 0)
	if credits > 0:
		lines.append("+%d credits" % credits)

	var ings: Array = result.get("ingredients", [])
	if ings.size() > 0:
		# Count by id
		var ing_counts: Dictionary = {}
		for ing in ings:
			var iid: String = ing.get("id", "?")
			ing_counts[iid] = ing_counts.get(iid, 0) + 1
		var ing_str: String = ""
		for iid in ing_counts:
			if not ing_str.is_empty():
				ing_str += "  "
			ing_str += "+%d %s" % [ing_counts[iid], iid.replace("_", " ").capitalize()]
		lines.append(ing_str)

	var corr: int = result.get("corruption", 0)
	if corr > 0:
		lines.append("+%d corruption absorbed" % corr)

	hunt_summary_label.text = "\n".join(lines)
	hunt_summary_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	hunt_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _update_rep_bars() -> void:
	for child in rep_bars_container.get_children():
		child.queue_free()

	var rep: Dictionary = SaveManager.data.reputation
	for track in TRACK_ORDER:
		var pts: int = rep.get(track, 0)
		var level: int = SaveData.get_rep_level(track, rep)
		var color: Color = TRACK_COLORS.get(track, Color.WHITE)
		var display_name: String = track.replace("_", " ").capitalize()

		# Calculate progress to next level
		var thresholds: Array = SaveData.REP_THRESHOLDS
		var bar_frac: float = 1.0
		var next_pts: int = 0
		var prev_pts: int = 0
		if level < thresholds.size() - 1:
			next_pts = thresholds[level + 1]
			prev_pts = thresholds[level]
			bar_frac = clampf(float(pts - prev_pts) / float(next_pts - prev_pts), 0.0, 1.0)

		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)

		# Label row
		var label_row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "%s  Lv%d" % [display_name, level]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", color)
		name_lbl.add_theme_font_size_override("font_size", 13)
		label_row.add_child(name_lbl)

		var pts_lbl := Label.new()
		if level >= thresholds.size() - 1:
			pts_lbl.text = "MAX"
		else:
			pts_lbl.text = "%d / %d" % [pts, next_pts]
		pts_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		pts_lbl.add_theme_font_size_override("font_size", 11)
		label_row.add_child(pts_lbl)
		row.add_child(label_row)

		# Progress bar (HBoxContainer with two ColorRects)
		var bar_bg := PanelContainer.new()
		bar_bg.custom_minimum_size = Vector2(0, 6)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar_bg)

		var bar_hbox := HBoxContainer.new()
		bar_hbox.add_theme_constant_override("separation", 0)
		bar_bg.add_child(bar_hbox)

		var bar_fill := ColorRect.new()
		bar_fill.color = color
		bar_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_fill.size_flags_stretch_ratio = bar_frac
		bar_hbox.add_child(bar_fill)

		if bar_frac < 1.0:
			var bar_empty := ColorRect.new()
			bar_empty.color = Color(0.15, 0.15, 0.2)
			bar_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar_empty.size_flags_stretch_ratio = 1.0 - bar_frac
			bar_hbox.add_child(bar_empty)

		rep_bars_container.add_child(row)

func _update_rep_display() -> void:
	_update_rep_bars()

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

		var locked_count: int = 0
		for recipe_id in RECIPES:
			var recipe: Dictionary = RECIPES[recipe_id]
			if recipe.track != track:
				continue
			var unlocked: bool = _is_recipe_unlocked(recipe_id)
			if not unlocked:
				locked_count += 1
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
			info.text = "%s  [%s]  %s" % [display_name, cost_str, rep_str]
			if not bonus_str.is_empty():
				info.text += "  ·  %s" % bonus_str
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

			var can_afford: bool = _can_afford_recipe(recipe_id)
			if not can_afford:
				info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			row.add_child(info)

			var btn := Button.new()
			btn.text = "Cook"
			btn.custom_minimum_size = Vector2(60, 36)
			btn.disabled = not can_afford
			btn.pressed.connect(_on_cook_recipe.bind(recipe_id))
			row.add_child(btn)

			kitchen_scroll_vbox.add_child(row)

		# Show locked teaser
		if locked_count > 0:
			var locked_lbl := Label.new()
			locked_lbl.text = "  + %d recipe%s locked — complete contracts to unlock" % [locked_count, "s" if locked_count > 1 else ""]
			locked_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			locked_lbl.add_theme_font_size_override("font_size", 11)
			kitchen_scroll_vbox.add_child(locked_lbl)

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
	_update_pantry_visual()
	_update_rep_bars()
	_build_kitchen()
	_update_stats()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")
