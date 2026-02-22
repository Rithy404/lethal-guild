extends CharacterBody2D

@onready var dialog_box: CanvasLayer = $DialogBox
@onready var interaction_area: Area2D = $InteractionArea
@onready var quest_ui: CanvasLayer = $"../../QuestBoardUI"



var player_nearby := false
var player_ref = null
var player_chose_yes := false
var has_completed_dialog := false

# Dialog for NEW players (no rank yet)
var initial_dialog := [
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
	"[NO]Feel free to explore the guild hall!\nSee you around!",
]

var returning_dialog := [
	"Welcome back!",
	"Ready to take on some quests?",
	"Let me show you what's available!",
]

var npc_name := "Emily"
var npc_portrait: Texture2D = preload("res://assets/Character/emily.tres")
var test_scene_path := "res://scenes/test_area.tscn"

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
			
			# Check if player already has a rank
			if Global.has_taken_test or Global.player_rank != "":
				dialog_box.start_dialog(returning_dialog, npc_name, npc_portrait)
			else:
				dialog_box.start_dialog(initial_dialog, npc_name, npc_portrait)

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

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		player_ref = null

func _on_dialog_finished() -> void:
	has_completed_dialog = true
	
	# Check if player has rank
	if Global.has_taken_test or Global.player_rank != "":
		# Player has rank - show quest UI
		show_quest_ui()
	elif player_chose_yes:
		# New player chose YES - go to test
		transition_to_test()
	else:
		# New player chose NO or just talking
		player_nearby = false
		if player_ref:
			player_ref.can_move = true
		print("Dialog ended!")

func show_quest_ui():
	player_nearby = false
	
	if quest_ui:
		# Sample F-Rank quests (you'll load this from data later)
		var f_rank_quests = [
			{"title": "Kill 10 Slimes", "reward": 25, "difficulty": "Easy"},
			{"title": "Kill 10 Lizards", "reward": 50, "difficulty": "Easy"},
			{"title": "Kill A Giant", "reward": 80, "difficulty": "Medium"},
		]
		
		quest_ui.populate_quests(f_rank_quests)
		quest_ui.show_quest_board()
	else:
		print("Error: Quest UI not found!")
		if player_ref:
			player_ref.can_move = true

func transition_to_test() -> void:
	print("Transitioning to test area...")
	
	if player_ref:
		Global.spawn_position = player_ref.global_position
	Global.from_scene = get_tree().current_scene.scene_file_path
	
	fade_to_test()

func fade_to_test() -> void:
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	get_tree().current_scene.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(test_scene_path)
