extends VBoxContainer

@onready var fullscreen_checkbox: CheckBox = $Fullscreen

func _ready() -> void:
	# Načíst stav UI ze SettingsManageru místo z výchozích hodnot scény
	fullscreen_checkbox.button_pressed = SettingsManager.fullscreen
	

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.fullscreen = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
