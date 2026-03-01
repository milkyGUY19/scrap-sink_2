extends StaticBody2D

@onready var boat_animation: AnimatedSprite2D = $BoatAnimation
@onready var done_label: Label = $DoneLabel

var required_items: Dictionary = {}
var trade_completed: bool = false
var floating_ui_scene: PackedScene = preload("res://scenes/ui/FloatingInventoryUI.tscn")
var floating_ui_instance: Control

func _ready() -> void:
	input_pickable = true
	boat_animation.play("default")
	
	# Inicializace UI požadavku
	floating_ui_instance = floating_ui_scene.instantiate()
	add_child(floating_ui_instance)
	floating_ui_instance.position = Vector2(0, -100)
	
	_generate_requirements()
	floating_ui_instance.update_inventory(required_items)
	
	input_event.connect(_on_input_event)

func _generate_requirements() -> void:
	var fish_data = preload("res://scripts/items/ItemFish.gd").new()
	fish_data.icon = preload("res://assets/ryba.png")
	
	var random_amount = randi() % 4 + 5 # 5 až 8 kusů
	required_items[fish_data] = random_amount

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not trade_completed:
			_attempt_trade()

func _attempt_trade() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var player = players[0]
	var player_inv = player.inventory
	
	# Povolení tradu?
	var has_all = true
	for req_item in required_items.keys():
		var amount_needed = required_items[req_item]
		var matched = false
		for p_item in player_inv.items.keys():
			if p_item.item_name == req_item.item_name and player_inv.items[p_item] >= amount_needed:
				matched = true
				break
		if not matched:
			has_all = false
			break
			
	if has_all:
		# Strhnutí ryb
		for req_item in required_items.keys():
			var amount_needed = required_items[req_item]
			var key_to_remove = null
			for p_item in player_inv.items.keys():
				if p_item.item_name == req_item.item_name:
					key_to_remove = p_item
					break
			if key_to_remove:
				player_inv.remove_item(key_to_remove, amount_needed)
				
		_give_reward()
		trade_completed = true
		
		# Vyčištění UI
		required_items.clear()
		floating_ui_instance.visible = false
		if done_label:
			done_label.visible = true
			
		# Zákaz dalšího klikání
		if input_event.is_connected(_on_input_event):
			input_event.disconnect(_on_input_event)
			
		GameManager.add_completed_trade()
		print("Plachetnice dostala ryby - Trade splněn!")
	else:
		print("Plachetnice hlásí: Nemáš dost ryb!")

func _give_reward() -> void:
	# Podobně jako ponorka - náhodná odměna
	var reward_type = randi() % 3
	match reward_type:
		0:
			print("Plachetnice ti dává: rychlost!")
			GameManager.apply_speed_boost(GameManager.get_speed_multiplier() + 0.5)
		1:
			print("Plachetnice ti dává: posílení motoru / HP!")
			GameManager.engine_level += 1
		2:
			print("Plachetnice ti zvětšuje inventář!")
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				var player = players[0]
				player.inventory.max_capacity += 10
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)
