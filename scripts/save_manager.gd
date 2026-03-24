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
