extends Control

@onready var results_label: Label = $MarginContainer/VBoxContainer/ResultsLabel
@onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	var result := GameData.hunt_result
	var credits: int = result.get("credits", 0)
	var corr: int = result.get("corruption", 0)
	var items: int = result.get("items", 0)

	var text := "=== Hunt Complete ===\n\n"
	if credits > 0:
		text += "Credits earned: %d\n" % credits
	else:
		text += "Hunt failed — no credits earned\n"
	text += "Corruption gained: %d\n" % corr
	text += "Items collected: %d\n\n" % items
	text += "--- Totals ---\n"
	text += "Total credits: %d\n" % SaveManager.data.total_credits
	text += "Total corruption: %d\n" % SaveManager.data.total_corruption
	text += "Contracts completed: %d" % SaveManager.data.contracts_completed
	results_label.text = text

	return_button.pressed.connect(_on_return)

func _on_return() -> void:
	get_tree().change_scene_to_file("res://scenes/ContractBoard.tscn")
