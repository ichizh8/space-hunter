extends Node

const SAVE_PATH := "user://space_hunter_save.cfg"

var data: SaveData = SaveData.new()

func _ready() -> void:
	load_game()

func save_game() -> void:
	var config := ConfigFile.new()
	var dict := data.to_dict()
	for key in dict:
		config.set_value("save", key, dict[key])
	config.save(SAVE_PATH)

func load_game() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		data = SaveData.new()
		return
	var dict := {}
	for key in config.get_section_keys("save"):
		dict[key] = config.get_value("save", key)
	data.from_dict(dict)

func complete_contract(credits: int, corruption: int) -> void:
	data.total_credits += credits
	data.total_corruption += corruption
	data.contracts_completed += 1
	save_game()

func buy_upgrade(upgrade_id: String, cost: int) -> bool:
	if data.total_credits < cost:
		return false
	data.total_credits -= cost
	data.ship_upgrades[upgrade_id] += 1
	save_game()
	return true

func add_stock(item_id: String, amount: int) -> void:
	var current: int = data.stock.get(item_id, 0)
	data.stock[item_id] = current + amount
	save_game()

func consume_stock(item_id: String) -> bool:
	var current: int = data.stock.get(item_id, 0)
	if current <= 0:
		return false
	data.stock[item_id] = current - 1
	save_game()
	return true

func add_ingredients(arr: Array) -> void:
	for item in arr:
		var ingredient_id: String = item.get("id", "").replace("ingredient_", "")
		if ingredient_id.is_empty():
			continue
		data.ingredients[ingredient_id] = data.ingredients.get(ingredient_id, 0) + 1
		# Also add to pantry if it's a known pantry ingredient
		if data.pantry.has(ingredient_id):
			data.pantry[ingredient_id] = data.pantry.get(ingredient_id, 0) + 1
	save_game()
