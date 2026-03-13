extends Area2D

var entered = false
@onready var camera_2d_2: Camera2D = $"../Y sort/Player/Camera2D2"
@onready var player: CharacterBody2D = $"../Y sort/Player"
@onready var fade_rect: ColorRect = ColorRect.new()

# NEW: Popup UI
@onready var popup_panel: Panel = Panel.new()
@onready var popup_label: Label = Label.new()
var popup_timer: float = 0.0
var showing_popup: bool = false

@export var target_scene: String = "res://scenes/dungeon_f_1.tscn"
@export var spawn_offset: Vector2 = Vector2(393, 408)

func _ready():
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
	
	# NEW: Create popup UI
	setup_popup_ui(canvas_layer)

func setup_popup_ui(canvas_layer: CanvasLayer):
	# Panel background
	popup_panel.custom_minimum_size = Vector2(400, 150)
	popup_panel.position = Vector2(
		(get_viewport().size.x - 400) / 2,
		(get_viewport().size.y - 150) / 2
	)
	popup_panel.add_theme_stylebox_override("panel", create_panel_style())
	popup_panel.hide()
	canvas_layer.add_child(popup_panel)
	
	# Label text
	popup_label.text = "Access Denied!\n\nOnly registered adventurers may enter.\nPlease take the rank test at the Guild first."
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_label.size = Vector2(380, 130)
	popup_label.position = Vector2(10, 10)
	
	# Style the text
	popup_label.add_theme_font_size_override("font_size", 18)
	popup_label.add_theme_color_override("font_color", Color.WHITE)
	
	popup_panel.add_child(popup_label)

func create_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)  # Dark semi-transparent
	style.border_color = Color(0.8, 0.2, 0.2, 1.0)  # Red border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func _on_body_entered(body: Node2D) -> void:
	if body is PhysicsBody2D:
		entered = true

func _on_body_exited(body: Node2D) -> void:
	if body is PhysicsBody2D:
		entered = false
		# Hide popup when leaving area
		if showing_popup:
			hide_popup()

func _physics_process(delta):
	# Handle popup timer
	if showing_popup:
		popup_timer -= delta
		if popup_timer <= 0.0:
			hide_popup()
	
	# Check for enter input
	if entered and Input.is_action_just_pressed("enter"):
		if Global.has_taken_test:
			zoom_transition_and_change_scene()
		else:
			show_popup()

func show_popup():
	if not showing_popup:
		showing_popup = true
		popup_timer = 5.0
		popup_panel.show()
		print("Access denied! Player must take rank test first.")

func hide_popup():
	showing_popup = false
	popup_timer = 0.0
	popup_panel.hide()

func zoom_transition_and_change_scene():
	# 1. ZOOM toward PLAYER
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera_2d_2, "zoom", Vector2(15.0, 15.0), 0.5)
	tween.tween_property(camera_2d_2, "global_position", player.global_position, 0.5)
	
	await tween.finished
	
	# Fade to black
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_tween.finished
	
	Global.spawn_position = spawn_offset
	get_tree().change_scene_to_file(target_scene)
