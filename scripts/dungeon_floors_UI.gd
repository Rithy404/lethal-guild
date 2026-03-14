extends CanvasLayer

# Floor buttons
@onready var floor1_button: TextureButton = $TextureRect/Floor1
@onready var floor2_button: TextureButton = $TextureRect/Floor2
@onready var floor3_button: TextureButton = $TextureRect/Floor3
@onready var floor4_button: TextureButton = $TextureRect/Floor4
@onready var floor5_button: TextureButton = $TextureRect/Floor5
@onready var close_button: TextureButton = $TextureRect/CloseButton

# Callbacks
var on_floor_selected: Callable

# Player reference
var player_ref = null

func _ready() -> void:
	# Connect buttons
	if floor1_button:
		floor1_button.pressed.connect(_on_floor1_pressed)
	
	if floor2_button:
		floor2_button.pressed.connect(_on_floor2_pressed)
		floor2_button.disabled = true
		floor2_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray tint
	
	if floor3_button:
		floor3_button.pressed.connect(_on_floor3_pressed)
		floor3_button.disabled = true
		floor3_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	if floor4_button:
		floor4_button.pressed.connect(_on_floor4_pressed)
		floor4_button.disabled = true
		floor4_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	if floor5_button:
		floor5_button.pressed.connect(_on_floor5_pressed)
		floor5_button.disabled = true
		floor5_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Hide by default
	hide()
	
	print("Dungeon Floors UI ready!")

func show_floor_selection():
	# Find player
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	# Show UI and pause player
	show()
	if player_ref:
		player_ref.can_move = false
	
	print("Floor selection opened!")

func close_floor_selection():
	hide()
	if player_ref:
		player_ref.can_move = true
	
	print("Floor selection closed!")

# Button Handlers
func _on_floor1_pressed():
	print("Floor 1 selected!")
	close_floor_selection()
	
	# Trigger the floor change callback
	if on_floor_selected.is_valid():
		on_floor_selected.call(1)

func _on_floor2_pressed():
	print("Floor 2 selected! (Coming soon)")
	# Will be implemented later

func _on_floor3_pressed():
	print("Floor 3 selected! (Coming soon)")
	# Will be implemented later

func _on_floor4_pressed():
	print("Floor 4 selected! (Coming soon)")
	# Will be implemented later

func _on_floor5_pressed():
	print("Floor 5 selected! (Coming soon)")
	# Will be implemented later

func _on_close_pressed():
	close_floor_selection()
