extends CanvasLayer
class_name PlayerUI
# PlayerUI.gd
# Pouze pasivně poslouchá GameManager a HealthComponent ponorky.
# Neobsahuje žádnou logiku hry, jen ukazuje čísla na obrazovku.

# Očekáváme napojení Label uzlů přes Inspector v Editoru
@export var depth_label: Label
@export var materials_label: Label
@export var hp_label: Label
@export var trades_label: Label

# Volitelně HealthComponent hráče - připojíme manuálně ve hře nebo v _ready získáme od hráče
var player_health: HealthComponent

func _ready() -> void:
	# Reagujeme na signály z roota hry
	GameManager.depth_changed.connect(_on_depth_changed)
	GameManager.inventory_capacity_changed.connect(_on_inventory_changed)
	GameManager.completed_trades_changed.connect(_on_trades_changed)
	
	# Prvotní zobrazení
	_on_depth_changed(GameManager.current_depth)
	_on_inventory_changed(0, 20) # Výchozí
	_on_trades_changed(GameManager.completed_trades_count)
	
	# Napojení na hráče pro HP
	call_deferred("_connect_to_player")

func _connect_to_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.health_component:
			setup_health_connection(player.health_component)

func setup_health_connection(health_comp: HealthComponent) -> void:
	player_health = health_comp
	player_health.hp_changed.connect(_on_hp_changed)
	
	# První zapsání HP
	_on_hp_changed(player_health.current_hp, player_health.max_hp)

# Callbacky signálů - aktualizují text v Labels
func _on_depth_changed(new_depth: float) -> void:
	if depth_label:
		depth_label.text = "Depth: %dm" % int(new_depth)

func _on_inventory_changed(current: int, max_cap: int) -> void:
	if materials_label:
		materials_label.text = "Inventory: %d/%d" % [current, max_cap]
		
func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	if hp_label:
		hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

func _on_trades_changed(count: int) -> void:
	if trades_label:
		trades_label.text = "Trades completed: %d/8" % count
