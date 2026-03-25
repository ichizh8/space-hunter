extends Control

@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel
@onready var pantry_label: Label = $MarginContainer/VBoxContainer/PantryLabel
@onready var contract_button: Button = $MarginContainer/VBoxContainer/ContractButton
@onready var cook_button: Button = $MarginContainer/VBoxContainer/CookButton
@onready var cook_status_label: Label = $MarginContainer/VBoxContainer/CookStatusLabel

func _ready() -> void:
	_update_stats()
	_update_pantry()
	contract_button.pressed.connect(_on_contract_board)
	cook_button.pressed.connect(_on_cook)
	cook_status_label.text = ""

func _update_stats() -> void:
	var d := SaveManager.data
	stats_label.text = "Credits: %d | Corruption: %d | Contracts: %d" % [
		d.total_credits, d.total_corruption, d.contracts_completed
	]

func _update_pantry() -> void:
	var pantry: Dictionary = SaveManager.data.ingredients
	var text := ""
	if pantry.is_empty():
		text = "  (empty — hunt creatures to collect ingredients)"
	else:
		for ing_id in pantry:
			var display_name: String = ing_id.replace("_", " ").capitalize()
			text += "  %s: %d\n" % [display_name, pantry[ing_id]]
	pantry_label.text = text.strip_edges()

func _on_contract_board() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")

func _on_cook() -> void:
	cook_status_label.text = "Kitchen coming soon"
