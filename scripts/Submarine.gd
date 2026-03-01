extends CharacterBody2D
class_name Submarine
# Submarine.gd 
# Slouží už POUZE jako controller (pohyb) hráče. Logiku životů a správy
# jsme přesunuli pryč, sem se pouze připojíme na signály dětí.

@export var max_speed: float = 350.0
@export var acceleration: float = 1000.0
@export var water_friction: float = 400.0

@onready var starting_y_position: float = global_position.y

# Očekáváme, že v Editoru pod tuto ponorku přidáme HealthComponent Node.
# V _ready ho napojíme na funkci on_death
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: AnimatedSprite2D = $Sprite2D
var inventory: Inventory
var cliff_damage_timer: float = 0.0
var was_touching_cliff: bool = false

var floating_ui_scene: PackedScene = preload("res://scenes/ui/FloatingInventoryUI.tscn")
var floating_ui_instance: Control

func _ready() -> void:
	add_to_group("player")
	
	inventory = Inventory.new()
	# Přičteme bonusovou kapacitu z předchozích životů/upgradů
	inventory.max_capacity += GameManager.bonus_inventory_capacity
	add_child(inventory)
	
	# Napojení Floating UI ihned na startu
	floating_ui_instance = floating_ui_scene.instantiate()
	add_child(floating_ui_instance)
	floating_ui_instance.position = Vector2(0, -80) # Posun nahoru nad ponorku
	
	# Přeposlání signálu do globálního GameManageru a místního UI
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	if health_component:
		# Takhle se připojuje signál z kódu od verze Godot 4.0
		health_component.died.connect(_on_death)
		
		# Test - Aplikování upgradu z nového GameManagera na base hp
		# Zvýší HP třeba o 50 za každý level trupu nad 1
		health_component.max_hp += (GameManager.hull_level - 1) * 50
		health_component.current_hp = health_component.max_hp

func _physics_process(delta: float) -> void:
	# 1. Spočítat aktuální hloubku a odeslat ji manažerovi
	# Tohle hru nezatíží, GameManager ví, jak reagovat, ale dělá to jen on
	var calculated_depth: float = (global_position.y - starting_y_position) / GameManager.PIXELS_PER_METER
	GameManager.current_depth = calculated_depth

	# 2. Získání vstupu přes sémantické akce (musíme je takto nastavit v Project Settings)
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Rychlost hráče bude modifikovaná podle úrovně motoru a hloubkového speed-bostu
	var base_speed_with_upgrades = max_speed + ((GameManager.engine_level - 1) * 50.0)
	var actual_speed = base_speed_with_upgrades * GameManager.get_speed_multiplier()

	# 3. Fyzika a Animace
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * actual_speed, acceleration * delta)
		sprite.play("movement")
		
		# Převrácení spritu, pokud plujeme doprava (výchozí sprite zřejmě míří doleva)
		if input_vector.x > 0:
			sprite.flip_h = true
		elif input_vector.x < 0:
			sprite.flip_h = false
	else:
		velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
		sprite.play("default")

	move_and_slide()
	
	# 4. Detekce poškození od útesů
	var is_touching_cliff = false
	
	# Kontrola přes slide_collisions (při pohybu)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("cliffs"):
			is_touching_cliff = true
			break
			
	# Pojistka: test_move pro případ, že stojíme u zdi bez pohybu
	if not is_touching_cliff:
		# Zkusíme se "pohnout" o 2 pixely do stran
		for dir in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			if test_move(global_transform, dir * 2.0):
				var col = move_and_collide(dir * 2.0, true)
				if col and col.get_collider().is_in_group("cliffs"):
					is_touching_cliff = true
					break
			
	if is_touching_cliff:
		if not was_touching_cliff:
			# Prvotní náraz (instantní damage)
			if health_component:
				health_component.take_damage(5)
				print(">>> NÁRAZ DO ÚTESU! HP: ", health_component.current_hp, " / ", health_component.max_hp)
			# Nastavíme timer rovnou na 0, aby po 1 vteřině dalšího kontaktu dostal dalších -5
			cliff_damage_timer = 0.0
			was_touching_cliff = true
		else:
			# Soustavný pobyt na zdi (ubírá po 1s)
			cliff_damage_timer += delta
			if cliff_damage_timer >= 1.0:
				if health_component:
					health_component.take_damage(5)
					print(">>> KONTAKT S ÚTESEM! HP: ", health_component.current_hp, " / ", health_component.max_hp)
				cliff_damage_timer = 0.0
	else:
		was_touching_cliff = false
		cliff_damage_timer = 0.0

# Vypořádání se se smrtí - řekneme Autoload managerovi a ten ať už ukončí ponor jak potřebuje
func _on_death() -> void:
	GameManager.on_player_death()

func _on_inventory_changed(c: int, m: int) -> void:
	GameManager.inventory_capacity_changed.emit(c, m)
	if floating_ui_instance:
		floating_ui_instance.update_inventory(inventory.items)
