extends Area2D

var entered = false
var player_ref = null
var health = 0
var max_health = 0
var is_test_dummy = false
var health_bar = null

@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var label: Label = $"../Control/Label"

func _ready() -> void:
	add_to_group("dummies")
	
	# Get health bar node
	health_bar = get_node_or_null("../Control/HealthBar")
	
	# Check if this dummy or its parent is in test_dummy group
	var parent = get_parent()
	var is_test = is_in_group("test_dummy") or (parent and parent.is_in_group("test_dummy"))
	
	# Only test dummies have health
	if is_test:
		is_test_dummy = true
		max_health = 9999
		health = max_health
		
		# Setup health bar
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = health
			health_bar.show()
	else:
		# Hide health bar for regular dummies
		if health_bar:
			health_bar.hide()

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
	
	# Only test dummies track health
	if is_test_dummy:
		health -= amount
		
		# Update health bar
		if health_bar:
			health_bar.value = health
		
		# Optional: Keep one print for feedback
		print("Test dummy: %d/%d HP" % [health, max_health])
		
		if health <= 0:
			print("Test dummy defeated! (but still alive for test)")
	else:
		print("Dummy got hit!")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = true
		player_ref = body
		if label:
			label.visible = false

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		entered = false
		player_ref = null
		if label:
			label.visible = true
