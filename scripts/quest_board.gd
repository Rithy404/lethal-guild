extends CanvasLayer

@onready var close_button: TextureButton = $CloseButton
@onready var quest: TextureRect = $Quest
@onready var quest_2: TextureRect = $Quest2
@onready var quest_3: TextureRect = $Quest3

var quest_nodes = []
var quest_data_array = []  # Store quest data


func _ready() -> void:
	# Collect all quest nodes
	quest_nodes = [quest, quest_2, quest_3]
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("Close button connected!")
	else:
		print("ERROR: Close button not found!")
	
	# Hide by default
	hide()
	
	# Connect quest AcceptButtons
	for i in range(quest_nodes.size()):
		var quest = quest_nodes[i]
		if quest:
			var accept_button = quest.get_node_or_null("AcceptButton")
			if accept_button:
				accept_button.pressed.connect(_on_quest_accepted.bind(i))
				print("Quest %d AcceptButton connected!" % (i + 1))
			else:
				print("Warning: Quest %d has no AcceptButton" % (i + 1))

func show_quest_board():
	show()
	print("Quest board opened")
	# Pause player movement
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false

func _on_close_button_pressed():
	print("Close button pressed!")
	hide()
	# Resume player movement
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	print("Quest board closed")

func _on_quest_accepted(quest_index: int):
	print("\n=== QUEST ACCEPTED ===")
	
	# Make sure we have quest data for this index
	if quest_index >= quest_data_array.size():
		print("Error: No quest data for index %d" % quest_index)
		return
	
	var data = quest_data_array[quest_index]
	
	# Print quest details
	print("Quest Title: ", data.get("title", "Unknown"))
	print("Description: ", data.get("description", "No description available"))
	print("Difficulty: ", data.get("difficulty", "?"))
	print("Reward: ", data.get("reward", 0), " XP")
	print("Objective: ", data.get("objective", "Unknown"))
	print("======================\n")
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("accept_quest"):
		var accepted = player.accept_quest(data)
		if accepted:
			# Close quest board after accepting
			_on_close_button_pressed()
		else:
			print("Player already has an active quest!")
			# You could show an error message here
			
func populate_quests(quest_data: Array):
	# Store quest data for later use
	quest_data_array = quest_data
	
	# Populate the quest board with quest data
	for i in range(min(quest_data.size(), quest_nodes.size())):
		var quest = quest_nodes[i]
		var data = quest_data[i]
		
		if quest:
			# Get the labels
			var title_label = quest.get_node_or_null("VBoxContainer/QuestLabel")
			var difficulty_label = quest.get_node_or_null("VBoxContainer/QuestDifficulty")
			var reward_label = quest.get_node_or_null("VBoxContainer/QuestReward")
			
			# Set the text
			if title_label:
				title_label.text = data.get("title", "Unknown Quest")
			if difficulty_label:
				difficulty_label.text = "Rank: " + data.get("difficulty", "?")
			if reward_label:
				reward_label.text = str(data.get("reward", 0)) + " XP"
			
			quest.show()
	
	# Hide unused quest slots
	for i in range(quest_data.size(), quest_nodes.size()):
		if quest_nodes[i]:
			quest_nodes[i].hide()
