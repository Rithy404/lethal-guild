extends Node2D


@onready var test_dummy: Area2D = $Dummy/Area2D
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var player_spawn: Marker2D = $PlayerSpawnPoint
@onready var dialog_box: CanvasLayer = $CanvasLayer/DialogBox
@onready var player_ref: CharacterBody2D = $Player

var test_active = false
var time_remaining = 30.0

func _ready() -> void:
	timer_label.hide()
	if test_dummy:
		test_dummy.hide()
	
	# Auto-start test when scene loads
	await get_tree().process_frame  # Wait one frame for everything to initialize
	
	if player_ref:
		start_test()
	else:
		print("ERROR: Player not found in test area!")

func start_test() -> void:
	test_active = true
	time_remaining = 30.0
	
	# Move player to spawn point
	if player_spawn and player_ref:
		player_ref.global_position = player_spawn.global_position
	
	player_ref.can_move = false
	
	# Setup dummy
	if test_dummy:
		# Add to test_dummy group programmatically
		var dummy_parent = test_dummy.get_parent()
		if dummy_parent:
			dummy_parent.add_to_group("test_dummy")  # Add this line
			dummy_parent.show()
		
		test_dummy.health = 9999
		test_dummy.is_test_dummy = true
	
	show_test_instructions()

func show_test_instructions() -> void:
	var instructions = [
		"Alright! Time for your test!",
		"See that training dummy?",
		"Defeat it within 30 seconds!",
		"Show me what you've got!"
	]
	dialog_box.start_dialog(instructions, "Emily")
	await dialog_box.dialog_finished
	
	countdown()

func countdown() -> void:
	timer_label.show()
	timer_label.modulate = Color.WHITE
	timer_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	timer_label.text = "GO!"
	timer_label.modulate = Color.GREEN
	await get_tree().create_timer(0.5).timeout
	
	# Unlock player movement
	if player_ref:
		player_ref.can_move = true
	
	start_timer()

func start_timer() -> void:
	while time_remaining > 0 and test_active:
		time_remaining -= 1.0
		timer_label.text = "Time: " + str(int(time_remaining))
		
		# Change color as time runs out
		if time_remaining <= 10:
			timer_label.modulate = Color.RED
		elif time_remaining <= 20:
			timer_label.modulate = Color.YELLOW
		
		await get_tree().create_timer(1.0).timeout
	
	if test_active:
		test_failed()

func test_failed() -> void:
	test_active = false
	timer_label.hide()
	
	if test_dummy:
		test_dummy.hide()
	
	# Lock player again
	if player_ref:
		player_ref.can_move = false
	
	var fail_dialog = [
		"Time's up!",
		"Hmm... you couldn't even scratch it.",
		"That's okay! Everyone starts\nsomewhere.",
		"Based on your performance...",
		"I'm assigning you Rank F!",
		"F-Rank adventurers start with\nsimple quests.",
		"Complete quests to gain experience\nand rank up!",
		"Your adventure starts now!\nGood luck!"
	]
	dialog_box.start_dialog(fail_dialog, "Emily")
	await dialog_box.dialog_finished
	
	# Assign rank and finish
	assign_rank_f()

func assign_rank_f() -> void:
	if player_ref:
		Global.player_rank = "F"
		Global.has_taken_test = true
		player_ref.can_move = true
	
	print("Player received Rank F!")
	
	# Return to guild hall
	return_to_guild()

func return_to_guild() -> void:
	# Fade out
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	get_tree().current_scene.add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	# Return to previous scene using Global.from_scene
	if Global.from_scene != "":
		# Set spawn position for guild hall
		Global.spawn_position = Vector2(602, 565)  # Position near Emily or guild entrance
		get_tree().change_scene_to_file(Global.from_scene)
		Global.from_scene = ""
	else:
		# Fallback to guild hall
		print("Warning: No return scene set!")
		Global.spawn_position = Vector2(602, 565)
		get_tree().change_scene_to_file("res://scenes/guild.tscn")
