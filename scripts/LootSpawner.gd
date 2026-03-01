extends Node

@export var scrap_scene: PackedScene = preload("res://scenes/ScrapItem.tscn")

var iron_data = preload("res://scripts/items/ItemIron.gd").new()
var oxygen_data = preload("res://scripts/items/ItemOxygen.gd").new()
var fish_data = preload("res://scripts/items/ItemFish.gd").new()

signal schedule_respawn(item_name: String)

func _ready() -> void:
	iron_data.icon = preload("res://assets/ocel.png")
	oxygen_data.icon = preload("res://assets/O2.png")
	fish_data.icon = preload("res://assets/ryba.png")
	_spawn_all_items()
	
	GameManager.item_collected.connect(_on_item_collected)

func _spawn_single_item(item_data_res: Resource, depth_m: float) -> void:
	var root_world = get_tree().current_scene
	if not root_world:
		return
		
	var map_node = root_world
	if root_world.has_node("World"):
		map_node = root_world.get_node("World")
	
	var y_pos = GameManager.PIXELS_PER_METER * depth_m + 300.0
	var x_pos = randf_range(300.0, 2100.0) 
	
	var instance = scrap_scene.instantiate()
	instance.position = Vector2(x_pos, y_pos)
	instance.item_data = item_data_res
	
	# Získáme referenci na Sprite2D a nastavíme mu správnou texturu
	var sprite = instance.get_node_or_null("Sprite2D")
	if sprite and item_data_res.icon:
		sprite.texture = item_data_res.icon
		sprite.modulate = Color.WHITE # Resetujeme starou modrou/šedou/červenou barvu
		# Vypočítáme scale, aby ikona měla finální velikost 64 pixelů na šířku a výšku
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			# Vezmeme ten větší rozměr (šířka nebo výška) pro zachování poměru stran
			var max_dim = max(tex_size.x, tex_size.y)
			var scale_factor = 64.0 / max_dim
			sprite.scale = Vector2(scale_factor, scale_factor)
		else:
			sprite.scale = Vector2(1, 1)
		
	map_node.add_child(instance)

func _spawn_all_items() -> void:
	var current_depth_m = 10.0
	var step_m = 10.0
	
	while current_depth_m <= GameManager.MAX_GAME_DEPTH:
		if current_depth_m <= 400.0:
			# Mělčina (10m - 400m)
			if randf() < 0.65: _spawn_single_item(fish_data, current_depth_m)
			if randf() < 0.08: _spawn_single_item(iron_data, current_depth_m)
			if randf() < 0.01: _spawn_single_item(oxygen_data, current_depth_m)
		elif current_depth_m <= 1000.0:
			# Temnota (400m - 1000m)
			if randf() < 0.15: _spawn_single_item(fish_data, current_depth_m)
			if randf() < 0.5: _spawn_single_item(iron_data, current_depth_m)
			if randf() < 0.04: _spawn_single_item(oxygen_data, current_depth_m)
		else:
			# Hlubina (1000m - 1600m)
			if randf() < 0.05: _spawn_single_item(fish_data, current_depth_m)
			if randf() < 0.2: _spawn_single_item(iron_data, current_depth_m)
			if randf() < 0.3: _spawn_single_item(oxygen_data, current_depth_m)
			
		current_depth_m += step_m

func _on_item_collected(item_name: String, depth_m: float) -> void:
	if item_name not in ["Fish", "Iron", "Oxygen tank"]:
		return
	
	var wait_time = 20.0
	
	var timer = get_tree().create_timer(wait_time, false)
	timer.timeout.connect(func(): _respawn_specific(item_name, depth_m))

func _respawn_specific(item_name: String, collected_depth_m: float) -> void:
	# Randomizujeme trochu hloubku, ať se nescházejí přesně v jedné lince (+- 30 metrů)
	var spawn_depth = clamp(collected_depth_m + randf_range(-30.0, 30.0), 10.0, GameManager.MAX_GAME_DEPTH)
	
	if item_name == "Fish":
		_spawn_single_item(fish_data, spawn_depth)
	elif item_name == "Iron":
		_spawn_single_item(iron_data, spawn_depth)
	elif item_name == "Oxygen tank":
		_spawn_single_item(oxygen_data, spawn_depth)
