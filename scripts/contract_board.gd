extends Control

@onready var contract_container: VBoxContainer = $MarginContainer/VBoxContainer/ContractContainer
@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel

var contracts: Array[Dictionary] = []

func _ready() -> void:
	contracts = GameData.generate_contracts(3)
	_update_stats()
	_build_contract_buttons()
	# Add "Return to Ship" button at the bottom
	var ship_btn := Button.new()
	ship_btn.custom_minimum_size = Vector2(0, 60)
	ship_btn.text = "Return to Ship"
	ship_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ShipHub.tscn"))
	contract_container.get_parent().add_child(ship_btn)

func _update_stats() -> void:
	var d := SaveManager.data
	stats_label.text = "Credits: %d | Corruption: %d | Contracts: %d" % [
		d.total_credits, d.total_corruption, d.contracts_completed
	]

func _build_contract_buttons() -> void:
	for child in contract_container.get_children():
		child.queue_free()
	for i in contracts.size():
		var contract := contracts[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 80)
		btn.text = "%s\nTarget: %s | Depth: %d | Reward: %d cr" % [
			contract["name"], contract["creature_type"], contract["depth"], contract["reward"]
		]
		btn.pressed.connect(_on_contract_selected.bind(i))
		contract_container.add_child(btn)

func _on_contract_selected(index: int) -> void:
	GameData.set_current_contract(contracts[index])
	get_tree().change_scene_to_file("res://scenes/Hunt.tscn")
