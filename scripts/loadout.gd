extends Control

var selected_weapon: String = "sidearm"
var go_btn: Button = null

const WEAPON_DISPLAY_NAMES: Dictionary = {
	"sidearm": "Pistol",
	"scatter": "Scatter",
	"lance": "Lance",
	"baton": "Baton",
	"dart": "Dart",
	"entropy_cannon": "Entropy",
	"pulse_cannon": "Pulse",
	"sniper_carbine": "Sniper",
	"chain_rifle": "Chain",
}

const ALL_WEAPONS: Array = ["sidearm", "scatter", "lance", "baton", "dart", "entropy_cannon", "pulse_cannon", "sniper_carbine", "chain_rifle"]

func _ready() -> void:
	var contract: Dictionary = GameData.current_contract

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "LOADOUT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Contract name
	var sub := Label.new()
	sub.text = contract.get("name", "Hunt")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	# Weapon label
	var wlbl := Label.new()
	wlbl.text = "Choose Weapon:"
	wlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(wlbl)

	# Weapon buttons — 3 per row
	var row: HBoxContainer = null
	for i in ALL_WEAPONS.size():
		if i % 3 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 6)
			vbox.add_child(row)
		var wid: String = ALL_WEAPONS[i]
		var btn := Button.new()
		btn.text = WEAPON_DISPLAY_NAMES.get(wid, wid)
		btn.custom_minimum_size = Vector2(90, 40)
		btn.pressed.connect(_select_weapon.bind(wid, btn))
		row.add_child(btn)

	vbox.add_child(HSeparator.new())

	# Kit info
	var kit_lbl := Label.new()
	var kits: Array = SaveManager.data.equipped_kits
	kit_lbl.text = "Kits: %s" % ", ".join(kits)
	kit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kit_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	vbox.add_child(kit_lbl)

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(110, 55)
	back_btn.pressed.connect(_go_back)
	btn_row.add_child(back_btn)

	go_btn = Button.new()
	go_btn.text = "GO HUNT"
	go_btn.custom_minimum_size = Vector2(110, 55)
	go_btn.pressed.connect(_go_hunt)
	btn_row.add_child(go_btn)

func _select_weapon(wid: String, _btn: Button) -> void:
	selected_weapon = wid

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
