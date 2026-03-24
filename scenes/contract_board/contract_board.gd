extends Control

const CREATURES := ["void-leech", "shadow-crawler", "abyss-worm", "nether-stalker", "rift-parasite"]
const CREATURE_NAMES := {
	"void-leech": "Void Leech",
	"shadow-crawler": "Shadow Crawler",
	"abyss-worm": "Abyss Worm",
	"nether-stalker": "Nether Stalker",
	"rift-parasite": "Rift Parasite",
}

@onready var contract_list: VBoxContainer = %ContractList
@onready var title_label: Label = %TitleLabel
@onready var credits_label: Label = %CreditsLabel
@onready var corruption_label: Label = %CorruptionLabel

var contracts: Array[Dictionary] = []


func _ready() -> void:
	_generate_contracts()
	_update_status()


func _update_status() -> void:
	credits_label.text = "Credits: %d" % ContractManager.total_credits
	corruption_label.text = "Corruption: %d" % ContractManager.total_corruption
	corruption_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))


func _generate_contracts() -> void:
	randomize()
	contracts.clear()
	var shuffled := CREATURES.duplicate()
	shuffled.shuffle()
	for i in range(3):
		var creature_slug: String = shuffled[i % shuffled.size()]
		var creature_name: String = CREATURE_NAMES[creature_slug]
		var depth: int = randi_range(1, 3)
		var reward: int = depth * 50 + randi_range(10, 40)
		contracts.append({
			"creature": creature_slug,
			"creature_name": creature_name,
			"depth": depth,
			"reward": reward,
			"name": "Hunt %ss" % creature_name,
		})
	_build_buttons()


func _build_buttons() -> void:
	for child in contract_list.get_children():
		child.queue_free()
	for i in range(contracts.size()):
		var contract: Dictionary = contracts[i]
		var btn := Button.new()
		btn.text = "%s\nDepth %d  ·  %d credits" % [contract["name"], contract["depth"], contract["reward"]]
		btn.custom_minimum_size = Vector2(0, 80)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_contract_selected.bind(i))
		contract_list.add_child(btn)


func _on_contract_selected(index: int) -> void:
	ContractManager.set_contract(contracts[index])
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
