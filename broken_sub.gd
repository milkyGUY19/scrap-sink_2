extends Sprite2D

@onready var press_f: Label = $PressF

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	finish()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.name == "Submarine"):
		press_f.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if(body.name == "Submarine"):
		press_f.visible = false

func finish() -> void:
	if (Input.is_action_just_pressed("respect") and press_f.visible == true):
		get_tree().change_scene_to_file("res://WinScreen.tscn")
