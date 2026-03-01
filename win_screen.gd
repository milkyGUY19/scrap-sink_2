extends Control

@onready var restart: Button = $WinScreenButtons/Restart
@onready var menu: Button = $WinScreenButtons/Menu
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play("new_animation")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_restart_pressed() -> void:
	pass

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
