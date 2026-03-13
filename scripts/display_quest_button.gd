extends TextureButton

@onready var quest_ui: TextureRect = $"../Quest"

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if Global.has_active_quest:
		quest_ui.visible = !quest_ui.visible
