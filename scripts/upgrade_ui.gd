extends TextureRect

# UI References
@onready var close_button: TextureButton = $CloseButton
@onready var current_level_label: Label = $CurrentLevel
@onready var stat_points_label: Label = $Statspoint

@onready var strength_label: Label = $Strength
@onready var health_label: Label = $Health
@onready var speed_label: Label = $Speed

@onready var upgrade_strength_button: TextureButton = $UpgradeStrength
@onready var upgrade_health_button: TextureButton = $UpgradeHealth
@onready var upgrade_speed_button: TextureButton = $UpgradeSpeed
@onready var upgrade: TextureButton = $"../Upgrade"

# NEW: Guild UI elements
@onready var guild_rank_label: Label = $GuildRank
@onready var guild_reputation_label: Label = $GuildReputation
@onready var reputation_bar: TextureProgressBar = $Reputation

var player_ref = null

func _ready() -> void:
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if upgrade_strength_button:
		upgrade_strength_button.pressed.connect(_on_upgrade_strength)
	
	if upgrade_health_button:
		upgrade_health_button.pressed.connect(_on_upgrade_health)
	
	if upgrade_speed_button:
		upgrade_speed_button.pressed.connect(_on_upgrade_speed)
	
	if upgrade:
		upgrade.pressed.connect(_on_upgrade_pressed)
	
	# Hide by default
	hide()

func open_upgrade_ui():
	# Find player
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	# Update all displays
	update_all_stats()
	
	# Show UI and pause player
	show()
	if player_ref:
		player_ref.can_move = false

func close_upgrade_ui():
	hide()
	if player_ref:
		player_ref.can_move = true

func update_all_stats():
	# Update level and points
	if current_level_label:
		current_level_label.text = "Level: " + str(Global.player_level)
	
	if stat_points_label:
		stat_points_label.text = "Points: " + str(Global.stat_points)
	
	# Update stat values
	if strength_label:
		strength_label.text = "Strenght: " + str(Global.player_strength)
	
	if health_label:
		health_label.text = "Health: " + str(Global.player_health_bonus)
	
	if speed_label:
		speed_label.text = "Speed: " + str(Global.player_speed_bonus)
	
	# NEW: Update guild reputation
	update_guild_display()
	
	# Enable/disable buttons based on available points
	var has_points = Global.stat_points > 0
	
	if upgrade_strength_button:
		upgrade_strength_button.disabled = not has_points
	
	if upgrade_health_button:
		upgrade_health_button.disabled = not has_points
	
	if upgrade_speed_button:
		upgrade_speed_button.disabled = not has_points

# NEW: Update guild rank and reputation display
func update_guild_display():
	# Only show if player has taken test
	if Global.has_taken_test and not Global.guild_rank.is_empty():
		# Show guild UI elements
		if guild_rank_label:
			guild_rank_label.text = "Rank: " + Global.guild_rank
			guild_rank_label.show()
		
		if guild_reputation_label:
			if Global.guild_rank == "S":
				guild_reputation_label.text = "Build Reputation: MAX"
			else:
				guild_reputation_label.text = "Build Reputation"
			guild_reputation_label.show()
		
		if reputation_bar:
			if Global.guild_rank == "S":
				# Max rank - show full bar
				reputation_bar.max_value = 100
				reputation_bar.value = 100
			else:
				reputation_bar.max_value = Global.guild_reputation_to_next_rank
				reputation_bar.value = Global.guild_reputation
			reputation_bar.show()
	else:
		# Hide guild UI elements
		if guild_rank_label:
			guild_rank_label.hide()
		
		if guild_reputation_label:
			guild_reputation_label.hide()
		
		if reputation_bar:
			reputation_bar.hide()

# Button Handlers
func _on_close_pressed():
	close_upgrade_ui()

func _on_upgrade_pressed():
	if visible:
		close_upgrade_ui()
	else:
		open_upgrade_ui()

func _on_upgrade_strength():
	if Global.stat_points <= 0:
		return
	
	Global.player_strength += 1
	Global.stat_points -= 1
	
	update_all_stats()

func _on_upgrade_health():
	if Global.stat_points <= 0:
		return
	
	# Calculate old max for proportion
	var old_max = 100 + ((Global.player_health_bonus) * 10)
	
	# Upgrade
	Global.player_health_bonus += 1
	Global.stat_points -= 1
	
	# Calculate new max
	var new_max = 100 + (Global.player_health_bonus * 10)
	
	# Update player's max health immediately
	if player_ref and player_ref.has_method("apply_stat_bonuses"):
		player_ref.apply_stat_bonuses()
		
		# Heal proportionally (give the +10 HP)
		var hp_gain = new_max - old_max
		player_ref.current_health += hp_gain
		player_ref.current_health = min(player_ref.current_health, new_max)
		Global.player_current_health = player_ref.current_health
		player_ref.update_hp_bar()
	
	update_all_stats()

func _on_upgrade_speed():
	if Global.stat_points <= 0:
		return
	
	Global.player_speed_bonus += 1
	Global.stat_points -= 1
	
	update_all_stats()
