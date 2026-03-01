extends Panel

@onready var pause_panel: Panel = self
@onready var pause_buttons: VBoxContainer = %PauseButtons
@onready var options: Panel = %Options
@onready var game_paused: Label = $GamePaused


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pause_buttons.visible = true
	options.visible = false
	game_paused.visible = true
	
func resume():
	get_tree().paused = false

func paused():
	get_tree().paused = true
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if options.visible:
			_ready()
		else:
			var is_paused = !get_tree().paused
			get_tree().paused = is_paused
			pause_panel.visible = is_paused
func _on_continue_pressed() -> void:
	resume()
	pause_panel.hide()

func _on_menu_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_options_pressed() -> void:
	pause_buttons.visible = false
	options.visible = true
	game_paused.visible = false

func _on_back_pressed() -> void:
	_ready()
