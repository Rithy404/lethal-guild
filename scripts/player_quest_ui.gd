extends TextureRect

@onready var quest_label_1: Label = $Label  # "Current Quest" title
@onready var quest_label_2: Label = $Label2  # Quest description/objective

func _ready() -> void:
	# Start hidden
	hide()

func show_quest(quest_data: Dictionary):
	# Update the labels
	if quest_label_1:
		quest_label_1.text = "Current Quest"
	
	if quest_label_2:
		var quest_text = quest_data.get("title", "Unknown Quest")
		# Don't show progress yet, will be updated by update_quest_progress
		quest_label_2.text = quest_text
	
	show()
	print("Quest displayed on UI!")

func hide_quest():
	hide()

func update_quest_progress(current: int, target: int):
	if quest_label_2:
		# Get the base title from Global if possible
		var title = Global.active_quest.get("title", "Quest")
		quest_label_2.text = title + " " + str(current) + "/" + str(target)

func complete_quest():
	print("Quest completed!")
	# Show completion message
	if quest_label_1:
		quest_label_1.text = "Quest Complete!"
	
	# Wait then hide
	await get_tree().create_timer(2.0).timeout
	hide_quest()
