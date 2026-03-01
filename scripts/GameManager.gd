extends Node
# GameManager.gd (Autoload)
# Tento skript uchovává globální stav vaší hry. Nemá řešit fyziku, ale 
# má shromažďovat data (hloubka, peníze) a oznamovat změny pomocí signálů.

const PIXELS_PER_METER: float = 100.0
const MAX_GAME_DEPTH: float = 1600.0

# -----------------
# 1. Signály (Events)
# -----------------
# Ostatní uzly se na tyto signály připojí, aby věděly, co se stalo,
# aniž by se musely navzájem hledat ve stromu.
signal player_died
signal player_returned
signal depth_changed(new_depth: float)
signal max_depth_changed(new_max_depth: float)
signal materials_changed(new_amount: int)
signal stored_materials_changed(new_amount: int)
signal inventory_capacity_changed(current: int, max_cap: int)
signal item_collected(item_name: String, depth_m: float)
signal completed_trades_changed(new_count: int)

# -----------------
# 2. Proměnné a Setters
# -----------------
# Používáme tzv. proterties se "set" metodou. To znamená, že pokaždé 
# když se hodnota změní (odkudkoliv z kódu), automaticky se zavolá její `setter` funkce 
# a vyvolá se příslušný signál (čili např. UI hned pozná změnu a překreslí se).

var current_depth: float = 0.0 : set = set_current_depth
var max_depth_reached: float = 0.0 : set = set_max_depth_reached
var collected_materials: int = 0 : set = set_collected_materials
var stored_materials: int = 0 : set = set_stored_materials
var completed_trades_count: int = 0 : set = set_completed_trades_count

# -----------------
# Upgrady (Prozatím jednoduše)
# -----------------
var hull_level: int = 1
var engine_level: int = 1

# -----------------
# 3. Setter Funkce
# -----------------
func set_current_depth(value: float) -> void:
	# Ujistíme se, že hloubka neklesne pod nulu
	current_depth = maxf(0.0, value)
	depth_changed.emit(current_depth)
	
	# Automatická aktualizace max_depth
	if current_depth > max_depth_reached:
		self.max_depth_reached = current_depth # Zde musíme použít `self.`, aby se zavolal setter!

func set_max_depth_reached(value: float) -> void:
	max_depth_reached = value
	max_depth_changed.emit(max_depth_reached)

func set_collected_materials(value: int) -> void:
	# Materiály také nesmí jít pod nulu
	collected_materials = maxi(0, value)
	materials_changed.emit(collected_materials)
	
func set_stored_materials(value: int) -> void:
	stored_materials = maxi(0, value)
	stored_materials_changed.emit(stored_materials)

func set_completed_trades_count(value: int) -> void:
	completed_trades_count = maxi(0, value)
	completed_trades_changed.emit(completed_trades_count)
func add_completed_trade() -> void:
	self.completed_trades_count += 1

# -----------------
# 4. Veřejné Funkce Stavu
# -----------------
func on_player_death() -> void:
	# Při smrti jen resetneme co hráč nasbíral během ponoru 
	# a přesměrujeme ho do záklaní scény.
	self.collected_materials = 0
	self.current_depth = 0.0
	player_died.emit()
	get_tree().change_scene_to_file("res://GameOver.tscn")

func on_player_return() -> void:
	# Při návratu se sebraný loot převede do "banky"
	self.stored_materials += collected_materials
	self.collected_materials = 0
	self.current_depth = 0.0
	player_returned.emit()
	get_tree().change_scene_to_file("res://scenes/Base.tscn")

var current_speed_multiplier: float = 1.5

func get_speed_multiplier() -> float:
	# Násobitel rychlosti lodi podle hloubky
	var depth_multiplier: float = 1.5
	if current_depth >= 1200.0:
		depth_multiplier = 5.0
	elif current_depth >= 600.0:
		depth_multiplier = 4.0
	elif current_depth >= 200.0:
		depth_multiplier = 3.0
	
	return max(depth_multiplier, current_speed_multiplier)

func apply_speed_boost(multiplier: float) -> void:
	# Aplikuje jednorázově či dlouhodobě speed boost.
	# Udržíme si ten nejvyšší možný
	if multiplier > current_speed_multiplier:
		current_speed_multiplier = multiplier
