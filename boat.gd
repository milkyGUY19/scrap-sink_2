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
	
	# Zjištění, jestli jsme plachetnici nevyřešili minulé kolo
	if GameManager.completed_submarines.has("boat_surface"):
		trade_completed = true
		required_items.clear()
		floating_ui_instance.visible = false
		if done_label:
			done_label.visible = true
	else:
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
		GameManager.register_submarine_complete("boat_surface")
		print("Plachetnice dostala ryby - Trade splněn!")
	else:
		print("Plachetnice hlásí: Nemáš dost ryb!")

func _give_reward() -> void:
	# Podle počtu splněných questů
	var trades_so_far = GameManager.completed_trades_count
	
	print("Plachetnice doručuje tvou speciální odměnu!")
	var players = get_tree().get_nodes_in_group("player")
	var player = players[0] if not players.is_empty() else null
		
	# Měníme logiku - přesně podle zadání vedoucího:
	match trades_so_far:
		0:
			# První ponorka/loď celkově
			print("1. opravená: +5 míst v inventáři")
			if player:
				GameManager.bonus_inventory_capacity += 5
				player.inventory.max_capacity += 5
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)
		1:
			# Druhá ponorka/loď celkově
			print("2. opravená: Speed 3x a +5 HP")
			GameManager.apply_speed_boost(3.0)
			if player and player.get_node_or_null("HealthComponent"):
				var hp_comp = player.get_node("HealthComponent")
				GameManager.bonus_health_capacity += 5
				hp_comp.max_hp += 5
				hp_comp.heal(5) # Ideální doplnit i aktuální HP
		2:
			# Třetí ponorka/loď
			print("3. opravená: +5 míst v inventáři")
			if player:
				GameManager.bonus_inventory_capacity += 5
				player.inventory.max_capacity += 5
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)
		3:
			# Čtvrtá ponorka/loď
			print("4. opravená: Speed 4x a +5 HP")
			GameManager.apply_speed_boost(4.0)
			if player and player.get_node_or_null("HealthComponent"):
				var hp_comp = player.get_node("HealthComponent")
				GameManager.bonus_health_capacity += 5
				hp_comp.max_hp += 5
				hp_comp.heal(5)
		4:
			# Pátá ponorka/loď
			print("5. opravená: +5 míst v inventáři")
			if player:
				GameManager.bonus_inventory_capacity += 5
				player.inventory.max_capacity += 5
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)
		5:
			# Šestá ponorka/loď
			print("6. opravená: Speed 5x a +5 HP")
			GameManager.apply_speed_boost(5.0)
			if player and player.get_node_or_null("HealthComponent"):
				var hp_comp = player.get_node("HealthComponent")
				GameManager.bonus_health_capacity += 5
				hp_comp.max_hp += 5
				hp_comp.heal(5)
		_:
			# Odměna pošesté - třeba jen malý bonus k batohu, nebo už nic
			print("Další opravená: Menší bonusový batůžek (+2)!")
			if player:
				GameManager.bonus_inventory_capacity += 2
				player.inventory.max_capacity += 2
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)

	GameManager.emit_upgrades_changed()
