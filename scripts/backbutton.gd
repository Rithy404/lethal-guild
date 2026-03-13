extends TextureButton

const BACKBUTTONPHOLD = preload("uid://u1ckna71h1yp")
const BACKBUTTONIDLE = preload("uid://ck2bmm1ly0eos")
@export var target_scene: String = "res://scenes/main_menu.tscn"
func _ready() -> void:
	texture_normal = BACKBUTTONIDLE

func _on_button_down() -> void:
	texture_normal = BACKBUTTONPHOLD

func _on_button_up() -> void:
	texture_normal = BACKBUTTONIDLE 

func _on_pressed() -> void:
	get_tree().change_scene_to_file(target_scene)
