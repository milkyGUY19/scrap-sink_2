extends Node

const SETTINGS_FILE = "user://settings.cfg"

var master_volume: float = 1.0
var sfx_volume: float = 0.5
var music_volume: float = 0.5

var fullscreen: bool = false
var vsync: bool = true
var resolution: Vector2i = Vector2i(1920, 1080)

func _ready() -> void:
	load_settings()
	apply_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("Audio", "master_volume", master_volume)
	config.set_value("Audio", "sfx_volume", sfx_volume)
	config.set_value("Audio", "music_volume", music_volume)
	
	config.set_value("Video", "fullscreen", fullscreen)
	config.set_value("Video", "vsync", vsync)
	config.set_value("Video", "resolution", resolution)
	
	config.save(SETTINGS_FILE)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		master_volume = config.get_value("Audio", "master_volume", 1.0)
		sfx_volume = config.get_value("Audio", "sfx_volume", 0.5)
		music_volume = config.get_value("Audio", "music_volume", 0.5)
		
		fullscreen = config.get_value("Video", "fullscreen", false)
		vsync = config.get_value("Video", "vsync", true)
		resolution = config.get_value("Video", "resolution", Vector2i(1920, 1080))

func apply_settings() -> void:
	# Aplikace zvuku
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
	
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	
	# Aplikace obrazu
	var window = get_window()
	if fullscreen:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = resolution
		
		# Zarovnání okna na střed
		var screen_id = window.current_screen
		var screen_rect = DisplayServer.screen_get_usable_rect(screen_id)
		var center_pos = screen_rect.position + (screen_rect.size / 2) - (Vector2i(resolution) / 2)
		window.position = center_pos

		
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
