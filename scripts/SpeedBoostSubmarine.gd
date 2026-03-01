extends StaticBody2D
class_name TraderSubmarine

var required_items: Dictionary = {}
var trades_completed: int = 0

var floating_ui_scene: PackedScene = preload("res://scenes/ui/FloatingInventoryUI.tscn")
var floating_ui_instance: Control
var reset_timer: Timer

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var done_label: Label = $DoneLabel

func _ready() -> void:
	# Vynutíme zapnutí klikání
	input_pickable = true
	
	# Vygenerování random 1, 2 nebo 3 položek pro trade
	_generate_requirements()
	
	# Vytvoření vizuálního elementu
	floating_ui_instance = floating_ui_scene.instantiate()
	add_child(floating_ui_instance)
	floating_ui_instance.position = Vector2(0, -80) # Posun nad vrak
	
	floating_ui_instance.update_inventory(required_items)
	
	input_event.connect(_on_input_event)
	
	# Začátek časovače pro automatickou obnovu tradů: 2 minuty PO splnění
	reset_timer = Timer.new()
	reset_timer.wait_time = 30.0
	reset_timer.autostart = false
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_reset_trade)
	add_child(reset_timer)
	
	# Výchozí stav
	_update_visuals()

func _update_visuals() -> void:
	# Vždy vrtulkou k levé stěně (čelem doprava)
	sprite.flip_h = false
	
	# Zrezlé ponorce nastavíme jen velmi mírně tmavší nádech (jako "špína"), ale bez vlivu vody,
	# protože samotná voda už ji kryje vrstvou WaterTopUnderwater skrz rendering Z-index.
	var base_mod: Color = Color(0.8, 0.8, 0.8, 1)

	if trades_completed == 0:
		sprite.play("wrecked_static")
		sprite.modulate = base_mod
	elif trades_completed == 1:
		sprite.play("wrecked_moving")
		sprite.modulate = base_mod
	elif trades_completed >= 2:
		sprite.play("repaired_final")
		sprite.modulate = Color.WHITE

func _reset_trade() -> void:
	# Vyčistit starý úkol a vygenerovat nový
	required_items.clear()
	_generate_requirements()
	floating_ui_instance.update_inventory(required_items)
	
	# Zajistit že po předchozím úspěšném obchodu bude možné okno opět prokliknout
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	
	print("Nový trade je k dispozici!")

func _generate_requirements() -> void:
	# Máme přístup k datovým typům z LootSpawneru (nebo je načteme napřímo)
	var iron_data = preload("res://scripts/items/ItemIron.gd").new()
	var oxygen_data = preload("res://scripts/items/ItemOxygen.gd").new()
	var fish_data = preload("res://scripts/items/ItemFish.gd").new()
	
	iron_data.icon = preload("res://assets/ocel.png")
	oxygen_data.icon = preload("res://assets/O2.png")
	fish_data.icon = preload("res://assets/ryba.png")
	
	# Zjistíme hloubku ponorky
	var depth_m = max(0.0, (global_position.y - 300.0) / GameManager.PIXELS_PER_METER)
	# Rozdělení logiky do přehledných funkcí podle zón, kde si můžeš sám definovat požadavky
	if depth_m <= 400.0:
		_setup_shallow_zone(fish_data, iron_data, oxygen_data)
	elif depth_m <= 1000.0:
		_setup_dark_zone(fish_data, iron_data, oxygen_data)
	else:
		_setup_deep_zone(fish_data, iron_data, oxygen_data)

# === ZDE MŮŽEŠ LIBOVOLNĚ UPRAVOVAT POŽADAVKY PRO JEDNOTLIVÉ ZÓNY ===

func _setup_shallow_zone(fish, iron, oxygen) -> void:
	# Mělčina: 7-11 ryb, 0-3 železa
	required_items[fish] = randi() % 5 + 7
	var iron_amt = randi() % 4
	if iron_amt > 0:
		required_items[iron] = iron_amt

func _setup_dark_zone(fish, iron, oxygen) -> void:
	# Temnota: 2-5 ryb, 6-9 železa, 1-3 kyslíky
	required_items[fish] = randi() % 4 + 2
	required_items[iron] = randi() % 4 + 6
	required_items[oxygen] = randi() % 3 + 1

func _setup_deep_zone(fish, iron, oxygen) -> void:
	# Hlubina: 0-2 ryby, 4-6 železa, 6-10 kyslíku
	var fish_amt = randi() % 3
	if fish_amt > 0:
		required_items[fish] = fish_amt
	required_items[iron] = randi() % 3 + 4
	required_items[oxygen] = randi() % 5 + 6
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_trade()

func _attempt_trade() -> void:
	# 1. Zjistit jestli má hráč dané suroviny bezpečně
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	
	var player: Submarine = players[0]
	var player_inv: Inventory = player.inventory
	
	# 2. Kontrola, zde ho má dostatek
	var has_all = true
	for req_item in required_items.keys():
		var amount_needed = required_items[req_item]
		var matched = false
		for player_item in player_inv.items.keys():
			# Jelikož porovnáváme instance ItemData, musíme kontrolovat jméno
			if player_item.item_name == req_item.item_name and player_inv.items[player_item] >= amount_needed:
				matched = true
				break
		if not matched:
			has_all = false
			break
			
	# 3. Pokud má dostatek - sebereme a dáme mu reward
	if has_all:
		for req_item in required_items.keys():
			var amount_needed = required_items[req_item]
			# Najdeme znovu ten správný klíč ze slovníku hráče pro vymazání
			var key_to_remove = null
			for player_item in player_inv.items.keys():
				if player_item.item_name == req_item.item_name:
					key_to_remove = player_item
					break
			if key_to_remove:
				player_inv.remove_item(key_to_remove, amount_needed)
				
		_give_reward()
		
		# Zvýšíme počet splněných tradů
		trades_completed += 1
		_update_visuals()
		
		# Zmizení ikonek (trade splněn)
		required_items.clear()
		floating_ui_instance.update_inventory(required_items)
		
		# Deaktivace klikání
		if input_event.is_connected(_on_input_event):
			input_event.disconnect(_on_input_event)
			
		# Spustíme odpočet na další trade (2 minuty), ALE JEN POKUD NENÍ HOTOVO
		if trades_completed < 2:
			reset_timer.start()
			print("Trade splněn! Další za 2 minuty.")
		else:
			# Po 2. tradu je konec, schováme UI
			floating_ui_instance.visible = false
			if done_label:
				done_label.visible = true
			GameManager.add_completed_trade()
			print("Ponorka byla plně opravena a už nic nepotřebuje.")
	else:
		print("Nemáš dostatek surovin na trade!")

func _give_reward() -> void:
	# Jednoduchý systém - náhodná odměna
	var reward_type = randi() % 3
	match reward_type:
		0:
			print("Trade accepted: +Speed")
			GameManager.apply_speed_boost(GameManager.get_speed_multiplier() + 0.5)
		1:
			print("Trade accepted: +Damage/HP")
			GameManager.engine_level += 1
		2:
			print("Trade accepted: +Inventory Space")
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				var player: Submarine = players[0]
				player.inventory.max_capacity += 10
				player.inventory.inventory_changed.emit(player.inventory.get_total_count(), player.inventory.max_capacity)
