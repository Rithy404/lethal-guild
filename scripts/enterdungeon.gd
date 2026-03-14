extends Area2D

var entered = false
@onready var camera_2d_2: Camera2D = $"../Y sort/Player/Camera2D2"
@onready var player: CharacterBody2D = $"../Y sort/Player"
@onready var fade_rect: ColorRect = ColorRect.new()
@onready var dungeon_floors: CanvasLayer = $"../DungeonFloors"

# Popup UI
@onready var popup_panel: Panel = Panel.new()
@onready var popup_label: Label = Label.new()
var popup_timer: float = 0.0
var showing_popup: bool = false

# Floor scenes
var floor_scenes = {
	1: "res://scenes/dungeon_f_1.tscn",
	2: "res://scenes/dungeon_f_2.tscn",  # Not created yet
	3: "res://scenes/dungeon_f_3.tscn",  # Not created yet
	4: "res://scenes/dungeon_f_4.tscn",  # Not created yet
	5: "res://scenes/dungeon_f_5.tscn",  # Not created yet
}

var floor_spawn_positions = {
	1: Vector2(393, 408),
	2: Vector2(200, 200),  # Placeholder
	3: Vector2(200, 200),  # Placeholder
	4: Vector2(200, 200),  # Placeholder
	5: Vector2(200, 200),  # Placeholder
}

func _ready():
	# Create CanvasLayer for fade and popup
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	# Black fade overlay
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.size = Vector2.ZERO
	fade_rect.modulate.a = 0.0
	canvas_layer.add_child(fade_rect)
	
	# Setup popup UI
	setup_popup_ui(canvas_layer)
	
	# Connect dungeon floors UI callback
	if dungeon_floors:
		dungeon_floors.on_floor_selected = _on_floor_selected

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
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(0.8, 0.2, 0.2, 1.0)
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
			# NEW: Show floor selection instead of direct transition
			show_floor_selection()
		else:
			show_popup()

func show_floor_selection():
	if dungeon_floors:
		dungeon_floors.show_floor_selection()
	else:
		print("Error: DungeonFloors UI not found!")

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

# NEW: Called when a floor is selected
func _on_floor_selected(floor_number: int):
	print("Entering floor %d..." % floor_number)
	
	var target_scene = floor_scenes.get(floor_number, "")
	var spawn_position = floor_spawn_positions.get(floor_number, Vector2(200, 200))
	
	if target_scene.is_empty():
		print("Error: Floor %d scene not found!" % floor_number)
		return
	
	# Zoom and transition
	zoom_transition_and_change_scene(target_scene, spawn_position)

func zoom_transition_and_change_scene(target_scene: String, spawn_offset: Vector2):
	# Zoom toward player
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(camera_2d_2, "zoom", Vector2(15.0, 15.0), 0.5)
	tween.tween_property(camera_2d_2, "global_position", player.global_position, 0.5)
	
	await tween.finished
	
	# Fade to black
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_tween.finished
	
	# Change scene
	Global.spawn_position = spawn_offset
	get_tree().change_scene_to_file(target_scene)
