extends Button

@export var target_scene: String = "res://scenes/game.tscn"


func _on_pressed() -> void:
	get_tree().change_scene_to_file(target_scene)
