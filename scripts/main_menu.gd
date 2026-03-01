extends Control

@onready var main_menu_buttons: VBoxContainer = $MainMenuButtons
@onready var options: Panel = $Options
@onready var game_name: Panel = $GameName


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_buttons.visible = true
	game_name.visible = true
	options.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")


func _on_options_pressed() -> void:
	main_menu_buttons.visible = false
	game_name.visible = false
	options.visible = true

func _on_back_pressed() -> void:
	_ready()
