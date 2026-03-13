extends Node

var spawn_position: Vector2 = Vector2.ZERO
var from_scene: String = ""
var player_rank: String = ""
var has_taken_test: bool = true
# Quest System - Add these
var active_quest: Dictionary = {}
var has_active_quest: bool = false
var quest_progress: int = 0
var quest_target: int = 0

# NEW: Experience and Leveling System
var player_level: int = 1
var player_exp: int = 0
var player_exp_to_next_level: int = 100  # Experience needed for level 2
var stat_points: int = 0  # Points to spend on stats
var player_current_health: int = 100
# Player Stats
var player_strength: int = 0  # Affects damage
var player_speed_bonus: int = 0  # Added to base speed
var player_health_bonus: int = 0  # Added to base health

# Experience calculation
func calculate_exp_needed(level: int) -> int:
	# Formula: 100 * level^1.5 (gets harder each level)
	return int(100 * pow(level, 1.2))

# Level up function
func level_up():
	player_level += 1
	stat_points += 1  # Give 1 stat point per level
	player_exp = 0  # Reset experience
	player_exp_to_next_level = calculate_exp_needed(player_level)
	
	print("LEVEL UP! Now level %d" % player_level)
	print("Stat points available: %d" % stat_points)

# Add experience
func add_exp(amount: int):
	player_exp += amount
	print("Gained %d EXP! (%d/%d)" % [amount, player_exp, player_exp_to_next_level])
	
	# Check for level up
	while player_exp >= player_exp_to_next_level:
		level_up()
