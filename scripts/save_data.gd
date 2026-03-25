class_name SaveData
extends RefCounted

var total_credits: int = 0
var total_corruption: int = 0
var contracts_completed: int = 0
var ingredients: Dictionary = {}  # ingredient_id -> count, e.g. {"void_extract": 2}
var version: int = 1

func to_dict() -> Dictionary:
	return {
		"version": version,
		"total_credits": total_credits,
		"total_corruption": total_corruption,
		"contracts_completed": contracts_completed,
		"ingredients": ingredients.duplicate(),
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
