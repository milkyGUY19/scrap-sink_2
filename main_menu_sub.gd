extends Node2D

@onready var sub: AnimatedSprite2D = $Sub
@onready var bubbles_1: AnimatedSprite2D = $Sub/Bubbles1
@onready var bubbles_2: AnimatedSprite2D = $Sub/Bubbles2
@onready var squid: AnimatedSprite2D = $Squid
@onready var pufferfish: AnimatedSprite2D = $Pufferfish

# Base rozlišení podle project.godot
const BASE_WIDTH: float = 1280.0
const BASE_HEIGHT: float = 720.0

# Počáteční (relativní) pozice v procentech (0.0 - 1.0)
var sub_rel := Vector2(1071.0 / BASE_WIDTH, 289.0 / BASE_HEIGHT)
var squid_rel := Vector2(241.0 / BASE_WIDTH, 186.0 / BASE_HEIGHT)
var pufferfish_rel := Vector2(140.5 / BASE_WIDTH, 497.25 / BASE_HEIGHT)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sub.play("default")
	bubbles_1.play("default")
	bubbles_2.play("default")
	squid.play("default")
	pufferfish.play("default")
	
	# Zbarvení do stejného podvodního odstínu jako má ponorka
	var water_color = Color(0.3, 0.45, 0.65, 1)
	squid.modulate = water_color
	pufferfish.modulate = water_color
	# (Sub už má nastaveno v editoru, ale můžeme potvrdit)
	sub.modulate = water_color
	
	# Napojení na změnu velikosti okna
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
	# Zavoláme hned napoprvé, aby se správně zarovnaly i do aktuálního rozlišení
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	# Podíváme se na aktuální velikost viditelné oblasti (okna)
	var current_size = get_viewport_rect().size
	
	sub.global_position = Vector2(current_size.x * sub_rel.x, current_size.y * sub_rel.y)
	squid.global_position = Vector2(current_size.x * squid_rel.x, current_size.y * squid_rel.y)
	pufferfish.global_position = Vector2(current_size.x * pufferfish_rel.x, current_size.y * pufferfish_rel.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
