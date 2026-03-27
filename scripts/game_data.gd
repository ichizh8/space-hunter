extends Node

const CREATURE_TYPES := ["Void Leech", "Shadow Crawler", "Abyss Worm", "Nether Stalker", "Rift Parasite"]
const CONTRACT_NAMES_PREFIX := ["Exterminate", "Purge", "Eliminate", "Hunt Down", "Eradicate"]

var current_contract: Dictionary = {}
var hunt_result: Dictionary = {}
var starting_weapon: String = "sidearm"
var equipped_kits: Array[String] = ["stim_pack", "flash_trap"]
var kit_tiers: Dictionary = {}
var kit_t3_choices: Dictionary = {}
var kit_t2_paths: Dictionary = {}

func generate_contracts(count: int = 3) -> Array[Dictionary]:
	var contracts: Array[Dictionary] = []
	for i in count:
		var creature_type: String = CREATURE_TYPES[randi() % CREATURE_TYPES.size()]
		var depth: int = randi_range(1, 3)
		var base_reward: int = depth * 50 + randi_range(10, 40)
		var prefix: String = CONTRACT_NAMES_PREFIX[randi() % CONTRACT_NAMES_PREFIX.size()]
		contracts.append({
			"name": "%s the %ss" % [prefix, creature_type],
			"creature_type": creature_type,
			"depth": depth,
			"reward": base_reward,
		})
	return contracts

func set_current_contract(contract: Dictionary) -> void:
	current_contract = contract

func set_hunt_result(credits: int, corruption: int, items: int, ingredients: Array[Dictionary] = []) -> void:
	hunt_result = {
		"credits": credits,
		"corruption": corruption,
		"items": items,
		"ingredients": ingredients,
	}
