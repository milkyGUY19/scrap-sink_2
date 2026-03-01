extends Node2D

@onready var wave_reverse: AnimatedSprite2D = $WaveReverse

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wave_reverse.play("default")
	
	# Zjistíme celkový počet snímků animace
	var frame_count = wave_reverse.sprite_frames.get_frame_count("default")
	
	# Vypočítáme pořadí vlny podle její pozice
	var wave_index = int(global_position.x / 60.0)
	
	# Nastavíme počáteční snímek na přeskáčku:
	# Sudé vlny začnou na snímku 0 (nejnižší)
	# Liché vlny začnou na posledním snímku (nejvyšší)
	if wave_index % 2 == 0:
		wave_reverse.frame = 0
	else:
		if frame_count > 0:
			wave_reverse.frame = frame_count - 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
