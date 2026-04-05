class_name SaveData
extends RefCounted

var total_credits: int = 0
var total_corruption: int = 0
var contracts_completed: int = 0
var ingredients: Dictionary = {}  # ingredient_id -> count, e.g. {"void_extract": 2}
var pantry: Dictionary = {
	"rift_dust": 0,
	"void_crystal": 0,
	"cave_moss": 0,
	"river_silt": 0,
	"elite_core": 0,
}
var ship_upgrades: Dictionary = {
	"max_hp": 0,        # levels 0-3, each +2 HP
	"mag_size": 0,      # levels 0-3, each +3 mag
	"xp_rate": 0,       # levels 0-3, each +10% essence gain
	"loadout_slots": 0, # levels 0-2, each +1 slot (start 4, max 6)
	"kit_slots": 0,     # levels 0-2 (2 base + level = total kit slots)
}
var unlocked_weapons: Array = ["sidearm", "scatter", "lance", "baton", "dart", "entropy_cannon", "flamethrower", "sniper_carbine", "grenade_launcher", "pulse_cannon", "chain_rifle"]
var loadout: Array = []
var stock: Dictionary = {
	"field_stim": 3,
	"trap": 2,
}
var equipped_kits: Array = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {"stim_pack": 1, "flash_trap": 1}
var unlocked_kits: Array = ["stim_pack", "flash_trap"]
var kit_t3_choices: Dictionary = {}  # kit_id -> "clean" or "void"
var kit_t2_paths: Dictionary = {}  # kit_id -> "attack"|"shield"|"harvest"
var active_bonuses: Dictionary = {}  # bonus_id -> true/int, consumed at hunt start

# Phase A: recipe unlocks — Tier 1 unlocked from start
var unlocked_recipes: Array = ["field_ration", "void_brew", "cave_jerky", "silt_stew"]

# Phase A: reputation tracks
var reputation: Dictionary = {
	"contractor": 0,
	"void_walker": 0,
	"tactician": 0,
	"scrapper": 0,
}

var version: int = 1

const REP_THRESHOLDS: Array = [0, 50, 150, 350, 700, 1200]

func max_kit_slots() -> int:
	return 2 + ship_upgrades.get("kit_slots", 0)

func get_available_weapons() -> Array:
	var always: Array = ["sidearm", "scatter", "lance", "baton", "dart", "flamethrower", "grenade_launcher"]
	var result: Array = always.duplicate()
	# Rep-gated weapons
	if get_rep_level("void_walker", reputation) >= 2:
		result.append("entropy_cannon")
	if get_rep_level("tactician", reputation) >= 2:
		result.append("pulse_cannon")
	if get_rep_level("contractor", reputation) >= 3:
		result.append("sniper_carbine")
	if get_rep_level("scrapper", reputation) >= 2:
		result.append("chain_rifle")
	return result

static func get_rep_level(track: String, rep_data: Dictionary) -> int:
	var pts: int = rep_data.get(track, 0)
	var level: int = 0
	for i in range(1, REP_THRESHOLDS.size()):
		if pts >= REP_THRESHOLDS[i]:
			level = i
		else:
			break
	return level

func to_dict() -> Dictionary:
	return {
		"version": version,
		"total_credits": total_credits,
		"total_corruption": total_corruption,
		"contracts_completed": contracts_completed,
		"ingredients": ingredients.duplicate(),
		"pantry": pantry.duplicate(),
		"ship_upgrades": ship_upgrades.duplicate(),
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"loadout": loadout.duplicate(),
		"stock": stock.duplicate(),
		"equipped_kits": equipped_kits.duplicate(),
		"kit_tiers": kit_tiers.duplicate(),
		"unlocked_kits": unlocked_kits.duplicate(),
		"kit_t3_choices": kit_t3_choices.duplicate(),
		"kit_t2_paths": kit_t2_paths.duplicate(),
		"unlocked_recipes": unlocked_recipes.duplicate(),
		"reputation": reputation.duplicate(),
		"active_bonuses": active_bonuses.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	version = data.get("version", 1)
	total_credits = data.get("total_credits", 0)
	total_corruption = data.get("total_corruption", 0)
	contracts_completed = data.get("contracts_completed", 0)
	var raw_ingredients: Variant = data.get("ingredients", {})
	if raw_ingredients is Dictionary:
		ingredients = (raw_ingredients as Dictionary).duplicate()
	else:
		ingredients = {}

	var raw_pantry: Variant = data.get("pantry", {})
	if raw_pantry is Dictionary:
		var loaded_pantry: Dictionary = (raw_pantry as Dictionary).duplicate()
		for key in pantry:
			if loaded_pantry.has(key):
				pantry[key] = loaded_pantry[key]

	var raw_upgrades: Variant = data.get("ship_upgrades", {})
	if raw_upgrades is Dictionary:
		var loaded: Dictionary = (raw_upgrades as Dictionary).duplicate()
		for key in ship_upgrades:
			if loaded.has(key):
				ship_upgrades[key] = loaded[key]
	var raw_weapons: Variant = data.get("unlocked_weapons", [])
	if raw_weapons is Array:
		unlocked_weapons.clear()
		for w in raw_weapons:
			unlocked_weapons.append(str(w))
		# Always ensure all weapons are unlocked for testing
		for _test_wep in ["sidearm", "scatter", "lance", "baton", "dart", "entropy_cannon", "flamethrower", "sniper_carbine", "grenade_launcher", "pulse_cannon", "chain_rifle"]:
			if not unlocked_weapons.has(_test_wep):
				unlocked_weapons.append(_test_wep)
	var raw_loadout: Variant = data.get("loadout", [])
	if raw_loadout is Array:
		loadout.clear()
		for item in raw_loadout:
			if item is Dictionary:
				loadout.append(item)
	var raw_stock: Variant = data.get("stock", {})
	if raw_stock is Dictionary:
		stock = (raw_stock as Dictionary).duplicate()
	else:
		stock = {"field_stim": 3, "trap": 2}

	var raw_kits: Variant = data.get("equipped_kits", [])
	if raw_kits is Array:
		equipped_kits.clear()
		for k in raw_kits: equipped_kits.append(str(k))
	if equipped_kits.is_empty(): equipped_kits = ["stim_pack", "flash_trap"]

	var raw_kit_tiers: Variant = data.get("kit_tiers", {})
	if raw_kit_tiers is Dictionary: kit_tiers = (raw_kit_tiers as Dictionary).duplicate()
	if kit_tiers.is_empty(): kit_tiers = {"stim_pack": 1, "flash_trap": 1}

	var raw_unlocked_kits: Variant = data.get("unlocked_kits", [])
	if raw_unlocked_kits is Array:
		unlocked_kits.clear()
		for k in raw_unlocked_kits: unlocked_kits.append(str(k))
	if unlocked_kits.is_empty(): unlocked_kits = ["stim_pack", "flash_trap"]

	var raw_t3: Variant = data.get("kit_t3_choices", {})
	if raw_t3 is Dictionary: kit_t3_choices = (raw_t3 as Dictionary).duplicate()

	var raw_t2p: Variant = data.get("kit_t2_paths", {})
	if raw_t2p is Dictionary: kit_t2_paths = (raw_t2p as Dictionary).duplicate()

	var raw_recipes: Variant = data.get("unlocked_recipes", [])
	if raw_recipes is Array:
		unlocked_recipes.clear()
		for r in raw_recipes: unlocked_recipes.append(str(r))
	if unlocked_recipes.is_empty():
		unlocked_recipes = ["field_ration", "void_brew", "cave_jerky", "silt_stew"]

	var raw_bonuses: Variant = data.get("active_bonuses", {})
	if raw_bonuses is Dictionary:
		active_bonuses = (raw_bonuses as Dictionary).duplicate()

	var raw_rep: Variant = data.get("reputation", {})
	if raw_rep is Dictionary:
		var loaded_rep: Dictionary = (raw_rep as Dictionary).duplicate()
		for key in reputation:
			if loaded_rep.has(key):
				reputation[key] = loaded_rep[key]
