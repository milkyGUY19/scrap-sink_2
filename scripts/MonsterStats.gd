extends Resource
class_name MonsterStats
# MonsterStats.gd
# Systém "Data jako kód". Tento skript je jen šablona. 
# V editoru přes něj vytvoříš soubory jako "LightMonster.tres" a "HeavyMonster.tres",
# kde jen naklikáš odlišná HP, rychlost a sprite, aniž bys psal nový zbytečný kód.

@export var monster_name: String = "Základní monstrum"
@export var base_hp: int = 20
@export var movement_speed: float = 100.0
@export var damage: int = 15
@export var drop_materials_min: int = 1
@export var drop_materials_max: int = 3
@export var monster_scene: PackedScene # Scéna, která se reálně spawne
