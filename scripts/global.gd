extends Node

var spawn_position: Vector2 = Vector2.ZERO
var from_scene: String = ""
var player_rank: String = ""
var has_taken_test: bool = false

# Quest System
var active_quest: Dictionary = {}
var has_active_quest: bool = false
var quest_progress: int = 0
var quest_target: int = 0

# Experience and Leveling System
var player_level: int = 1
var player_exp: int = 0
var player_exp_to_next_level: int = 100
var stat_points: int = 0

# Player Stats
var player_strength: int = 0
var player_speed_bonus: int = 0
var player_health_bonus: int = 0
var player_current_health: int = 100

# NEW: Guild Reputation System
var guild_reputation: int = 0
var guild_reputation_to_next_rank: int = 100
var guild_rank: String = ""  # F, E, D, C, B, A, S

# Rank order for progression
var rank_order = ["F", "E", "D", "C", "B", "A", "S"]

# Experience calculation
func calculate_exp_needed(level: int) -> int:
	return int(100 * pow(level, 1.5))

# Level up function
func level_up():
	player_level += 1
	stat_points += 1
	player_exp = 0
	player_exp_to_next_level = calculate_exp_needed(player_level)
	
	print("LEVEL UP! Now level %d" % player_level)
	print("Stat points available: %d" % stat_points)

# Add experience
func add_exp(amount: int):
	player_exp += amount
	print("Gained %d EXP! (%d/%d)" % [amount, player_exp, player_exp_to_next_level])
	
	while player_exp >= player_exp_to_next_level:
		level_up()

# NEW: Guild Reputation Functions

# Calculate reputation needed for next rank
func calculate_reputation_needed(current_rank: String) -> int:
	var rank_index = rank_order.find(current_rank)
	if rank_index == -1:
		return 100  # Default for F rank
	
	# Formula: 100 * (rank_index + 1) * 1.5
	# F: 100, E: 150, D: 225, C: 338, B: 506, A: 759, S: maxed
	return int(100 * (rank_index + 1) * 1.5)

# Add guild reputation
func add_guild_reputation(amount: int):
	if guild_rank.is_empty():
		print("Cannot gain reputation - not a guild member yet!")
		return
	
	if guild_rank == "S":
		print("Already at max rank S!")
		return
	
	guild_reputation += amount
	print("Gained %d Guild Reputation! (%d/%d)" % [amount, guild_reputation, guild_reputation_to_next_rank])
	
	# Check for rank up
	while guild_reputation >= guild_reputation_to_next_rank:
		rank_up()

# Rank up to next guild rank
func rank_up():
	var current_index = rank_order.find(guild_rank)
	
	if current_index == -1 or current_index >= rank_order.size() - 1:
		print("Already at max rank!")
		guild_rank = "S"
		return
	
	# Reset reputation
	guild_reputation = 0
	
	# Move to next rank
	guild_rank = rank_order[current_index + 1]
	
	# Calculate new reputation needed
	if guild_rank != "S":
		guild_reputation_to_next_rank = calculate_reputation_needed(guild_rank)
	else:
		guild_reputation_to_next_rank = 0  # Max rank, no more progression
	
	print("=== RANK UP! ===")
	print("New Guild Rank: %s" % guild_rank)
	if guild_rank != "S":
		print("Reputation to next rank: %d" % guild_reputation_to_next_rank)

# Initialize guild rank when test is taken
func initialize_guild_rank():
	guild_rank = "F"
	guild_reputation = 0
	guild_reputation_to_next_rank = calculate_reputation_needed("F")
	print("Joined guild at rank F!")
