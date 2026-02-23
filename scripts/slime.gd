extends CharacterBody2D

# Movement
@export var chase_speed: float = 20.0

# Detection ranges
@export var detection_range: float = 50.0  # Start chasing
@export var stop_chase_range: float = 150.0  # Stop chasing (must be > detection_range)
@export var attack_range: float = 5.0  # Distance to attack (NOT Area2D based)

# Combat
@export var max_health: int = 50
@export var damage: int = 8
@export var attack_cooldown: float = 1  # Seconds between attacks

var current_health: int = 50
var player_ref = null
var spawn_position: Vector2
var is_dead: bool = false
var can_attack: bool = true

# Components
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# State
enum State { IDLE, CHASE, RETURN }
var current_state = State.IDLE

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	current_health = max_health
	
	animated_sprite.play("idle_front")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Find player if we don't have reference
	if not player_ref:
		find_player()
	
	# Main AI logic
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		match current_state:
			State.IDLE:
				velocity = Vector2.ZERO
				# Start chasing if player is close
				if distance_to_player < detection_range:
					current_state = State.CHASE
					print("Slime: Starting chase!")
			
			State.CHASE:
				# Player escaped too far
				if distance_to_player > stop_chase_range:
					print("Slime: Player escaped, returning to spawn")
					current_state = State.RETURN
					player_ref = null
					return
				
				# Check if in attack range
				if distance_to_player <= attack_range:
					# Stop moving and attack
					velocity = Vector2.ZERO
					if can_attack:
						attack_player()
				else:
					# Chase player
					var direction = (player_ref.global_position - global_position).normalized()
					velocity = direction * chase_speed
			
			State.RETURN:
				velocity = Vector2.ZERO
				player_ref = null
				return_to_spawn()
	else:
		# No player, stay idle or return
		if current_state != State.IDLE:
			current_state = State.RETURN
			return_to_spawn()
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
	update_animation()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func attack_player():
	if not player_ref or not player_ref.has_method("take_damage"):
		return
	
	can_attack = false
	
	# Deal damage
	player_ref.take_damage(damage)
	print("Slime attacked for %d damage!" % damage)
	
	# Visual feedback (flash or play attack anim)
	flash_attack()
	
	# Start cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func flash_attack():
	# Quick flash to show attack
	animated_sprite.modulate = Color.YELLOW
	await get_tree().create_timer(0.15).timeout
	if not is_dead:
		animated_sprite.modulate = Color.WHITE

func return_to_spawn():
	var distance_to_spawn = global_position.distance_to(spawn_position)
	
	# Reached spawn
	if distance_to_spawn < 10.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		current_state = State.IDLE
		regenerate_health()
		print("Slime: Returned to spawn")
		return
	
	# Move towards spawn
	var direction = (spawn_position - global_position).normalized()
	velocity = direction * chase_speed

func regenerate_health():
	current_health = max_health
	print("Slime regenerated to full health!")

func update_animation():
	if velocity.length() == 0:
		# Idle
		if player_ref and current_state == State.CHASE:
			var dir_to_player = player_ref.global_position - global_position
			play_idle_animation(dir_to_player)
		else:
			animated_sprite.play("idle_front")
	else:
		# Moving
		play_move_animation(velocity)

func play_idle_animation(direction: Vector2):
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			animated_sprite.play("idle_front")
		else:
			animated_sprite.play("idle_back")
	else:
		animated_sprite.play("idle_right")
		animated_sprite.flip_h = direction.x < 0

func play_move_animation(direction: Vector2):
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			animated_sprite.play("move_front")
		else:
			animated_sprite.play("move_back")
	else:
		animated_sprite.play("move_right")
		animated_sprite.flip_h = direction.x < 0

func take_damage(amount: int):
	if is_dead:
		return
	
	current_health -= amount
	print("Slime took %d damage! Health: %d/%d" % [amount, current_health, max_health])
	
	# Start chasing the player who hit us
	if not player_ref:
		find_player()
	if player_ref:
		current_state = State.CHASE
	
	flash_damage()
	
	if current_health <= 0:
		die()

func flash_damage():
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		animated_sprite.modulate = Color.WHITE

func die():
	is_dead = true
	velocity = Vector2.ZERO
	current_state = State.IDLE
	print("Slime defeated!")
	
	# Update quest progress
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("update_quest_progress"):
			if Global.has_active_quest:
				var quest_title = Global.active_quest.get("title", "")
				if "Slime" in quest_title:
					player.update_quest_progress(1)
	
	# Play death animation
	animated_sprite.play("die")
	
	# Wait for death animation to finish
	await animated_sprite.animation_finished
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Hide instead of removing
	hide()
	
	# Wait before respawn
	await get_tree().create_timer(10.0).timeout
	respawn()

func respawn():
	print("Slime respawning!")
	
	# Reset state
	is_dead = false
	current_health = max_health
	current_state = State.IDLE
	global_position = spawn_position
	velocity = Vector2.ZERO
	player_ref = null
	can_attack = true
	
	# Reset visuals
	animated_sprite.modulate = Color.WHITE
	animated_sprite.modulate.a = 1.0
	show()
	
	animated_sprite.play("idle_front")

func can_be_hit_by_player(player_position: Vector2, player_facing: Vector2) -> bool:
	if is_dead:
		return false
	
	var dir_to_slime = (global_position - player_position).normalized()
	var dot = dir_to_slime.dot(player_facing)
	
	return dot > 0.5
