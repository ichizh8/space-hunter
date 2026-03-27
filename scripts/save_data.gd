class_name SaveData
extends RefCounted

var total_credits: int = 0
var total_corruption: int = 0
var contracts_completed: int = 0
var ingredients: Dictionary = {}  # ingredient_id -> count, e.g. {"void_extract": 2}
var ship_upgrades: Dictionary = {
	"max_hp": 0,        # levels 0-3, each +2 HP
	"mag_size": 0,      # levels 0-3, each +3 mag
	"xp_rate": 0,       # levels 0-3, each +10% essence gain
	"loadout_slots": 0, # levels 0-2, each +1 slot (start 4, max 6)
}
var unlocked_weapons: Array[String] = ["sidearm"]
var loadout: Array[Dictionary] = []
var stock: Dictionary = {
	"field_stim": 3,
	"trap": 2,
}
var equipped_kits: Array[String] = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {"stim_pack": 1, "flash_trap": 1}
var unlocked_kits: Array[String] = ["stim_pack", "flash_trap"]
var version: int = 1

func to_dict() -> Dictionary:
	return {
		"version": version,
		"total_credits": total_credits,
		"total_corruption": total_corruption,
		"contracts_completed": contracts_completed,
		"ingredients": ingredients.duplicate(),
		"ship_upgrades": ship_upgrades.duplicate(),
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"loadout": loadout.duplicate(),
		"stock": stock.duplicate(),
		"equipped_kits": equipped_kits.duplicate(),
		"kit_tiers": kit_tiers.duplicate(),
		"unlocked_kits": unlocked_kits.duplicate(),
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
		if unlocked_weapons.is_empty():
			unlocked_weapons.append("sidearm")
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
