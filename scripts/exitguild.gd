extends Area2D

var entered = false
@export var target_scene: String = "res://scenes/game.tscn"
@export var spawn_position: Vector2 = Vector2(30, 217)
@onready var fade_rect: ColorRect = ColorRect.new()
@onready var camera_2d: Camera2D = $"../Ysort/Player/Camera2D"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../Ysort/Emily/AnimatedSprite2D"

func _ready():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Create black fade overlay INSIDE CanvasLayer
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.size = Vector2.ZERO  # Anchors handle sizing
	fade_rect.modulate.a = 0.0  # Start invisible
	canvas_layer.add_child(fade_rect)

func _on_body_entered(body: Node2D) -> void:
	if body is PhysicsBody2D:
		entered = true
		animated_sprite_2d.play("wave")

func _on_body_exited(body: Node2D) -> void:
	if body is PhysicsBody2D:
		entered = false
		animated_sprite_2d.play("default")

# KEEP your original physics_process for KEYBOARD input
func _physics_process(_delta):
	if entered and Input.is_action_just_pressed("enter"):
		zoom_transition_and_change_scene()

func zoom_transition_and_change_scene():
	# 1. ZOOM first
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera_2d, "zoom", Vector2(10.0, 10.0), 0.5)
	tween.tween_property(camera_2d, "global_position", global_position, 0.5)
	await tween.finished
	# 2. FADE TO BLACK (0.3s)
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_tween.finished
	# 3. Change scene
	Global.spawn_position = spawn_position
	get_tree().change_scene_to_file(target_scene)
