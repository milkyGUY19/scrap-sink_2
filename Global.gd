extends Node

var current_depth: float = 0.0
var max_depth_reached: float = 0.0
var collected_materials: int = 0
var stored_materials: int = 0

# Upgrady
var hull_level: int = 1
var engine_level: int = 1

func _ready():
	pass

# Volá se při smrti ponorky
func on_player_death():
	collected_materials = 0 # Ztráta věcí z aktuálního ponoru
	current_depth = 0.0
	get_tree().change_scene_to_file("res://scenes/Base.tscn")

# Volá se při úspěšném návratu
func on_player_return():
	stored_materials += collected_materials
	collected_materials = 0
	current_depth = 0.0
	get_tree().change_scene_to_file("res://scenes/Base.tscn")
