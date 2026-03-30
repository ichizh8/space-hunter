extends Control

var selected_weapon: String = "sidearm"
var go_btn: Button = null
var weapon_buttons: Dictionary = {}  # wid -> Button

const WEAPON_DISPLAY_NAMES: Dictionary = {
	"sidearm": "Pistol", "scatter": "Scatter", "lance": "Lance",
	"baton": "Baton", "dart": "Dart", "entropy_cannon": "Entropy",
	"flamethrower": "Flamer", "sniper_carbine": "Sniper",
	"grenade_launcher": "Grenade", "pulse_cannon": "Pulse", "chain_rifle": "Chain",
}

const ALL_WEAPONS: Array = ["sidearm", "scatter", "lance", "baton", "dart", "entropy_cannon", "flamethrower", "sniper_carbine", "grenade_launcher", "pulse_cannon", "chain_rifle"]

func _ready() -> void:
	var contract: Dictionary = GameData.current_contract

	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = UITheme.MARGIN_LG
	vbox.offset_right = -UITheme.MARGIN_LG
	vbox.offset_top = UITheme.MARGIN_LG
	vbox.offset_bottom = -UITheme.MARGIN_LG
	vbox.add_theme_constant_override("separation", UITheme.MARGIN_MD)
	add_child(vbox)

	# Title
	var title := UITheme.make_label("LOADOUT", UITheme.FONT_TITLE, UITheme.ACCENT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Contract name
	var sub := UITheme.make_label(contract.get("name", "Hunt"), UITheme.FONT_BODY, UITheme.ACCENT_CYAN)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	vbox.add_child(UITheme.make_separator())

	# Weapon section
	vbox.add_child(UITheme.make_section_header("WEAPON", UITheme.ACCENT_ORANGE))

	# Weapon grid — 3 per row
	var available_weapons: Array = SaveManager.data.get_available_weapons()
	var row: HBoxContainer = null
	for i in available_weapons.size():
		if i % 3 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", UITheme.MARGIN_SM)
			vbox.add_child(row)
		var wid: String = available_weapons[i]
		var btn := Button.new()
		btn.text = WEAPON_DISPLAY_NAMES.get(wid, wid)
		btn.custom_minimum_size = Vector2(100, UITheme.BUTTON_MIN_H)
		if wid == selected_weapon:
			UITheme.style_button_primary(btn, UITheme.ACCENT_ORANGE, UITheme.FONT_SMALL)
		else:
			UITheme.style_button(btn, UITheme.ACCENT_CYAN, UITheme.FONT_SMALL)
		btn.pressed.connect(_select_weapon.bind(wid))
		row.add_child(btn)
		weapon_buttons[wid] = btn

	vbox.add_child(UITheme.make_separator())

	# Kit info
	vbox.add_child(UITheme.make_section_header("KITS", UITheme.ACCENT_PURPLE))
	var kits: Array = SaveManager.data.equipped_kits
	var kit_names: Array = []
	for kid in kits:
		kit_names.append(kid.replace("_", " ").capitalize())
	var kit_lbl := UITheme.make_label(", ".join(kit_names), UITheme.FONT_BODY, UITheme.ACCENT_GREEN)
	kit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(kit_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Bottom buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", UITheme.MARGIN_LG)
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(120, 56)
	UITheme.style_button_ghost(back_btn, UITheme.FONT_HEADING)
	back_btn.pressed.connect(_go_back)
	btn_row.add_child(back_btn)

	go_btn = Button.new()
	go_btn.text = "GO HUNT"
	go_btn.custom_minimum_size = Vector2(160, 56)
	UITheme.style_button_primary(go_btn, UITheme.ACCENT_GREEN, UITheme.FONT_HEADING)
	go_btn.pressed.connect(_go_hunt)
	btn_row.add_child(go_btn)

func _select_weapon(wid: String) -> void:
	selected_weapon = wid
	# Update button styles
	for w in weapon_buttons:
		var btn: Button = weapon_buttons[w]
		if w == wid:
			UITheme.style_button_primary(btn, UITheme.ACCENT_ORANGE, UITheme.FONT_SMALL)
		else:
			UITheme.style_button(btn, UITheme.ACCENT_CYAN, UITheme.FONT_SMALL)

func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _go_hunt() -> void:
	GameData.starting_weapon = selected_weapon
	var kits: Array = SaveManager.data.equipped_kits
	GameData.equipped_kits = kits.duplicate()
	GameData.kit_tiers = SaveManager.data.kit_tiers.duplicate()
	GameData.kit_t3_choices = SaveManager.data.kit_t3_choices.duplicate()
	GameData.kit_t2_paths = SaveManager.data.kit_t2_paths.duplicate()
	SaveManager.data.loadout = []
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/Hunt.tscn")
