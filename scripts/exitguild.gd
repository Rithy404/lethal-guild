extends Area2D

var entered = false
@export var target_scene: String = "res://scenes/game.tscn"
@export var spawn_position: Vector2 = Vector2(25, 217)
@onready var camera_2d: Camera2D = $"../Player/Camera2D"
@onready var fade_rect: ColorRect = ColorRect.new()

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Create black fade overlay INSIDE CanvasLayer
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.size = Vector2.ZERO  # Anchors handle sizing
	fade_rect.modulate.a = 0.0  # Start invisible
	canvas_layer.add_child(fade_rect)

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true
	print("Enter")

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false
	print("Exit")

# KEEP your original physics_process for KEYBOARD input
func _physics_process(_delta):
	if entered and Input.is_action_just_pressed("enter"):
		print("PRESSED ENTER")
		zoom_transition_and_change_scene()

func zoom_transition_and_change_scene():
	if not camera_2d:
		return
	
	# 1. ZOOM first
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera_2d, "zoom", Vector2(15.0, 15.0), 0.5)
	tween.tween_property(camera_2d, "global_position", global_position, 0.5)
	
	await tween.finished
	
	# 2. FADE TO BLACK (0.3s)
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	
	await fade_tween.finished
	
	# 3. Change scene
	Global.spawn_position = spawn_position
	get_tree().change_scene_to_file(target_scene)
