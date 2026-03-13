extends Area2D

var player_fell: bool = false
@onready var fade_rect: ColorRect = ColorRect.new()
@onready var game_over_label: Label = Label.new()
var canvas_layer = CanvasLayer.new()# Above everything
func _ready():
	# Connect signal
	body_entered.connect(_on_body_entered)
	
	# Create CanvasLayer for game over screen

	add_child(canvas_layer)
	
	# Black fade overlay
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.modulate.a = 0.0
	canvas_layer.add_child(fade_rect)
	
	# Game Over text
	game_over_label.text = "GAME OVER \n YOU FELL OFF"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.anchor_right = 1.0
	game_over_label.anchor_bottom = 1.0
	game_over_label.add_theme_font_size_override("font_size", 72)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	game_over_label.modulate.a = 0.0
	canvas_layer.add_child(game_over_label)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not player_fell:
		player_fell = true
		player_fell_into_hole(body)

func player_fell_into_hole(player: CharacterBody2D):
	print("Player fell into hole!")
	canvas_layer.layer = 100
	# Stop player movement
	if player.has_method("die"):
		player.can_move = false
		player.velocity = Vector2.ZERO
	
	# Fade to black
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await fade_tween.finished
	
	# Show GAME OVER text
	var text_tween = create_tween()
	text_tween.tween_property(game_over_label, "modulate:a", 1.0, 1.0)
	await text_tween.finished
	
	# Wait 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	# Reset everything and go to main menu
	reset_game()

func reset_game():
	print("Resetting game to initial state...")
	
	# Reset all Global variables
	Global.spawn_position = Vector2.ZERO
	Global.from_scene = ""
	Global.player_rank = ""
	Global.has_taken_test = false
	
	# Reset quest
	Global.active_quest.clear()
	Global.has_active_quest = false
	Global.quest_progress = 0
	Global.quest_target = 0
	
	# Reset level and experience
	Global.player_level = 1
	Global.player_exp = 0
	Global.player_exp_to_next_level = 100
	Global.stat_points = 0
	
	# Reset stats
	Global.player_strength = 0
	Global.player_speed_bonus = 0
	Global.player_health_bonus = 0
	Global.player_current_health = 100
	
	print("All stats reset! Returning to main menu...")
	
	# Go to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
