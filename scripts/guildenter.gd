extends Area2D

var entered = false
@export var target_scene: String = "res://scenes/guild.tscn"
@export var spawn_offset: Vector2 = Vector2(580, 620)  # Adjust for outside building

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _physics_process(_delta):
	if entered and Input.is_action_just_pressed("enter"):
		Global.spawn_position = spawn_offset  # Exit spot
		get_tree().change_scene_to_file(target_scene)
