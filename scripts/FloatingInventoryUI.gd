extends Control
class_name FloatingInventoryUI

@onready var container = $HBoxContainer

var item_icons = {}

func _ready() -> void:
	z_index = 100
	# Vymažeme jakýkoliv zkušební obsah
	for child in container.get_children():
		child.queue_free()

func update_inventory(items_dict: Dictionary) -> void:
	# 1. Vymazat stávající
	for child in container.get_children():
		child.queue_free()
	
	# 2. Vytvořit nově pro každý předmět (který má množství > 0)
	for item_data in items_dict.keys():
		var amount = items_dict[item_data]
		if amount > 0:
			var slot = HBoxContainer.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_theme_constant_override("separation", 2)
			
			var icon_rect = TextureRect.new()
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Tady předpokládáme že Icon není prázdné - jinak použijeme fallback barevný obdélník
			if item_data.icon:
				icon_rect.texture = item_data.icon
			icon_rect.custom_minimum_size = Vector2(20, 20)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			var it_name = item_data.item_name
			
			var label = Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.text = it_name + " x" + str(amount)
			# label.add_theme_font_size_override("font_size", 14) 
			
			slot.add_child(icon_rect)
			slot.add_child(label)
			
			container.add_child(slot)
