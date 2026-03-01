extends Node
class_name Inventory

signal inventory_changed(current_count: int, max_capacity: int)

@export var max_capacity: int = 20
var items: Dictionary = {} # Budeme uchovávat počty [ItemData: int] místo pole pro lepší UI

func add_item(item: ItemData) -> bool:
	var current_total_count = get_total_count()
	if current_total_count < max_capacity:
		var found_key = null
		for k in items.keys():
			if k.item_name == item.item_name:
				found_key = k
				break
				
		if found_key:
			items[found_key] += 1
		else:
			items[item] = 1
			
		inventory_changed.emit(get_total_count(), max_capacity)
		GameManager.collected_materials = get_total_value()
		return true
	return false

func remove_item(item: ItemData, amount: int = 1) -> bool:
	var found_key = null
	for k in items.keys():
		if k.item_name == item.item_name:
			found_key = k
			break
			
	if found_key and items[found_key] >= amount:
		items[found_key] -= amount
		if items[found_key] <= 0:
			items.erase(found_key)
		inventory_changed.emit(get_total_count(), max_capacity)
		GameManager.collected_materials = get_total_value()
		return true
	return false

func clear_inventory() -> void:
	items.clear()
	inventory_changed.emit(0, max_capacity)

func get_total_count() -> int:
	var total: int = 0
	for item in items.keys():
		total += items[item]
	return total

func get_total_value() -> int:
	var total: int = 0
	for item in items.keys():
		total += item.value * items[item]
	return total
