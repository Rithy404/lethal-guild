extends CharacterBody2D

@onready var dialog_box: CanvasLayer = $DialogBox
@onready var interaction_area: Area2D = $InteractionArea

var player_nearby := false
var player_ref = null
var player_chose_yes := false  # Track if player accepted the test
var has_completed_dialog := false  # Track if initial dialog is done

# Customize your dialog here
var dialog_lines := [
	"Welcome to the Lethal Guild!\nI'm Emily, nice to meet you!",
	"First time here? You look a bit\nlost, haha!",
	"Don't let the name intimidate you -\nwe're actually pretty friendly!",
	"Our guild specializes in taking on\nthe toughest challenges.",
	"Whether it's hunting dangerous\nmonsters or exploring ancient ruins...",
	"...we train our members to become\nthe best adventurers they can be!",
	"[CHOICE]So, are you interested in joining?",
	"[YES]Fantastic! I had a feeling you\nwere serious about this!",
	"[YES]Before you can officially join,\nyou'll need a rank assessment.",
	"[YES]It helps us figure out what kind of\nquests suit your current abilities.",
	"[YES]Follow me to the training grounds!",
	"[NO]No worries! It's a big decision.",
	"[NO]Take your time to think it over.\nWe'll be here when you're ready!",
	"Feel free to explore the guild hall!\nSee you around!",
]

var npc_name := "Emily"
var npc_portrait: Texture2D = preload("res://assets/Character/emily.tres")

# Path to your test area scene
var test_scene_path := "res://scenes/test_area.tscn"  # Change to your actual path

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	dialog_box.dialog_finished.connect(_on_dialog_finished)
	dialog_box.choice_made.connect(_on_choice_made)

func _input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):
		if not dialog_box.is_talking:
			if player_ref:
				player_ref.can_move = false
			dialog_box.start_dialog(dialog_lines, npc_name, npc_portrait)

func _on_choice_made(choice: bool) -> void:
	if choice:
		print("Player chose YES - Will go to test")
		player_chose_yes = true
	else:
		print("Player chose NO - Can talk again later")
		player_chose_yes = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		print("Press Z or Enter to talk!")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null

func _on_dialog_finished() -> void:
	has_completed_dialog = true
	
	# Check if player chose YES and dialog is finished
	if player_chose_yes:
		transition_to_test()
	else:
		# Just unlock player movement if they said NO
		player_nearby = false
		if player_ref:
			player_ref.can_move = true
		print("Dialog ended!")

func transition_to_test() -> void:
	print("Transitioning to test area...")
	
	# Save player's current position and scene using existing Global variables
	if player_ref:
		Global.spawn_position = player_ref.global_position
	Global.from_scene = get_tree().current_scene.scene_file_path
	
	# Fade transition
	fade_to_test()

func fade_to_test() -> void:
	# Simple fade using ColorRect
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make it fullscreen
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	get_tree().current_scene.add_child(fade)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(test_scene_path)
