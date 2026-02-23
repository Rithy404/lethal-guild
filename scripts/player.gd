extends CharacterBody2D

const SPEED = 67.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var quest_ui: TextureRect = $CanvasLayer/Quest

var last_dir = Vector2.ZERO   # stores the last direction faced
var is_attacking = false
var can_move = true

# HP System
var max_health = 100
var current_health = 100


func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	global_position = Global.spawn_position
	if Global.spawn_position == Vector2.ZERO:
		global_position = Vector2(200, 275)  # Fallback spawn
	
	# Initialize HP bar
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	if quest_ui:
		quest_ui.hide()
	
	# Only restore quest if there's an active quest
	restore_quest_from_global()


func _physics_process(delta: float) -> void:
	if is_attacking or not can_move:
		return  # Skip movement and input during attack
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	
	# Handle attack input
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attack()
		return
	
	# Save last facing direction
	if x != 0 or y != 0:
		last_dir = Vector2(x, y).normalized()
	# Flip for horizontal only
	if x > 0:
		animated_sprite.flip_h = false
	elif x < 0:
		animated_sprite.flip_h = true
	# Choose animation
	if y != 0:
		if y > 0:
			animated_sprite.play("walk_yminus")  # moving down
		else:
			animated_sprite.play("walk_yplus")   # moving up
	elif x != 0:
		animated_sprite.play("walk_x")
	else:
		# Character stopped → play idle based on last direction
		if last_dir.y > 0:
			animated_sprite.play("idle_yminus")  # last moved DOWN
		elif last_dir.y < 0:
			animated_sprite.play("idle_yplus")   # last moved UP
		else:
			animated_sprite.play("idle_x")        # last direction was horizontal
	
	# Movement
	var input_dir = Vector2(x, y).normalized()
	if input_dir != Vector2.ZERO:
		velocity = input_dir * SPEED
	else:
		# slow stop (optional)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	move_and_slide()

func attack():
	if is_attacking:
		return
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var dir_to_mouse = (mouse_pos - player_pos).normalized()
	
	# Determine attack direction based on FULL mouse direction
	var attack_anim = ""
	if abs(dir_to_mouse.y) > abs(dir_to_mouse.x):
		# Primarily vertical
		if dir_to_mouse.y > 0:
			attack_anim = "attack_down"   # mouse down
		else:
			attack_anim = "attack_up"     # mouse up
	else:
		# Primarily horizontal
		attack_anim = "attack_right"
	
	# Flip ONLY for horizontal right attack
	animated_sprite.flip_h = (dir_to_mouse.x < 0 and attack_anim == "attack_right")
	animated_sprite.play(attack_anim)
	is_attacking = true
	
	# CHECK FOR DUMMY HIT
	check_dummy_hit()

func check_dummy_hit():
	# Find all Area2D nodes in range (you can use groups or get_overlapping_areas)
	var space_state = get_world_2d().direct_space_state
	
	# Or better: use groups
	var dummies = get_tree().get_nodes_in_group("dummies")
	for dummy in dummies:
		if dummy.has_method("can_be_hit_by_player"):
			if dummy.can_be_hit_by_player():
				print("HIT THE DUMMY!")
				# Call damage function on dummy
				if dummy.has_method("take_damage"):
					dummy.take_damage(10)

# HP System Functions
func take_damage(amount: int):
	current_health -= amount
	current_health = max(0, current_health)  # Don't go below 0
	update_hp_bar()
	
	print("Player took %d damage! HP: %d/%d" % [amount, current_health, max_health])
	
	# Optional: Play hurt animation/sound
	# play_hurt_animation()
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	current_health = min(max_health, current_health)  # Don't exceed max
	update_hp_bar()
	
	print("Player healed %d HP! HP: %d/%d" % [amount, current_health, max_health])

func update_hp_bar():
	if hp_bar:
		hp_bar.value = current_health

func die():
	print("Player died!")
	can_move = false
	# Add death logic here:
	# - Play death animation
	# - Show game over screen
	# - Respawn player
	# - etc.

func _on_animation_finished():
	if animated_sprite.animation in ["attack_right", "attack_up", "attack_down"]:
		is_attacking = false
		# Resume idle animation based on last_dir
		if last_dir.y > 0:
			animated_sprite.play("idle_yminus")
		elif last_dir.y < 0:
			animated_sprite.play("idle_yplus")
		else:
			animated_sprite.play("idle_x")

func restore_quest_from_global():
	# Check if there's actually an active quest to restore
	if Global.has_active_quest and not Global.active_quest.is_empty():
		# Restore quest to UI
		if quest_ui:
			quest_ui.show_quest(Global.active_quest)
			quest_ui.update_quest_progress(Global.quest_progress, Global.quest_target)
		print("Quest restored: ", Global.active_quest.get("title", "Unknown"))
	else:
		# No active quest, make sure UI is hidden
		if quest_ui:
			quest_ui.hide()
		print("No active quest to restore")
func accept_quest(quest_data: Dictionary):
	if Global.has_active_quest:
		print("Already have an active quest!")
		return false
	
	# Save to Global
	Global.active_quest = quest_data
	Global.has_active_quest = true
	
	# Extract target number from quest
	var target = extract_quest_target(quest_data.get("title", ""))
	Global.quest_target = target
	Global.quest_progress = 0
	
	# Show on UI
	if quest_ui:
		quest_ui.show_quest(quest_data)
	
	print("Quest accepted: ", quest_data.get("title", "Unknown"))
	return true

func extract_quest_target(title: String) -> int:
	# Extract number from "Kill 10 Slimes" -> 10
	var words = title.split(" ")
	for word in words:
		if word.is_valid_int():
			return int(word)
	return 0

func update_quest_progress(amount: int):
	if Global.has_active_quest:
		Global.quest_progress += amount
		
		if quest_ui:
			quest_ui.update_quest_progress(Global.quest_progress, Global.quest_target)
		
		# Check if quest is complete
		if Global.quest_progress >= Global.quest_target:
			complete_quest()

func complete_quest():
	if Global.has_active_quest:
		var reward = Global.active_quest.get("reward", 0)
		print("Quest completed! Reward: %d Gold" % reward)
		
		# Give reward (implement gold system later)
		# Global.player_gold += reward
		
		if quest_ui:
			quest_ui.complete_quest()
		
		# Clear global quest data
		Global.has_active_quest = false
		Global.active_quest.clear()
		Global.quest_progress = 0
		Global.quest_target = 0
