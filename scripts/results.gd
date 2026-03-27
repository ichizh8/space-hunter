extends Control

@onready var results_label: Label = $MarginContainer/VBoxContainer/ResultsLabel
@onready var return_button: Button = $MarginContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	var result := GameData.hunt_result
	var credits: int = result.get("credits", 0)
	var corr: int = result.get("corruption", 0)
	var items: int = result.get("items", 0)
	var ingredients: Array = result.get("ingredients", [])

	# Persist ingredients
	if not ingredients.is_empty():
		SaveManager.add_ingredients(ingredients)

	var text := "=== Hunt Complete ===\n\n"
	if credits > 0:
		text += "Credits earned: %d\n" % credits
	else:
		text += "Hunt failed — no credits earned\n"
	text += "Corruption gained: %d\n" % corr
	text += "Items collected: %d\n" % items

	# Show ingredients collected this hunt
	if not ingredients.is_empty():
		text += "\n--- Ingredients Found ---\n"
		for ing in ingredients:
			text += "  %s\n" % ing.get("name", "Unknown")

	# Show pantry totals
	text += "\n--- Pantry ---\n"
	var pantry: Dictionary = SaveManager.data.pantry
	var has_pantry: bool = false
	for key in pantry:
		if pantry[key] > 0:
			has_pantry = true
			break
	if not has_pantry:
		text += "  (empty)\n"
	else:
		for ing_id in pantry:
			var count: int = pantry.get(ing_id, 0)
			if count > 0:
				var display_name: String = ing_id.replace("_", " ").capitalize()
				text += "  %s: %d\n" % [display_name, count]

	text += "\n--- Totals ---\n"
	text += "Total credits: %d\n" % SaveManager.data.total_credits
	text += "Total corruption: %d\n" % SaveManager.data.total_corruption
	text += "Contracts completed: %d" % SaveManager.data.contracts_completed
	results_label.text = text

	return_button.pressed.connect(_on_return)

func _on_return() -> void:
	get_tree().change_scene_to_file("res://scenes/ShipHub.tscn")
