extends Node

var current_contract: Dictionary = {}
var total_credits: int = 0
var total_corruption: int = 0
var contracts_completed: int = 0


func set_contract(contract: Dictionary) -> void:
	current_contract = contract


func complete_contract(credits_earned: int, corruption_gained: int) -> void:
	total_credits += credits_earned
	total_corruption += corruption_gained
	contracts_completed += 1
