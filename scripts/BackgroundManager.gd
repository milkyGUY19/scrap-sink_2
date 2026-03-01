extends Control
class_name BackgroundManager

@export var water_bg: Panel
@export var water_overlay: Panel

@export var shallow_color: Color = Color(0.094, 0.553, 0.773, 1.0) # #188cce
@export var deep_color: Color = Color(0.008, 0.094, 0.149, 1.0)    # #021826

func _ready() -> void:
	# Připojíme se k signálu, který oznamuje změnu hloubky
	GameManager.depth_changed.connect(_on_depth_changed)
	
	# Pokud jsme zapomněli přiřadit nody z editoru, najdeme si je
	if not water_bg:
		water_bg = get_node_or_null("WaterTop")
	if not water_overlay:
		water_overlay = get_node_or_null("../WaterTopUnderwater")
		
	# Aplikujeme stav úplně nahoře při startu hry
	_on_depth_changed(GameManager.current_depth)

func _on_depth_changed(current_depth_m: float) -> void:
	# Spočítáme faktor pro míchání barev: 0.0 na hladině plná mělká, 1.0 v hlubině plně temná barva
	# Pozor, omezujeme se na max 1.0 (úplně na samém dně v M1600+), aby se to netmavilo ještě dál
	var blend_factor = clamp(current_depth_m / GameManager.MAX_GAME_DEPTH, 0.0, 1.0)
	
	# Smícháme barvy funkcí lerp (lineární interpolace) - 0.5 bude přesně tvořit tu požadovanou střední "Temnotu"
	var current_color = shallow_color.lerp(deep_color, blend_factor)
	
	if water_bg:
		water_bg.modulate = current_color
	
	if water_overlay:
		# U overlaye chceme zachovat původní průhlednost ze StyleBoxu, takže Alpha necháme na 1.0 (násobí se 1x)
		water_overlay.modulate = Color(current_color.r, current_color.g, current_color.b, 1.0)
