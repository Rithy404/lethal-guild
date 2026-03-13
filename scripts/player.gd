extends CharacterBody2D

const SPEED = 67.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var quest_ui: TextureRect = $CanvasLayer/Quest
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var exp_bar: TextureProgressBar = $CanvasLayer/Experience
@onready var upgrade_ui: TextureRect = $CanvasLayer/UpgradeUI

var last_dir = Vector2.ZERO
var is_attacking = false
var can_move = true

# HP System
var max_health = 100
var current_health = 100
var is_dead = false

# Regeneration System
var time_since_last_damage: float = 0.0
var regen_delay: float = 5.0  # Wait 5 seconds before regen starts
var regen_rate: float = 2.0  # Heal 2 HP per second
var is_regenerating: bool = false

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if upgrade_ui:
		upgrade_ui.hide()

	# Connect death screen signal
	if death_screen:
		death_screen.respawn_player.connect(_on_respawn)
	
	# Handle spawn position
	global_position = Global.spawn_position
	if Global.spawn_position == Vector2.ZERO:
		global_position = Vector2(200, 275)
	
	# Initialize HP bar
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	
	# Initialize EXP bar - ADD THIS
	if exp_bar:
		exp_bar.max_value = Global.player_exp_to_next_level
		exp_bar.value = Global.player_exp
		print("EXP bar initialized!")
	else:
		print("Warning: EXP bar not found!")
	
	
	# Apply stat bonuses - ADD THIS
	apply_stat_bonuses()
	
	# Hide quest UI initially
	if quest_ui:
		quest_ui.hide()
	
	# Restore active quest
	restore_quest_from_global()
	
func apply_stat_bonuses():
	# Apply health bonus
	var total_max_health = 100 + (Global.player_health_bonus * 10)  # Each point = +10 max HP
	max_health = total_max_health
	current_health = min(current_health, max_health)  # Don't exceed new max
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	
	print("Stats applied - Max HP: %d, Strength: %d, Speed bonus: %d" % [max_health, Global.player_strength, Global.player_speed_bonus])
	
func _physics_process(delta: float) -> void:
	if is_attacking or not can_move or is_dead:
		return
	
	var x := Input.get_axis("move_left", "move_right")
	var y := Input.get_axis("move_up", "move_down")
	
	# Simple attack - just add back what was working before
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
			animated_sprite.play("walk_yminus")
		else:
			animated_sprite.play("walk_yplus")
	elif x != 0:
		animated_sprite.play("walk_x")
	else:
		if last_dir.y > 0:
			animated_sprite.play("idle_yminus")
		elif last_dir.y < 0:
			animated_sprite.play("idle_yplus")
		else:
			animated_sprite.play("idle_x")
	
	# Movement
	var total_speed = SPEED + (Global.player_speed_bonus * 5)  # Each point = +5 speed
	var input_dir = Vector2(x, y).normalized()
	if input_dir != Vector2.ZERO:
		velocity = input_dir * total_speed  # ← Use total_speed
	else:
		velocity.x = move_toward(velocity.x, 0, total_speed)  # ← Use total_speed
		velocity.y = move_toward(velocity.y, 0, total_speed)  # ← Use total_speed
	
	move_and_slide()
	
				
func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Handle regeneration
	if current_health < max_health:
		time_since_last_damage += delta
		
		# Start regenerating after delay
		if time_since_last_damage >= regen_delay:
			if not is_regenerating:
				is_regenerating = true
				print("Started regenerating health")
			
			# Heal over time
			var heal_amount = regen_rate * delta
			current_health += heal_amount
			current_health = min(current_health, max_health)  # Cap at max
			update_hp_bar()
			
			# Stop regenerating when full
			if current_health >= max_health:
				current_health = max_health
				is_regenerating = false
				print("Health fully regenerated!")
	else:
		is_regenerating = false
		time_since_last_damage = 0.0

func attack():
	if is_attacking:
		return
	
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	var dir_to_mouse = (mouse_pos - player_pos).normalized()
	
	# Determine attack animation and FIXED direction
	var attack_anim = ""
	var attack_direction = Vector2.ZERO
	
	if abs(dir_to_mouse.y) > abs(dir_to_mouse.x):
		# Vertical attack
		if dir_to_mouse.y > 0:
			attack_anim = "attack_down"
			attack_direction = Vector2(0, 1)
		else:
			attack_anim = "attack_up"
			attack_direction = Vector2(0, -1)
	else:
		# Horizontal attack
		attack_anim = "attack_right"
		attack_direction = Vector2(1, 0) if dir_to_mouse.x > 0 else Vector2(-1, 0)
	
	animated_sprite.flip_h = (attack_direction.x < 0 and attack_anim == "attack_right")
	animated_sprite.play(attack_anim)
	is_attacking = true
	
	# Check for hits in the FIXED attack direction
	check_attack_hits(attack_direction)

func check_attack_hits(attack_direction: Vector2):
	var attack_range = 10.0
	var attack_offset = 12.0
	var min_dot = 0.5
	
	# Calculate damage based on strength - MODIFY THIS
	var base_damage = 10
	var total_damage = base_damage + (Global.player_strength * 2)  # Each strength point = +2 damage
	
	var attack_origin = global_position + (attack_direction * attack_offset)
	
	# Check enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = attack_origin.distance_to(enemy.global_position)
		if distance > attack_range:
			continue
		
		var dir_to_enemy = (enemy.global_position - global_position).normalized()
		var dot = dir_to_enemy.dot(attack_direction)
		
		if dot > min_dot:
			if enemy.has_method("take_damage"):
				enemy.take_damage(total_damage)  # ← Use total_damage instead of 10
				break
	
	# Check dummies (same change)
	var dummies = get_tree().get_nodes_in_group("dummies")
	for dummy in dummies:
		if not is_instance_valid(dummy):
			continue
		
		var distance = attack_origin.distance_to(dummy.global_position)
		if distance > attack_range:
			continue
		
		var dir_to_dummy = (dummy.global_position - global_position).normalized()
		var dot = dir_to_dummy.dot(attack_direction)
		
		if dot > min_dot:
			if dummy.has_method("take_damage"):
				dummy.take_damage(total_damage)  # ← Use total_damage

# HP System Functions
func take_damage(amount: int):
	if is_dead:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	update_hp_bar()
	
	# Stop regeneration and reset timer
	time_since_last_damage = 0.0
	is_regenerating = false
	
	print("Player took %d damage! HP: %d/%d" % [amount, current_health, max_health])
	flash_damage()
	
	if current_health <= 0:
		die()

func flash_damage():
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		animated_sprite.modulate = Color.WHITE

func heal(amount: int):
	current_health += amount
	current_health = min(max_health, current_health)
	update_hp_bar()
	
	print("Player healed %d HP! HP: %d/%d" % [amount, current_health, max_health])

func update_hp_bar():
	if hp_bar:
		hp_bar.value = current_health

func die():
	if is_dead:
		return
	
	print("Player died!")
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	is_regenerating = false
	time_since_last_damage = 0.0
	
	if death_screen:
		death_screen.show_death_screen()
	else:
		print("Error: Death screen not found!")
		await get_tree().create_timer(3.0).timeout
		respawn()

func respawn():
	print("Player respawning!")
	
	# Reset state
	is_dead = false
	current_health = max_health
	can_move = true
	velocity = Vector2.ZERO
	is_regenerating = false
	time_since_last_damage = 0.0
	
	# Reset position
	global_position = Global.spawn_position
	if Global.spawn_position == Vector2.ZERO:
		global_position = Vector2(200, 275)
	
	# Reset visuals
	animated_sprite.modulate = Color.WHITE
	update_hp_bar()
	
	# Play idle animation
	animated_sprite.play("idle_x")

func _on_respawn():
	respawn()

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
	if Global.has_active_quest and not Global.active_quest.is_empty():
		if quest_ui:
			quest_ui.show_quest(Global.active_quest)
			quest_ui.update_quest_progress(Global.quest_progress, Global.quest_target)
		print("Quest restored: ", Global.active_quest.get("title", "Unknown"))
	else:
		if quest_ui:
			quest_ui.hide()
		print("No active quest to restore")

func accept_quest(quest_data: Dictionary):
	if Global.has_active_quest:
		print("Already have an active quest!")
		return false
	
	Global.active_quest = quest_data
	Global.has_active_quest = true
	
	var target = extract_quest_target(quest_data.get("title", ""))
	Global.quest_target = target
	Global.quest_progress = 0
	
	if quest_ui:
		quest_ui.show_quest(quest_data)
	
	print("Quest accepted: ", quest_data.get("title", "Unknown"))
	return true

func extract_quest_target(title: String) -> int:
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
		
		if Global.quest_progress >= Global.quest_target:
			complete_quest()

func complete_quest():
	if Global.has_active_quest:
		var reward = Global.active_quest.get("reward", 0)
		print("Quest completed! Reward: %d Gold" % reward)
		
		if quest_ui:
			quest_ui.complete_quest()
		
		Global.has_active_quest = false
		Global.active_quest.clear()
		Global.quest_progress = 0
		Global.quest_target = 0
		
func update_exp_bar():
	if exp_bar:
		exp_bar.max_value = Global.player_exp_to_next_level
		exp_bar.value = Global.player_exp

# NEW: Gain experience
func gain_exp(amount: int):
	var old_level = Global.player_level
	Global.add_exp(amount)
	update_exp_bar()
	
	# Check if we leveled up
	if Global.player_level > old_level:
		print("=== LEVEL UP! ===")
		print("You are now level %d!" % Global.player_level)
		print("You have %d stat points to spend!" % Global.stat_points)
