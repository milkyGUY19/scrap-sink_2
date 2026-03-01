extends Node
class_name HealthComponent
# HealthComponent.gd
# Tento uzel se přidá jako dítě do jakéhokoliv tělesa (Ponorka, Monstrum),
# které má mít životy. Díky tomu už nemusíme psát logiku životů znovu a znovu.

signal died
signal hp_changed(current_hp: int, max_hp: int)

@export var max_hp: int = 100

# Setter property zajistí, že při každé změně HP (i zvenčí) se zavolá set_hp
var current_hp: int : set = set_hp

func _ready() -> void:
	current_hp = max_hp

func set_hp(value: int) -> void:
	# Hodnota HP nemůže být menší než 0 nebo větší než max_hp
	current_hp = clampi(value, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp == 0:
		died.emit()

# Pomocná funkce, pokud na to někdo chce volat zvenčí "dát damage"
func take_damage(amount: int) -> void:
	# self.current_hp = ... zavolá náš setter výše
	self.current_hp -= amount
	
func heal(amount: int) -> void:
	self.current_hp += amount
