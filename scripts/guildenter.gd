extends Area2D

var entered = false
@onready var camera_2d_2: Camera2D = $"../Player/Camera2D2"
@export var target_scene: String = "res://scenes/guild.tscn"
@export var spawn_offset: Vector2 = Vector2(580, 620)
@onready var fade_rect: ColorRect = ColorRect.new()
@onready var player: CharacterBody2D = $"../Player"
func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create CanvasLayer for full-screen fade
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Black fade overlay
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.size = Vector2.ZERO
	fade_rect.modulate.a = 0.0
	canvas_layer.add_child(fade_rect)

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true
	print("Enter")

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false
	print("Exit")

func _physics_process(_delta):
	if entered and Input.is_action_just_pressed("enter"):
		print("PRESSED ENTER")
		zoom_transition_and_change_scene()

func zoom_transition_and_change_scene():
	if not camera_2d_2:
		print("No camera found!")
		return
	



	# 1. ZOOM toward PLAYER (not door)
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera_2d_2, "zoom", Vector2(15.0, 15.0), 0.5)
	# Keep camera on PLAYER position during zoom
	tween.tween_property(camera_2d_2, "global_position", player.global_position, 0.5)
	
	await tween.finished
	
	# Rest stays same...
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_tween.finished
	
	Global.spawn_position = spawn_offset
	get_tree().change_scene_to_file(target_scene)
