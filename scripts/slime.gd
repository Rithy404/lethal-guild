extends CharacterBody2D

# Movement
@export var chase_speed: float = 20.0

# Combat
@export var max_health: int = 50
@export var damage: int = 8
@export var attack_cooldown: float = 1.0

var current_health: int = 50
var player_ref = null
var spawn_position: Vector2
var is_dead: bool = false
var can_attack: bool = true
var return_timer: float = 0.0
# Detection flags
var player_in_detection_range: bool = false
var player_in_attack_range: bool = false

@onready var healthbar: TextureProgressBar = $Healthbar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

enum State { IDLE, CHASE, ATTACK, RETURN }
var current_state = State.IDLE

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	current_health = max_health
	
	# Initialize health bar
	if healthbar:
		healthbar.max_value = max_health
		healthbar.value = current_health
		healthbar.show()
	
	# Setup detection area (chase range)
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)
	
	# Setup attack area (attack range)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_range_entered)
		attack_area.body_exited.connect(_on_attack_range_exited)
	
	# Collision exception with player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		add_collision_exception_with(players[0])
	
	animated_sprite.play("idle_front")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	match current_state:
		State.IDLE:
			process_idle()
		State.CHASE:
			process_chase()
		State.ATTACK:
			process_attack()
		State.RETURN:
			process_return()
	
	move_and_slide()
	update_animation()

func process_idle():
	velocity = Vector2.ZERO
	
	if player_in_detection_range and player_ref:
		current_state = State.CHASE

func process_chase():
	if not player_ref:
		current_state = State.RETURN
		return
	
	if not player_in_detection_range:
		current_state = State.RETURN
		player_ref = null
		return
	
	if player_in_attack_range:
		current_state = State.ATTACK
		return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * chase_speed

func process_attack():
	velocity = Vector2.ZERO
	
	if not player_ref:
		current_state = State.RETURN
		return
	
	if not player_in_attack_range:
		current_state = State.CHASE
		return
	
	if can_attack:
		attack_player()

func process_return():
	# Check if player came back into detection range
	if player_in_detection_range and player_ref:
		print("Slime: Player re-detected - resuming chase!")
		current_state = State.CHASE
		return_timer = 0.0
		return
	
	var distance_to_spawn = global_position.distance_to(spawn_position)
	
	# Reached spawn point
	if distance_to_spawn < 10.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		current_state = State.IDLE
		regenerate_health()
		return_timer = 0.0
		
		# Check if player is nearby after reaching spawn
		await get_tree().process_frame
		check_player_in_areas()
		return
	
	# Timeout teleport - if returning takes too long
	return_timer += get_process_delta_time()
	if return_timer >= 5.0:
		print("Slime teleporting to spawn (timeout)")
		global_position = spawn_position
		velocity = Vector2.ZERO
		current_state = State.IDLE
		regenerate_health()
		return_timer = 0.0
		
		# Check if player is nearby after teleporting
		await get_tree().process_frame
		check_player_in_areas()
		return
	
	# Move toward spawn
	var direction = (spawn_position - global_position).normalized()
	velocity = direction * chase_speed

func attack_player():
	if not player_ref or not player_ref.has_method("take_damage"):
		return
	
	can_attack = false
	player_ref.take_damage(damage)
	
	flash_attack()
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func flash_attack():
	animated_sprite.modulate = Color.YELLOW
	await get_tree().create_timer(0.15).timeout
	if not is_dead:
		animated_sprite.modulate = Color.WHITE

func regenerate_health():
	current_health = max_health
	update_healthbar()

func update_animation():
	if velocity.length() == 0:
		if player_ref and current_state == State.CHASE:
			var dir_to_player = player_ref.global_position - global_position
			play_idle_animation(dir_to_player)
		else:
			animated_sprite.play("idle_front")
	else:
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
	update_healthbar()
	
	flash_damage()
	
	if current_health <= 0:
		die()

func update_healthbar():
	if healthbar:
		healthbar.value = current_health

func flash_damage():
	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		animated_sprite.modulate = Color.WHITE

func die():
	is_dead = true
	velocity = Vector2.ZERO
	current_state = State.IDLE
	
	# Hide health bar when dead
	if healthbar:
		healthbar.hide()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		
		# Give EXP to player
		if player.has_method("gain_exp"):
			var exp_reward = 25
			player.gain_exp(exp_reward)
		
		# Update quest progress
		if player.has_method("update_quest_progress"):
			if Global.has_active_quest:
				var quest_title = Global.active_quest.get("title", "")
				if "Slime" in quest_title:
					player.update_quest_progress(1)
	
	animated_sprite.play("die")
	await animated_sprite.animation_finished
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	hide()
	await get_tree().create_timer(10.0).timeout
	respawn()

func respawn():
	# Reset state
	is_dead = false
	current_health = max_health
	current_state = State.IDLE
	global_position = spawn_position
	velocity = Vector2.ZERO
	player_ref = null
	can_attack = true
	player_in_detection_range = false
	player_in_attack_range = false
	
	# Reset visuals
	animated_sprite.modulate = Color.WHITE
	animated_sprite.modulate.a = 1.0
	show()
	
	# Show and reset health bar
	if healthbar:
		healthbar.value = max_health
		healthbar.show()
	
	animated_sprite.play("idle_front")
	
	# NEW: Check if player is already in range
	await get_tree().process_frame
	check_player_in_areas()

# NEW: Check for overlapping bodies on respawn
func check_player_in_areas():
	# Check detection area
	if detection_area:
		var bodies = detection_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				player_in_detection_range = true
				player_ref = body
				print("Player detected on respawn - starting chase!")
				break
	
	# Check attack area
	if attack_area:
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				player_in_attack_range = true
				break

# === AREA2D SIGNAL HANDLERS ===

func _on_detection_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_detection_range = true
		player_ref = body

func _on_detection_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_detection_range = false

func _on_attack_range_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_attack_range = true

func _on_attack_range_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_attack_range = false
