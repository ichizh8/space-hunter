extends Control


# Tab containers built in _ready
var ship_tab_content: VBoxContainer
var upgrades_tab_content: VBoxContainer
var kits_tab_content: VBoxContainer
var stats_label: Label
var pantry_label: Label
var pantry_container: HBoxContainer
var cook_status_label: Label
var credits_label: Label
var kits_credits_label: Label
var kits_equipped_label: Label
var kits_scroll_vbox: VBoxContainer
var kitchen_scroll_vbox: VBoxContainer
var rep_label: Label
var rep_bars_container: VBoxContainer
var hunt_summary_panel: PanelContainer
var hunt_summary_label: Label
var onboarding_label: Label

# ── Bottom tab bar refs ──
var tab_bar_panel: PanelContainer
var ship_tab_btn: Button
var upgrades_tab_btn: Button
var kits_tab_btn: Button

# Content scroll
var content_scroll: ScrollContainer

# Upgrade shop buttons (for refresh)
var upgrade_buttons: Array = []
var upgrade_labels: Array = []

# ── DATA CONSTANTS (unchanged) ───────────────────────────────────────────────

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

const TRACK_ORDER: Array = ["contractor", "void_walker", "tactician", "scrapper"]

const UPGRADE_DEFS: Array = [
	{id="max_hp", name="Reinforced Hull", desc="Max HP +2", cost=80, max_level=3},
	{id="mag_size", name="Extended Magazine", desc="Mag Size +3", cost=60, max_level=3},
	{id="xp_rate", name="Void Attunement", desc="XP Rate +10%", cost=50, max_level=3},
	{id="loadout_slots", name="Extra Loadout Slot", desc="+1 slot", cost=100, max_level=2},
]

const WEAPON_UNLOCK_DEFS: Array = [
	{id="scatter", name="Scatter Pistol", desc="Close-range burst", cost=120},
	{id="lance", name="Void Lance", desc="Piercing beam", cost=150},
	{id="baton", name="Shock Baton", desc="Melee AOE", cost=130},
	{id="dart", name="Homing Dart", desc="Homing shots", cost=80},
	{id="flamethrower", name="Flamethrower", desc="Cone damage", cost=180},
	{id="grenade_launcher", name="Grenade Launcher", desc="Explosive", cost=160},
]

const KIT_NAMES: Dictionary = {
	"stim_pack": "Stim Pack", "flash_trap": "Flash Trap", "blink_kit": "Blink",
	"chain_kit": "Chain", "charge_kit": "Charge", "mirage_kit": "Mirage",
	"turret_kit": "Turret", "smoke_kit": "Smoke", "anchor_kit": "Anchor",
	"drone_kit": "Drone", "familiar_kit": "Familiar", "pack_kit": "Pack",
	"void_surge": "Void Surge", "rupture_kit": "Rupture",
}

const KIT_DESCS: Dictionary = {
	"stim_pack": "Heal HP, gain corruption", "flash_trap": "Stun trap, 2 charges",
	"blink_kit": "Teleport 200px", "chain_kit": "Tether enemy 3s",
	"charge_kit": "Knockback blast", "mirage_kit": "Decoy draws aggro",
	"turret_kit": "Auto-turret", "smoke_kit": "Smoke screen",
	"anchor_kit": "Gravity pull", "drone_kit": "Intercept bullets",
	"familiar_kit": "Void familiar", "pack_kit": "Summon allies",
	"void_surge": "Speed burst", "rupture_kit": "Corruption AOE",
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

# ── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Root background
	var bg_rect := ColorRect.new()
	bg_rect.color = UITheme.BG_DARK
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# Main layout: full screen VBoxContainer
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.anchor_bottom = 1.0
	root.offset_left = UITheme.MARGIN_LG
	root.offset_right = -UITheme.MARGIN_LG
	root.offset_top = UITheme.MARGIN_MD
	root.offset_bottom = -70  # room for bottom tab bar
	root.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	add_child(root)

	# ── HEADER ROW ──
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(header)

	var title := UITheme.make_label("SPACE HUNTER", UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.custom_minimum_size = Vector2(40, 40)
	help_btn.tooltip_text = "How to play"
	UITheme.style_button_ghost(help_btn, UITheme.FONT_HEADING)
	help_btn.pressed.connect(_show_intro_panel)
	header.add_child(help_btn)

	# ── STATS BAR ──
	stats_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(stats_label)

	root.add_child(UITheme.make_separator())

	# ── SCROLLABLE CONTENT AREA ──
	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(content_scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	content_scroll.add_child(content_vbox)

	# === SHIP TAB CONTENT ===
	ship_tab_content = VBoxContainer.new()
	ship_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ship_tab_content.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	content_vbox.add_child(ship_tab_content)
	_build_ship_tab()

	# === UPGRADES TAB CONTENT ===
	upgrades_tab_content = VBoxContainer.new()
	upgrades_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_tab_content.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	content_vbox.add_child(upgrades_tab_content)
	_build_upgrades_tab()

	# === KITS TAB CONTENT ===
	kits_tab_content = VBoxContainer.new()
	kits_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kits_tab_content.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	content_vbox.add_child(kits_tab_content)
	_build_kits_tab()

	# ── BOTTOM TAB BAR (floating, pixel-glass style) ──
	_build_tab_bar()

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


func _build_ship_tab() -> void:
	# Onboarding hint
	onboarding_label = UITheme.make_label(
		"Hunt elites   collect ingredients   cook   gain rep   unlock gear",
		UITheme.FONT_SMALL, UITheme.ACCENT_CYAN
	)
	onboarding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	onboarding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	onboarding_label.visible = SaveManager.data.contracts_completed == 0
	ship_tab_content.add_child(onboarding_label)

	# Hunt summary banner
	hunt_summary_panel = UITheme.make_card(
		Color(UITheme.ACCENT_GREEN.r * 0.1, UITheme.ACCENT_GREEN.g * 0.1, UITheme.ACCENT_GREEN.b * 0.1),
		Color(UITheme.ACCENT_GREEN.r * 0.4, UITheme.ACCENT_GREEN.g * 0.4, UITheme.ACCENT_GREEN.b * 0.4)
	)
	hunt_summary_panel.visible = false
	ship_tab_content.add_child(hunt_summary_panel)

	hunt_summary_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.ACCENT_GREEN)
	hunt_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hunt_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hunt_summary_panel.add_child(hunt_summary_label)

	# Contract Board button — primary CTA
	var contract_button := Button.new()
	contract_button.text = "CONTRACT BOARD"
	contract_button.custom_minimum_size = Vector2(0, 56)
	UITheme.style_button_primary(contract_button, UITheme.ACCENT_GOLD, UITheme.FONT_HEADING)
	contract_button.pressed.connect(_on_contract_board)
	ship_tab_content.add_child(contract_button)

	# Pantry section
	ship_tab_content.add_child(UITheme.make_section_header("PANTRY", UITheme.ACCENT_ORANGE))

	pantry_container = HBoxContainer.new()
	pantry_container.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	pantry_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ship_tab_content.add_child(pantry_container)

	pantry_label = Label.new()
	pantry_label.visible = false
	ship_tab_content.add_child(pantry_label)

	# Reputation section
	ship_tab_content.add_child(UITheme.make_section_header("REPUTATION", UITheme.ACCENT_BLUE))

	rep_bars_container = VBoxContainer.new()
	rep_bars_container.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	ship_tab_content.add_child(rep_bars_container)

	rep_label = Label.new()
	rep_label.visible = false

	ship_tab_content.add_child(UITheme.make_separator())

	# Kitchen section
	ship_tab_content.add_child(UITheme.make_section_header("KITCHEN", UITheme.ACCENT_RED))

	cook_status_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.ACCENT_GREEN)
	cook_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_tab_content.add_child(cook_status_label)

	kitchen_scroll_vbox = VBoxContainer.new()
	kitchen_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kitchen_scroll_vbox.add_theme_constant_override("separation", UITheme.MARGIN_XS)
	ship_tab_content.add_child(kitchen_scroll_vbox)


func _build_upgrades_tab() -> void:
	credits_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_tab_content.add_child(credits_label)

	upgrades_tab_content.add_child(UITheme.make_section_header("SHIP UPGRADES", UITheme.ACCENT_CYAN))

	for def in UPGRADE_DEFS:
		var row := _make_upgrade_row(def)
		upgrades_tab_content.add_child(row)

	upgrades_tab_content.add_child(UITheme.make_section_header("WEAPONS", UITheme.ACCENT_ORANGE))

	for def in WEAPON_UNLOCK_DEFS:
		var row := _make_weapon_unlock_row(def)
		upgrades_tab_content.add_child(row)


func _build_kits_tab() -> void:
	kits_credits_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.ACCENT_GOLD)
	kits_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kits_tab_content.add_child(kits_credits_label)

	kits_equipped_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.ACCENT_CYAN)
	kits_equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kits_tab_content.add_child(kits_equipped_label)

	kits_tab_content.add_child(UITheme.make_separator())

	kits_scroll_vbox = VBoxContainer.new()
	kits_scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kits_scroll_vbox.add_theme_constant_override("separation", UITheme.MARGIN_XS)
	kits_tab_content.add_child(kits_scroll_vbox)


func _build_tab_bar() -> void:
	# Floating bottom tab bar — pixel-glass aesthetic
	tab_bar_panel = PanelContainer.new()
	tab_bar_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tab_bar_panel.anchor_top = 1.0
	tab_bar_panel.anchor_bottom = 1.0
	tab_bar_panel.offset_top = -64
	tab_bar_panel.offset_left = UITheme.MARGIN_LG
	tab_bar_panel.offset_right = -UITheme.MARGIN_LG
	tab_bar_panel.offset_bottom = -UITheme.MARGIN_SM

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(UITheme.BG_DARK.r, UITheme.BG_DARK.g, UITheme.BG_DARK.b, 0.85)
	bar_style.border_color = UITheme.BORDER_DEFAULT
	bar_style.border_width_left = 2; bar_style.border_width_right = 2
	bar_style.border_width_top = 2; bar_style.border_width_bottom = 2
	bar_style.content_margin_left = UITheme.MARGIN_XS
	bar_style.content_margin_right = UITheme.MARGIN_XS
	bar_style.content_margin_top = UITheme.MARGIN_XS
	bar_style.content_margin_bottom = UITheme.MARGIN_XS
	tab_bar_panel.add_theme_stylebox_override("panel", bar_style)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", UITheme.MARGIN_XS)
	tab_bar_panel.add_child(tab_hbox)

	ship_tab_btn = Button.new()
	ship_tab_btn.text = "SHIP"
	ship_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ship_tab_btn.custom_minimum_size = Vector2(0, 48)
	ship_tab_btn.pressed.connect(_show_ship_tab)
	tab_hbox.add_child(ship_tab_btn)

	upgrades_tab_btn = Button.new()
	upgrades_tab_btn.text = "UPGRADES"
	upgrades_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_tab_btn.custom_minimum_size = Vector2(0, 48)
	upgrades_tab_btn.pressed.connect(_show_upgrades_tab)
	tab_hbox.add_child(upgrades_tab_btn)

	kits_tab_btn = Button.new()
	kits_tab_btn.text = "KITS"
	kits_tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kits_tab_btn.custom_minimum_size = Vector2(0, 48)
	kits_tab_btn.pressed.connect(_show_kits_tab)
	tab_hbox.add_child(kits_tab_btn)

	add_child(tab_bar_panel)


# ── INTRO ONBOARDING ─────────────────────────────────────────────────────────

const INTRO_SLIDES: Array = [
	{
		title = "SPACE HUNTER",
		icon = ">>",
		body = "You are a hunter drifting between dead worlds.\n\nEvery run is a contract — kill, collect, survive.\nWhat you bring back shapes who you become.",
		color = Color(0.4, 0.8, 1.0),
	},
	{
		title = "THE LOOP",
		icon = "<>",
		body = "1. Pick a contract on the board\n2. Hunt — kill elites, collect ingredients\n3. Return to your ship\n4. Cook recipes to earn reputation\n5. Rep unlocks new weapons and kits\n\nEach run you level up and choose upgrades.",
		color = Color(0.5, 1.0, 0.6),
	},
	{
		title = "CORRUPTION",
		icon = "##",
		body = "Everything out there corrupts you.\n\nStay clean (low corruption) for precise, powerful abilities.\nEmbrace the void (high corruption) to unlock chaos and scaling damage.\n\nNeither path is wrong. Both demand commitment.",
		color = Color(0.75, 0.3, 1.0),
	},
	{
		title = "KITS",
		icon = "[]",
		body = "You carry two kits into each hunt.\n\nKits evolve: Tier 2 adds new mechanics, Tier 3 lets you choose a path — Clean or Void.\n\nPlaying against your chosen path doubles your cooldowns. Commit.",
		color = Color(1.0, 0.75, 0.2),
	},
	{
		title = "READY TO HUNT",
		icon = "!!",
		body = "Tap Contract Board to pick your first contract.\n\nGood luck out there.",
		color = Color(1.0, 0.9, 0.4),
	},
]

var _intro_slide_index: int = 0
var _intro_pending_next: bool = false
var _intro_pending_close: bool = false

func _show_intro_panel() -> void:
	_intro_slide_index = 0
	_build_intro_slide()

func _build_intro_slide() -> void:
	# Safety: remove any existing intro panel
	var existing := get_node_or_null("IntroPanel")
	if is_instance_valid(existing):
		existing.queue_free()

	if _intro_slide_index < 0 or _intro_slide_index >= INTRO_SLIDES.size():
		return

	var slide: Dictionary = INTRO_SLIDES[_intro_slide_index]
	var vp_size := get_viewport_rect().size

	var panel := Panel.new()
	panel.name = "IntroPanel"
	panel.position = Vector2.ZERO
	panel.size = vp_size

	var bg := StyleBoxFlat.new()
	bg.bg_color = UITheme.BG_OVERLAY
	panel.add_theme_stylebox_override("panel", bg)

	# Content card in the center
	var card := PanelContainer.new()
	card.position = Vector2(vp_size.x * 0.06, vp_size.y * 0.08)
	card.size = Vector2(vp_size.x * 0.88, vp_size.y * 0.84)
	var card_style := UITheme.make_panel_style(
		UITheme.BG_MEDIUM,
		Color(slide.color.r * 0.5, slide.color.g * 0.5, slide.color.b * 0.5)
	)
	card.add_theme_stylebox_override("panel", card_style)
	panel.add_child(card)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UITheme.MARGIN_LG)
	card.add_child(outer)

	# Progress bar (pixel segments)
	var progress_hbox := HBoxContainer.new()
	progress_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_hbox.add_theme_constant_override("separation", UITheme.MARGIN_XS)
	outer.add_child(progress_hbox)
	for i in range(INTRO_SLIDES.size()):
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(40, 4)
		if i <= _intro_slide_index:
			seg.color = slide.color
		else:
			seg.color = UITheme.BORDER_DEFAULT
		progress_hbox.add_child(seg)

	# Spacer
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, UITheme.MARGIN_MD)
	outer.add_child(spacer_top)

	# Icon (pixel text instead of emoji for WASM compatibility)
	var icon_lbl := UITheme.make_label(slide.icon, 36, slide.color)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(icon_lbl)

	# Title
	var title_lbl := UITheme.make_label(slide.title, UITheme.FONT_TITLE, slide.color)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title_lbl)

	# Body
	var body_lbl := UITheme.make_label(slide.body, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body_lbl)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", UITheme.MARGIN_MD)
	outer.add_child(btn_row)

	# Skip button (always visible, works on every slide)
	var skip_btn := Button.new()
	var is_last: bool = _intro_slide_index == INTRO_SLIDES.size() - 1
	skip_btn.text = "Close" if is_last else "Skip"
	skip_btn.custom_minimum_size = Vector2(100, UITheme.BUTTON_MIN_H)
	UITheme.style_button_ghost(skip_btn, UITheme.FONT_BODY)
	skip_btn.pressed.connect(_close_intro)
	btn_row.add_child(skip_btn)

	# Next / Let's Go
	if not is_last:
		var next_btn := Button.new()
		next_btn.text = "Next"
		next_btn.custom_minimum_size = Vector2(140, 52)
		UITheme.style_button_primary(next_btn, slide.color, UITheme.FONT_HEADING)
		next_btn.pressed.connect(_intro_next)
		btn_row.add_child(next_btn)
	else:
		var go_btn := Button.new()
		go_btn.text = "Let's Go!"
		go_btn.custom_minimum_size = Vector2(160, 52)
		UITheme.style_button_primary(go_btn, UITheme.ACCENT_GOLD, UITheme.FONT_HEADING)
		go_btn.pressed.connect(_close_intro)
		btn_row.add_child(go_btn)

	add_child(panel)
	panel.move_to_front()

func _intro_next() -> void:
	if _intro_slide_index < INTRO_SLIDES.size() - 1:
		_intro_pending_next = true
	else:
		_intro_pending_close = true

func _close_intro() -> void:
	_intro_pending_close = true

func _do_intro_next() -> void:
	_intro_slide_index += 1
	_build_intro_slide()

func _do_close_intro() -> void:
	var panel := get_node_or_null("IntroPanel")
	if is_instance_valid(panel):
		panel.queue_free()
	SaveManager.data.active_bonuses["_intro_seen"] = true
	SaveManager.save_game()

func _process(_delta: float) -> void:
	if _intro_pending_next:
		_intro_pending_next = false
		call_deferred("_do_intro_next")
	if _intro_pending_close:
		_intro_pending_close = false
		call_deferred("_do_close_intro")

# ── UPGRADE ROWS ─────────────────────────────────────────────────────────────

func _make_upgrade_row(def: Dictionary) -> PanelContainer:
	var card := UITheme.make_card()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var lbl := UITheme.make_label("", UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(lbl)
	upgrade_labels.append(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(UITheme.BUTTON_MIN_W, UITheme.BUTTON_MIN_H)
	UITheme.style_button(btn, UITheme.ACCENT_CYAN)
	btn.pressed.connect(_on_buy_upgrade.bind(def.id, def.cost))
	row.add_child(btn)
	upgrade_buttons.append(btn)

	_update_upgrade_label(lbl, btn, def)
	return card

func _make_weapon_unlock_row(def: Dictionary) -> PanelContainer:
	var card := UITheme.make_card()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.MARGIN_SM)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_lbl := UITheme.make_label(def.name, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
	info.add_child(name_lbl)

	var desc_lbl := UITheme.make_label(def.desc, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
	info.add_child(desc_lbl)

	var lbl := Label.new()
	lbl.visible = false
	info.add_child(lbl)
	upgrade_labels.append(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(UITheme.BUTTON_MIN_W, UITheme.BUTTON_MIN_H)
	UITheme.style_button(btn, UITheme.ACCENT_ORANGE)
	btn.pressed.connect(_on_buy_weapon.bind(def.id, def.cost))
	row.add_child(btn)
	upgrade_buttons.append(btn)

	_update_weapon_label(lbl, btn, def)
	return card

func _update_upgrade_label(lbl: Label, btn: Button, def: Dictionary) -> void:
	var level: int = SaveManager.data.ship_upgrades.get(def.id, 0)
	var maxed: bool = level >= def.max_level
	lbl.text = "%s  Lv %d/%d\n%s" % [def.name, level, def.max_level, def.desc]
	if maxed:
		btn.text = "MAX"
		btn.disabled = true
	elif SaveManager.data.total_credits < def.cost:
		btn.text = "%dcr" % def.cost
		btn.disabled = true
	else:
		btn.text = "%dcr" % def.cost
		btn.disabled = false

func _update_weapon_label(_lbl: Label, btn: Button, def: Dictionary) -> void:
	var owned: bool = SaveManager.data.unlocked_weapons.has(def.id)
	if owned:
		btn.text = "OWNED"
		btn.disabled = true
	elif SaveManager.data.total_credits < def.cost:
		btn.text = "%dcr" % def.cost
		btn.disabled = true
	else:
		btn.text = "%dcr" % def.cost
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

# ── KIT LIST ─────────────────────────────────────────────────────────────────

func _build_kits_list() -> void:
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

		var card := UITheme.make_card()
		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", UITheme.MARGIN_XS)
		card.add_child(card_vbox)

		# Kit info
		var info_row := HBoxContainer.new()
		card_vbox.add_child(info_row)

		var name_lbl := UITheme.make_label(kit_name, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_row.add_child(name_lbl)

		if owned:
			var tier_lbl := UITheme.make_label("T%d" % tier, UITheme.FONT_SMALL, UITheme.ACCENT_CYAN)
			info_row.add_child(tier_lbl)

		var desc_lbl := UITheme.make_label(kit_desc, UITheme.FONT_SMALL, UITheme.TEXT_SECONDARY)
		card_vbox.add_child(desc_lbl)

		# Action buttons
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", UITheme.MARGIN_XS)
		card_vbox.add_child(btn_row)

		if not owned:
			var cost: int = KIT_UNLOCK_COSTS.get(kit_id, 999)
			var unlock_btn := Button.new()
			unlock_btn.text = "Unlock %dcr" % cost
			unlock_btn.custom_minimum_size = Vector2(120, 36)
			UITheme.style_button(unlock_btn, UITheme.ACCENT_GREEN, UITheme.FONT_SMALL)
			unlock_btn.disabled = SaveManager.data.total_credits < cost
			unlock_btn.pressed.connect(_on_kit_unlock.bind(kit_id, cost))
			btn_row.add_child(unlock_btn)
		else:
			if tier < 2:
				var costs: Array = KIT_TIER_COSTS.get(kit_id, [0, 100, 200])
				var t2_cost: int = costs[1] if costs.size() > 1 else 100
				var t2_btn := Button.new()
				t2_btn.text = "T2 %dcr" % t2_cost
				t2_btn.custom_minimum_size = Vector2(100, 36)
				UITheme.style_button(t2_btn, UITheme.ACCENT_PURPLE, UITheme.FONT_SMALL)
				t2_btn.disabled = SaveManager.data.total_credits < t2_cost
				t2_btn.pressed.connect(_on_kit_tier_upgrade.bind(kit_id, 2, t2_cost))
				btn_row.add_child(t2_btn)
			elif tier == 2:
				var costs: Array = KIT_TIER_COSTS.get(kit_id, [0, 100, 200])
				var t3_cost: int = costs[2] if costs.size() > 2 else 200
				var t3_btn := Button.new()
				t3_btn.text = "T3 %dcr" % t3_cost
				t3_btn.custom_minimum_size = Vector2(100, 36)
				UITheme.style_button(t3_btn, UITheme.ACCENT_PURPLE, UITheme.FONT_SMALL)
				t3_btn.disabled = SaveManager.data.total_credits < t3_cost
				t3_btn.pressed.connect(_on_kit_tier_upgrade.bind(kit_id, 3, t3_cost))
				btn_row.add_child(t3_btn)
			else:
				var path_label: String = "(%s)" % t3_choice.capitalize() if t3_choice != "" else "(pending)"
				var maxed_lbl := UITheme.make_label("MAX %s" % path_label, UITheme.FONT_SMALL, UITheme.ACCENT_GOLD)
				btn_row.add_child(maxed_lbl)

			# Assign to slot buttons
			var s1_btn := Button.new()
			s1_btn.text = "S1"
			s1_btn.custom_minimum_size = Vector2(48, 36)
			UITheme.style_button_ghost(s1_btn, UITheme.FONT_SMALL)
			s1_btn.pressed.connect(_on_kit_assign.bind(kit_id, 0))
			btn_row.add_child(s1_btn)

			var s2_btn := Button.new()
			s2_btn.text = "S2"
			s2_btn.custom_minimum_size = Vector2(48, 36)
			UITheme.style_button_ghost(s2_btn, UITheme.FONT_SMALL)
			s2_btn.pressed.connect(_on_kit_assign.bind(kit_id, 1))
			btn_row.add_child(s2_btn)

		kits_scroll_vbox.add_child(card)

# ── KIT/UPGRADE HANDLERS ────────────────────────────────────────────────────

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

# ── TAB SWITCHING ────────────────────────────────────────────────────────────

func _show_ship_tab() -> void:
	ship_tab_content.visible = true
	upgrades_tab_content.visible = false
	kits_tab_content.visible = false
	UITheme.set_tab_active(ship_tab_btn, true, UITheme.ACCENT_CYAN)
	UITheme.set_tab_active(upgrades_tab_btn, false, UITheme.ACCENT_ORANGE)
	UITheme.set_tab_active(kits_tab_btn, false, UITheme.ACCENT_PURPLE)
	_show_hunt_summary()
	_update_pantry_visual()
	_update_rep_bars()
	_build_kitchen()

func _show_upgrades_tab() -> void:
	ship_tab_content.visible = false
	upgrades_tab_content.visible = true
	kits_tab_content.visible = false
	UITheme.set_tab_active(ship_tab_btn, false, UITheme.ACCENT_CYAN)
	UITheme.set_tab_active(upgrades_tab_btn, true, UITheme.ACCENT_ORANGE)
	UITheme.set_tab_active(kits_tab_btn, false, UITheme.ACCENT_PURPLE)
	_refresh_shop()

func _show_kits_tab() -> void:
	ship_tab_content.visible = false
	upgrades_tab_content.visible = false
	kits_tab_content.visible = true
	UITheme.set_tab_active(ship_tab_btn, false, UITheme.ACCENT_CYAN)
	UITheme.set_tab_active(upgrades_tab_btn, false, UITheme.ACCENT_ORANGE)
	UITheme.set_tab_active(kits_tab_btn, true, UITheme.ACCENT_PURPLE)
	_build_kits_list()

# ── STATUS UPDATES ───────────────────────────────────────────────────────────

func _update_stats() -> void:
	var d := SaveManager.data
	stats_label.text = "%dcr  |  %d hunts  |  %d corruption" % [
		d.total_credits, d.contracts_completed, d.total_corruption
	]
	if is_instance_valid(onboarding_label):
		onboarding_label.visible = d.contracts_completed == 0 and GameData.hunt_result.is_empty()

func _update_pantry() -> void:
	_update_pantry_visual()

func _update_pantry_visual() -> void:
	for child in pantry_container.get_children():
		child.queue_free()

	var pantry: Dictionary = SaveManager.data.pantry
	var has_any: bool = false
	for key in pantry:
		if pantry[key] > 0:
			has_any = true
			break

	if not has_any:
		var empty_lbl := UITheme.make_label("(empty — kill elites to collect)", UITheme.FONT_SMALL, UITheme.TEXT_MUTED)
		pantry_container.add_child(empty_lbl)
		return

	const ING_ORDER: Array = ["rift_dust", "void_crystal", "cave_moss", "river_silt", "elite_core"]
	for ing_id in ING_ORDER:
		var count: int = pantry.get(ing_id, 0)
		var color: Color = UITheme.PANTRY_COLORS.get(ing_id, Color.WHITE)
		var short_name: String = ing_id.replace("_", " ").capitalize().left(8)
		var badge := UITheme.make_ingredient_badge(count, color, short_name)
		pantry_container.add_child(badge)

func _show_hunt_summary() -> void:
	var result: Dictionary = GameData.hunt_result
	if result.is_empty():
		hunt_summary_panel.visible = false
		return

	hunt_summary_panel.visible = true
	onboarding_label.visible = false

	var lines: Array = ["Last Hunt"]
	var credits: int = result.get("credits", 0)
	if credits > 0:
		lines.append("+%d credits" % credits)

	var ings: Array = result.get("ingredients", [])
	if ings.size() > 0:
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
		lines.append("+%d corruption" % corr)

	hunt_summary_label.text = "\n".join(lines)

func _update_rep_bars() -> void:
	for child in rep_bars_container.get_children():
		child.queue_free()

	var rep: Dictionary = SaveManager.data.reputation
	for track in TRACK_ORDER:
		var pts: int = rep.get(track, 0)
		var level: int = SaveData.get_rep_level(track, rep)
		var color: Color = UITheme.TRACK_COLORS.get(track, Color.WHITE)
		var display_name: String = track.replace("_", " ").capitalize()

		var thresholds: Array = SaveData.REP_THRESHOLDS
		var bar_frac: float = 1.0
		var next_pts: int = 0
		var prev_pts: int = 0
		if level < thresholds.size() - 1:
			next_pts = thresholds[level + 1]
			prev_pts = thresholds[level]
			bar_frac = clampf(float(pts - prev_pts) / float(next_pts - prev_pts), 0.0, 1.0)

		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		var label_row := HBoxContainer.new()
		var name_lbl := UITheme.make_label("%s  Lv%d" % [display_name, level], UITheme.FONT_SMALL, color)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_row.add_child(name_lbl)

		var pts_lbl: Label
		if level >= thresholds.size() - 1:
			pts_lbl = UITheme.make_label("MAX", UITheme.FONT_TINY, UITheme.ACCENT_GOLD)
		else:
			pts_lbl = UITheme.make_label("%d/%d" % [pts, next_pts], UITheme.FONT_TINY, UITheme.TEXT_MUTED)
		label_row.add_child(pts_lbl)
		row.add_child(label_row)

		var bar := UITheme.make_progress_bar(bar_frac, color, UITheme.BG_DARK, 6)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bar)

		rep_bars_container.add_child(row)

func _update_rep_display() -> void:
	_update_rep_bars()

# ── KITCHEN ──────────────────────────────────────────────────────────────────

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
		var track_color: Color = UITheme.TRACK_COLORS.get(track, Color.WHITE)
		var track_lbl := UITheme.make_label(track.replace("_", " ").capitalize(), UITheme.FONT_SMALL, track_color)
		kitchen_scroll_vbox.add_child(track_lbl)

		var locked_count: int = 0
		for recipe_id in RECIPES:
			var recipe: Dictionary = RECIPES[recipe_id]
			if recipe.track != track:
				continue
			var unlocked: bool = _is_recipe_unlocked(recipe_id)
			if not unlocked:
				locked_count += 1
				continue

			var card := UITheme.make_card()
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", UITheme.MARGIN_SM)
			card.add_child(row)

			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_constant_override("separation", 1)
			row.add_child(info)

			var display_name: String = RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id)
			var name_lbl := UITheme.make_label(display_name, UITheme.FONT_BODY, UITheme.TEXT_PRIMARY)
			info.add_child(name_lbl)

			var cost_str := ""
			for ing_id in recipe.cost:
				if not cost_str.is_empty():
					cost_str += ", "
				cost_str += "%s x%d" % [ing_id.replace("_", " ").capitalize(), recipe.cost[ing_id]]
			var detail_text: String = "%s  +%drep" % [cost_str, recipe.rep]
			var bonus_str: String = BONUS_DESCS.get(recipe.bonus, "")
			if not bonus_str.is_empty():
				detail_text += "  %s" % bonus_str
			var detail_lbl := UITheme.make_label(detail_text, UITheme.FONT_TINY, UITheme.TEXT_SECONDARY)
			detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(detail_lbl)

			var can_afford: bool = _can_afford_recipe(recipe_id)
			if not can_afford:
				name_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)

			var btn := Button.new()
			btn.text = "Cook"
			btn.custom_minimum_size = Vector2(64, 36)
			UITheme.style_button(btn, track_color, UITheme.FONT_SMALL)
			btn.disabled = not can_afford
			btn.pressed.connect(_on_cook_recipe.bind(recipe_id))
			row.add_child(btn)

			kitchen_scroll_vbox.add_child(card)

		if locked_count > 0:
			var locked_lbl := UITheme.make_label(
				"+ %d locked — complete contracts to unlock" % locked_count,
				UITheme.FONT_TINY, UITheme.TEXT_MUTED
			)
			kitchen_scroll_vbox.add_child(locked_lbl)

		kitchen_scroll_vbox.add_child(UITheme.make_separator())

func _on_cook_recipe(recipe_id: String) -> void:
	var recipe: Dictionary = RECIPES[recipe_id]
	if not _is_recipe_unlocked(recipe_id) or not _can_afford_recipe(recipe_id):
		return

	for ing_id in recipe.cost:
		var needed: int = recipe.cost[ing_id]
		SaveManager.data.pantry[ing_id] = SaveManager.data.pantry.get(ing_id, 0) - needed

	var track: String = recipe.track
	var old_level: int = SaveData.get_rep_level(track, SaveManager.data.reputation)
	SaveManager.data.reputation[track] = SaveManager.data.reputation.get(track, 0) + recipe.rep
	var new_level: int = SaveData.get_rep_level(track, SaveManager.data.reputation)

	if not recipe.bonus.is_empty():
		SaveManager.data.active_bonuses[recipe.bonus] = true

	_check_tier2_unlocks()
	SaveManager.save_game()

	var display_name: String = RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id)
	cook_status_label.text = "Cooked %s! +%d %s rep" % [display_name, recipe.rep, track.replace("_", " ").capitalize()]

	if new_level > old_level:
		cook_status_label.text += " — Level Up! Lv%d" % new_level

	_update_pantry_visual()
	_update_rep_bars()
	_build_kitchen()
	_update_stats()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")
