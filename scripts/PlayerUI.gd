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

var upgrades_container: VBoxContainer
var speed_boost_label: Label
var inventory_boost_label: Label
var hp_boost_label: Label

func _ready() -> void:
	# Reagujeme na signály z roota hry
	GameManager.depth_changed.connect(_on_depth_changed)
	GameManager.inventory_capacity_changed.connect(_on_inventory_changed)
	GameManager.completed_trades_changed.connect(_on_trades_changed)
	
	# Prvotní zobrazení
	_on_depth_changed(GameManager.current_depth)
	_on_inventory_changed(0, 20) # Výchozí
	_on_trades_changed(GameManager.completed_trades_count)
	
	# Vytvoření dynamického UI pro Upgrady
	_create_upgrades_ui()
	GameManager.upgrades_changed.connect(_on_upgrades_changed)
	_on_upgrades_changed(GameManager.current_speed_multiplier, GameManager.bonus_inventory_capacity, GameManager.bonus_health_capacity)
	
	# Napojení na hráče pro HP
	call_deferred("_connect_to_player")

func _create_upgrades_ui() -> void:
	# Naprosté oddělení od stávajících kontejnerů, aby si to Godot nepřepisoval
	upgrades_container = VBoxContainer.new()
	add_child(upgrades_container)
	
	upgrades_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	upgrades_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	upgrades_container.grow_vertical = Control.GROW_DIRECTION_END
	upgrades_container.offset_top = 20
	upgrades_container.offset_right = -20
	upgrades_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var font = preload("res://assets/Peaberry-Base.otf")
	
	speed_boost_label = Label.new()
	speed_boost_label.add_theme_font_override("font", font)
	speed_boost_label.add_theme_font_size_override("font_size", 24)
	speed_boost_label.add_theme_constant_override("outline_size", 4)
	speed_boost_label.add_theme_color_override("font_color", Color.WHITE)
	speed_boost_label.add_theme_color_override("font_outline_color", Color.BLACK)
	speed_boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrades_container.add_child(speed_boost_label)
	
	inventory_boost_label = Label.new()
	inventory_boost_label.add_theme_font_override("font", font)
	inventory_boost_label.add_theme_font_size_override("font_size", 24)
	inventory_boost_label.add_theme_constant_override("outline_size", 4)
	inventory_boost_label.add_theme_color_override("font_color", Color.WHITE)
	inventory_boost_label.add_theme_color_override("font_outline_color", Color.BLACK)
	inventory_boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrades_container.add_child(inventory_boost_label)
	
	hp_boost_label = Label.new()
	hp_boost_label.add_theme_font_override("font", font)
	hp_boost_label.add_theme_font_size_override("font_size", 24)
	hp_boost_label.add_theme_constant_override("outline_size", 4)
	hp_boost_label.add_theme_color_override("font_color", Color.WHITE)
	hp_boost_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrades_container.add_child(hp_boost_label)


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
		var max_d = GameManager.get_max_allowed_depth()
		depth_label.text = "Depth: %dm / %dm" % [int(new_depth), int(max_d)]

func _on_inventory_changed(current: int, max_cap: int) -> void:
	if materials_label:
		materials_label.text = "Inventory: %d/%d" % [current, max_cap]
		
func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	if hp_label:
		hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

func _on_trades_changed(count: int) -> void:
	if trades_label:
		trades_label.text = "Trades completed: %d/8" % count

func _on_upgrades_changed(speed: float, inv: int, hp: int) -> void:
	if speed_boost_label:
		speed_boost_label.text = "SpeedBoost: %sx" % str(speed).pad_decimals(1)
	if inventory_boost_label:
		inventory_boost_label.text = "InventoryBoost: +%d" % inv
	if hp_boost_label:
		hp_boost_label.text = "HPBoost: +%d" % hp
		
	# Přepočítat ihned i text u hloubky ať zareaguje na novou ponorku
	_on_depth_changed(GameManager.current_depth)
