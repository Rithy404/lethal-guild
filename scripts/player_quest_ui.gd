extends TextureRect

@onready var quest_label_1: Label = $Label
@onready var quest_label_2: Label = $Label2

func _ready() -> void:
	# IMPORTANT: Let clicks pass through Quest UI to reach the button
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	

func show_quest(quest_data: Dictionary):
	if quest_label_1:
		quest_label_1.text = "Current Quest"
	
	if quest_label_2:
		var quest_text = quest_data.get("title", "Unknown Quest")
		quest_label_2.text = quest_text
	
	show()
	
	print("Quest displayed on UI!")

func hide_quest():
	hide()

func update_quest_progress(current: int, target: int):
	if quest_label_2:
		var title = Global.active_quest.get("title", "Quest")
		quest_label_2.text = title + " " + str(current) + "/" + str(target)

func complete_quest():
	print("Quest completed!")
	
	if quest_label_1:
		quest_label_1.text = "Quest Complete!"
	
	await get_tree().create_timer(2.0).timeout
	hide_quest()
