extends Node
# v47 — CI/CD pipeline test (auto-export + deploy via GitHub Actions)

const CREATURE_TYPES := ["Void Leech", "Shadow Crawler", "Abyss Worm", "Nether Stalker", "Rift Parasite"]
const CONTRACT_NAMES_PREFIX := ["Exterminate", "Purge", "Eliminate", "Hunt Down", "Eradicate"]

# Boss names for Boss Hunt contracts
const BOSS_NAMES := ["Rift Sovereign", "The Hollow", "Ancient Brood", "Abyssal Tide"]
const BOSS_BIOMES := ["open", "void_pool", "cave", "river_bank"]

# Contract type definitions
const CONTRACT_TYPES := ["hunt", "payload_escort", "void_breach", "boss_hunt", "extraction_run"]

const CONTRACT_TYPE_INFO: Dictionary = {
	"hunt": {label = "Hunt", icon_color = Color(0.9, 0.3, 0.3), desc = "Survive and eliminate targets"},
	"payload_escort": {label = "Payload Escort", icon_color = Color(0.3, 0.7, 0.9), desc = "Protect the cargo pod to the exit"},
	"void_breach": {label = "Void Breach", icon_color = Color(0.6, 0.1, 0.9), desc = "Hold position near the void rift"},
	"boss_hunt": {label = "Boss Hunt", icon_color = Color(1.0, 0.5, 0.0), desc = "Find and eliminate a named apex target"},
	"extraction_run": {label = "Extraction Run", icon_color = Color(0.2, 0.9, 0.4), desc = "Collect ingredient caches across biomes"},
}

var current_contract: Dictionary = {}
var hunt_result: Dictionary = {}
var starting_weapon: String = "sidearm"
var equipped_kits: Array = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {}
var kit_t3_choices: Dictionary = {}
var kit_t2_paths: Dictionary = {}

func generate_contracts(count: int = 3) -> Array:
	var contracts: Array = []
	var available_types: Array = ["hunt", "payload_escort", "void_breach", "boss_hunt", "extraction_run"]
	available_types.shuffle()
	# Always include hunt
	if not available_types.slice(0, count).has("hunt"):
		available_types[0] = "hunt"
		available_types.shuffle()
	for i in count:
		var ctype: String = available_types[i % available_types.size()]
		contracts.append(_generate_contract_of_type(ctype))
	return contracts

func _generate_contract_of_type(ctype: String) -> Dictionary:
	var difficulty: int = randi_range(1, 3)
	var info: Dictionary = CONTRACT_TYPE_INFO[ctype]
	match ctype:
		"hunt":
			var creature_type: String = CREATURE_TYPES[randi() % CREATURE_TYPES.size()]
			var prefix: String = CONTRACT_NAMES_PREFIX[randi() % CONTRACT_NAMES_PREFIX.size()]
			var base_reward: int = difficulty * 50 + randi_range(10, 40)
			return {
				"type": "hunt",
				"name": "%s the %ss" % [prefix, creature_type],
				"creature_type": creature_type,
				"depth": difficulty,
				"difficulty": difficulty,
				"reward": base_reward,
				"par_time": 300.0,
				"desc": info.desc,
				"label": info.label,
				"icon_color": info.icon_color,
				"special_reward": "",
			}
		"payload_escort":
			return {
				"type": "payload_escort",
				"name": "Payload: Cargo Run %s" % ["Alpha", "Beta", "Gamma"][randi() % 3],
				"difficulty": difficulty,
				"depth": difficulty,
				"reward": 600 + (difficulty - 1) * 100,
				"par_time": 240.0,
				"desc": info.desc,
				"label": info.label,
				"icon_color": info.icon_color,
				"pod_hp": 200 + difficulty * 50,
				"pod_speed": 40.0,
				"special_reward": "Tier 2 recipe" if difficulty >= 2 else "",
			}
		"void_breach":
			var hold_time: float = 120.0 + difficulty * 30.0
			return {
				"type": "void_breach",
				"name": "Void Breach: Sector %d" % randi_range(1, 99),
				"difficulty": difficulty,
				"depth": difficulty,
				"reward": 500 + (difficulty - 1) * 80,
				"par_time": 180.0,
				"desc": info.desc,
				"label": info.label,
				"icon_color": info.icon_color,
				"hold_time": hold_time,
				"special_reward": "Void Walker rep bonus",
			}
		"boss_hunt":
			var boss_idx: int = randi() % BOSS_NAMES.size()
			return {
				"type": "boss_hunt",
				"name": "Target: %s" % BOSS_NAMES[boss_idx],
				"difficulty": difficulty,
				"depth": difficulty,
				"reward": 800 + (difficulty - 1) * 120,
				"par_time": 300.0,
				"desc": info.desc,
				"label": info.label,
				"icon_color": info.icon_color,
				"boss_name": BOSS_NAMES[boss_idx],
				"boss_biome": BOSS_BIOMES[boss_idx],
				"special_reward": "2x Elite Core + Tier 3 recipe",
			}
		"extraction_run":
			return {
				"type": "extraction_run",
				"name": "Extraction: %s Route" % ["Northern", "Southern", "Eastern", "Deep"][randi() % 4],
				"difficulty": difficulty,
				"depth": difficulty,
				"reward": 700 + (difficulty - 1) * 90,
				"par_time": 360.0,
				"desc": info.desc,
				"label": info.label,
				"icon_color": info.icon_color,
				"cache_count": 3,
				"special_reward": "All ingredients kept + rep bonus",
			}
	# Fallback
	return {"type": "hunt", "name": "Hunt", "difficulty": 1, "depth": 1, "reward": 50, "par_time": 300.0, "desc": "", "label": "Hunt", "icon_color": Color.WHITE, "special_reward": ""}

func set_current_contract(contract: Dictionary) -> void:
	current_contract = contract

func set_hunt_result(credits: int, corruption: int, items: int, ingredients: Array = [], extras: Dictionary = {}) -> void:
	hunt_result = {
		"credits": credits,
		"corruption": corruption,
		"items": items,
		"ingredients": ingredients,
		"contract_name": extras.get("contract_name", "Hunt"),
		"hunt_status": extras.get("hunt_status", "COMPLETED"),
		"time_survived": extras.get("time_survived", 0.0),
		"total_kills": extras.get("total_kills", 0),
		"damage_dealt": extras.get("damage_dealt", 0),
		"peak_corruption": extras.get("peak_corruption", corruption),
		"elite_kills": extras.get("elite_kills", 0),
	}
