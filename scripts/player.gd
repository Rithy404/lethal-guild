extends CharacterBody2D

const SPEED = 100.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_dir = Vector2.ZERO   # stores the last direction faced
var is_attacking = false

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	global_position = Global.spawn_position
	if Global.spawn_position == Vector2.ZERO:
		global_position = Vector2(200, 275)  # Fallback spawn


func _physics_process(delta: float) -> void:
	if is_attacking:
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
