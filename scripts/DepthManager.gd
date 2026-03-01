extends Node
class_name DepthManager
# DepthManager.gd
# Generátor nepřátel a lootu závislý na hloubce hráče.
# Využívá proměnné Curve (křivky), které nastavíš přímo v inspektoru.

# Kolekce všech monster, která umíme spawnout (jako Custom Resources).
# V editoru do tohoto pole jen nahážeš LightMonster.tres a HeavyMonster.tres
@export var monster_pool: Array[MonsterStats] = []

# Křivka. Kolik nepřátel celkově by se asi tak mělo objevit podle hloubky.
# Osa X: Hloubka (0 = hladina, 1.0 = 10000 m). Osa Y: Max počet monster najednou
@export var spawn_density_curve: Curve 

# Další křivka, která udává, jaká je šance, že monstrum bude těžké.
# Osa X: Hloubka. Osa Y: Šance na těžké monstrum (0.0 až 1.0).
@export var heavy_monster_chance_curve: Curve 

# Timer, který volá funkci _on_spawn_timer_timeout. Přejmenováno pro čistotu.
@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	if len(monster_pool) == 0:
		push_warning("DepthManager: Nemám zadána žádná monstra k spawnování!")
	
	# Napojíme signál ručně pro jistotu.
	if spawn_timer and not spawn_timer.timeout.is_connected(_on_timeout):
		spawn_timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	if len(monster_pool) == 0: return

	# Zjistíme, kde na ose 0 - 10000 se nacházíme (normalizujeme na 0.0 - 1.0)
	var depth_progress: float = GameManager.current_depth / GameManager.MAX_GAME_DEPTH
	depth_progress = clampf(depth_progress, 0.0, 1.0) # Pojistka

	# Načteme hodnoty z křivek
	var max_active_enemies: int = int(spawn_density_curve.sample(depth_progress)) if spawn_density_curve else 5
	var heavy_chance: float = heavy_monster_chance_curve.sample(depth_progress) if heavy_monster_chance_curve else 0.0
	
	# TODO: Logika zjišťování kolik nepřátel teď je (přes Groups). 
	# Zatím to zjednodušíme - prostě zkusíme spawnout.
	
	var chosen_monster_stats: MonsterStats = null
	
	# 0 až 500: Jen light. 500+: Začíná Heavy. 
	# Tuhle logiku už nemusíme psát do IF statements, tu logiku jsi vyklikal
	# v té heavy_chance_curve křivce! Tady se tím nebudeme trápit.
	
	# Prototyp výběru - samozřejmě funguje jen pokud máš pole správně naplněné:
	# index 0: lehké, index 1: těžké
	if randf() < heavy_chance and monster_pool.size() > 1:
		chosen_monster_stats = monster_pool[1] # Těžké
	else:
		chosen_monster_stats = monster_pool[0] # Lehké

	if chosen_monster_stats and chosen_monster_stats.monster_scene:
		spawn_enemy(chosen_monster_stats.monster_scene)

func spawn_enemy(scene_pack: PackedScene) -> void:
	# Instancování do světa (mimo obrazovku atd.)
	var instance = scene_pack.instantiate()
	
	# Zde bychom typicky určili náhodnou pozici mimo kameru hráče 
	# a přidali instanci jako dítě do hlavní herní scény.
	get_tree().current_scene.add_child(instance)
	
	# Příklad spawnu 500 pixelů vpravo od středu - TODO nahradit opravdovou logikou
	if instance is Node2D:
		instance.global_position = get_viewport().get_camera_2d().get_screen_center_position() + Vector2(randf_range(500, 800), randf_range(-300, 300))
