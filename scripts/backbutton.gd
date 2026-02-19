extends TextureButton

const BACKBUTTONPHOLD = preload("uid://u1ckna71h1yp")
const BACKBUTTONIDLE = preload("uid://ck2bmm1ly0eos")

func _ready() -> void:
	texture_normal = BACKBUTTONIDLE

func _on_button_down() -> void:
	texture_normal = BACKBUTTONPHOLD

func _on_button_up() -> void:
	texture_normal = BACKBUTTONIDLE 

func _on_pressed() -> void:
	pass
