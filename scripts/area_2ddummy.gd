extends Area2D

var entered = false
var player_ref = null
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var label: Label = $"../Control/Label"

func _ready() -> void:
	add_to_group("dummies")

func can_be_hit_by_player() -> bool:
	if not entered or player_ref == null:
		return false
	
	var dummy_pos = global_position
	var player_pos = player_ref.global_position
	var dir_to_dummy = (dummy_pos - player_pos).normalized()
	
	var mouse_pos = player_ref.get_global_mouse_position()
	var player_facing = (mouse_pos - player_pos).normalized()
	
	var dot = dir_to_dummy.dot(player_facing)
	return dot > 0.5

func take_damage(amount: int):
	animated_sprite_2d.play("hit")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("idle")
	print("Dummy got hit!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = true
		player_ref = body
		label.visible = false
		print("Player entered attack range")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = false
		player_ref = null
		label.visible = true
		print("Player left attack range")
