extends HSlider

@export var audio_bus_name: String

var audio_bus_id

func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	# Načíst uloženou hodnotu ze SettingsManageru při startu
	if audio_bus_name == "Master":
		value = SettingsManager.master_volume
	elif audio_bus_name == "SFX":
		value = SettingsManager.sfx_volume
	elif audio_bus_name == "Music":
		value = SettingsManager.music_volume
		
	# Připojit signál pro změny z UI
	value_changed.connect(_on_value_changed)

func _on_value_changed(val: float) -> void:
	# Aplikovat hlasitost do AudioServeru
	var db = linear_to_db(val)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	
	# Uložit do SettingsManageru
	if audio_bus_name == "Master":
		SettingsManager.master_volume = val
	elif audio_bus_name == "SFX":
		SettingsManager.sfx_volume = val
	elif audio_bus_name == "Music":
		SettingsManager.music_volume = val
		
	SettingsManager.save_settings()
