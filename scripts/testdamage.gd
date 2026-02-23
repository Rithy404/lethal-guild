extends Area2D

@export var damage_amount: int = 30
@export var damage_interval: float = 1.0  # Damage every 1 second

var player_inside = false
var player_ref = null
var damage_timer: Timer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create damage timer
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		print("Player entered damage zone!")
		
		# Deal immediate damage
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
		
		# Start continuous damage
		damage_timer.start()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		damage_timer.stop()
		print("Player left damage zone")

func _on_damage_timer_timeout() -> void:
	if player_inside and player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage_amount)
		print("Damage zone dealt %d damage!" % damage_amount)
