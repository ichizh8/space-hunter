extends Control

var selected_weapon: String = "sidearm"
var chosen_consumables: Dictionary = {}  # item_id -> count chosen
var weapon_buttons: Array[Button] = []
var all_weapon_ids: Array[String] = []  # all 9 weapon IDs in display order
var consumable_labels: Dictionary = {}  # item_id -> Label
var slots_label: Label
var total_slots: int = 4
var kit_slot_labels: Array[Label] = []
var kit_picker_visible: int = -1  # -1 = hidden, 0/1 = slot being changed
var kit_picker_container: VBoxContainer = null
var main_vbox: VBoxContainer = null
var _pending_kit_rebuild: int = -1  # deferred kit picker rebuild slot

const STOCK_NAMES: Dictionary = {
	"field_stim": "Field Stim",
	"trap": "Trap",
}

const KIT_NAMES: Dictionary = {
	"stim_pack": "Stim",
	"flash_trap": "Trap",
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
	"void_surge": "Surge",
	"rupture_kit": "Rupture",
}

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

# All weapons in display order
const ALL_WEAPONS: Array[String] = ["sidearm", "scatter", "lance", "baton", "dart", "entropy_cannon", "pulse_cannon", "sniper_carbine", "chain_rifle"]

func _is_weapon_available(wid: String) -> bool:
	if Constants.DEBUG_UNLOCK_ALL_WEAPONS:
		return true
	if not Constants.WEAPON_UNLOCK_REQS.has(wid):
		return true  # starter weapons
	var req: Dictionary = Constants.WEAPON_UNLOCK_REQS[wid]
	var level: int = SaveData.get_rep_level(req.track, SaveManager.data.reputation)
	return level >= req.level

func _get_lock_text(wid: String) -> String:
	if not Constants.WEAPON_UNLOCK_REQS.has(wid):
		return ""
	var req: Dictionary = Constants.WEAPON_UNLOCK_REQS[wid]
	var track_name: String = Constants.REP_TRACK_NAMES.get(req.track, req.track)
	return "%s %d" % [track_name, req.level]

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

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = "Hunt Loadout"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Contract: %s | Depth %d" % [contract.get("name", "Unknown"), contract.get("depth", 1)]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(subtitle)

	var sep1 := HSeparator.new()
	main_vbox.add_child(sep1)

	# Starting weapon section
	var weapon_title := Label.new()
	weapon_title.text = "Starting Weapon:"
	main_vbox.add_child(weapon_title)

	# Show all 9 weapons in a grid (3 rows of 3)
	all_weapon_ids = ALL_WEAPONS.duplicate()
	selected_weapon = "sidearm"
	# Default to first available weapon
	for wid in all_weapon_ids:
		if _is_weapon_available(wid):
			selected_weapon = wid
			break

	var row_idx: int = 0
	var weapon_row: HBoxContainer = null
	for wi in range(all_weapon_ids.size()):
		if wi % 3 == 0:
			weapon_row = HBoxContainer.new()
			weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
			weapon_row.add_theme_constant_override("separation", 4)
			main_vbox.add_child(weapon_row)
		var wid: String = all_weapon_ids[wi]
		var available: bool = _is_weapon_available(wid)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(90, 36)
		if available:
			btn.text = WEAPON_DISPLAY_NAMES.get(wid, wid.capitalize())
			btn.pressed.connect(_on_weapon_selected.bind(wid))
		else:
			var lock_text: String = _get_lock_text(wid)
			btn.text = "%s [%s]" % [WEAPON_DISPLAY_NAMES.get(wid, wid.capitalize()), lock_text]
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)
		weapon_row.add_child(btn)
		weapon_buttons.append(btn)

	_update_weapon_highlight()

	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	# Equipped Kits section with Change buttons
	var kit_title := Label.new()
	kit_title.text = "Equipped Kits:"
	main_vbox.add_child(kit_title)

	var eq_kits: Array[String] = SaveManager.data.equipped_kits
	if eq_kits.is_empty():
		eq_kits = ["stim_pack", "flash_trap"]

	for ki in range(2):
		var kit_row := HBoxContainer.new()
		kit_row.alignment = BoxContainer.ALIGNMENT_CENTER
		kit_row.add_theme_constant_override("separation", 10)
		main_vbox.add_child(kit_row)

		var kit_id: String = eq_kits[ki] if ki < eq_kits.size() else ""
		var tier: int = SaveManager.data.kit_tiers.get(kit_id, 1)
		var t3c: String = SaveManager.data.kit_t3_choices.get(kit_id, "")
		var tier_str: String = " T%d" % tier
		if tier >= 3 and not t3c.is_empty():
			tier_str += " (%s)" % t3c.capitalize()

		var kit_lbl := Label.new()
		kit_lbl.text = "Slot %d: %s%s" % [ki + 1, KIT_NAMES.get(kit_id, kit_id.capitalize()), tier_str]
		kit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kit_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kit_row.add_child(kit_lbl)
		kit_slot_labels.append(kit_lbl)

		var change_btn := Button.new()
		change_btn.text = "Change"
		change_btn.custom_minimum_size = Vector2(80, 36)
		change_btn.pressed.connect(_on_kit_change.bind(ki))
		kit_row.add_child(change_btn)

	# Kit picker container (hidden initially)
	kit_picker_container = VBoxContainer.new()
	kit_picker_container.visible = false
	main_vbox.add_child(kit_picker_container)

	var sep2b := HSeparator.new()
	main_vbox.add_child(sep2b)

	# Consumables section
	var consumable_title := Label.new()
	consumable_title.text = "Consumables:"
	main_vbox.add_child(consumable_title)

	slots_label = Label.new()
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(slots_label)
	_update_slots_label()

	var stock: Dictionary = SaveManager.data.stock
	for item_id in stock:
		if stock[item_id] <= 0:
			continue
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		main_vbox.add_child(row)

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
	main_vbox.add_child(sep3)

	# Credits
	var credits_lbl := Label.new()
	credits_lbl.text = "Credits: %d" % SaveManager.data.total_credits
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(credits_lbl)

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_row)

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

# WASM-safe: use call_deferred for kit picker rebuild
func _on_kit_change(slot: int) -> void:
	_pending_kit_rebuild = slot
	call_deferred("_rebuild_kit_picker")

func _rebuild_kit_picker() -> void:
	var slot: int = _pending_kit_rebuild
	if slot < 0:
		return
	kit_picker_visible = slot
	# Clear old children
	for child in kit_picker_container.get_children():
		child.queue_free()

	var picker_lbl := Label.new()
	picker_lbl.text = "Select kit for Slot %d:" % (slot + 1)
	picker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kit_picker_container.add_child(picker_lbl)

	var unlocked_kits: Array[String] = SaveManager.data.unlocked_kits
	for kid in unlocked_kits:
		var tier: int = SaveManager.data.kit_tiers.get(kid, 1)
		var t3c: String = SaveManager.data.kit_t3_choices.get(kid, "")
		var desc: String = KIT_NAMES.get(kid, kid)
		if tier >= 3 and not t3c.is_empty():
			desc += " T%d (%s)" % [tier, t3c.capitalize()]
		else:
			desc += " T%d" % tier

		var pick_btn := Button.new()
		pick_btn.text = desc
		pick_btn.custom_minimum_size = Vector2(0, 36)
		pick_btn.pressed.connect(_on_kit_picked.bind(kid, slot))
		kit_picker_container.add_child(pick_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 36)
	cancel_btn.pressed.connect(_on_kit_picker_cancel)
	kit_picker_container.add_child(cancel_btn)

	kit_picker_container.visible = true

func _on_kit_picked(kit_id: String, slot: int) -> void:
	var eq: Array[String] = SaveManager.data.equipped_kits
	if eq.is_empty():
		eq = ["stim_pack", "flash_trap"]
	while eq.size() < 2:
		eq.append("")
	var other: int = 1 - slot
	if eq[other] == kit_id:
		eq[other] = eq[slot]
	eq[slot] = kit_id
	SaveManager.data.equipped_kits = eq
	SaveManager.save_game()

	# Update labels
	for ki in range(2):
		var kid: String = eq[ki]
		var tier: int = SaveManager.data.kit_tiers.get(kid, 1)
		var t3c: String = SaveManager.data.kit_t3_choices.get(kid, "")
		var tier_str: String = " T%d" % tier
		if tier >= 3 and not t3c.is_empty():
			tier_str += " (%s)" % t3c.capitalize()
		kit_slot_labels[ki].text = "Slot %d: %s%s" % [ki + 1, KIT_NAMES.get(kid, kid.capitalize()), tier_str]

	kit_picker_container.visible = false
	kit_picker_visible = -1

func _on_kit_picker_cancel() -> void:
	kit_picker_container.visible = false
	kit_picker_visible = -1

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
	for i in weapon_buttons.size():
		var wid: String = all_weapon_ids[i]
		if not _is_weapon_available(wid):
			continue  # locked buttons stay as-is
		if wid == selected_weapon:
			weapon_buttons[i].text = "> %s <" % WEAPON_DISPLAY_NAMES.get(wid, wid.capitalize())
		else:
			weapon_buttons[i].text = WEAPON_DISPLAY_NAMES.get(wid, wid.capitalize())

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _on_go_hunt() -> void:
	GameData.starting_weapon = selected_weapon
	GameData.equipped_kits = SaveManager.data.equipped_kits.duplicate()
	GameData.kit_tiers = SaveManager.data.kit_tiers.duplicate()
	GameData.kit_t3_choices = SaveManager.data.kit_t3_choices.duplicate()
	GameData.kit_t2_paths = SaveManager.data.kit_t2_paths.duplicate()

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
