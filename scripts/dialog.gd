extends CanvasLayer


@onready var name_label: Label = $MarginContainer/Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var dialog_label: Label = $MarginContainer/Panel/HBoxContainer/VBoxContainer2/DialogLabel
@onready var portrait: TextureRect = $MarginContainer/Panel/HBoxContainer/VBoxContainer/TextureRect
@onready var no_button: Button = $MarginContainer/Panel/HBoxContainer/VBoxContainer2/ChoiceContainer/NoButton
@onready var yes_button: Button = $MarginContainer/Panel/HBoxContainer/VBoxContainer2/ChoiceContainer/YesButton
@onready var choice_container: HBoxContainer = $MarginContainer/Panel/HBoxContainer/VBoxContainer2/ChoiceContainer

var dialog_lines := []
var current_line := 0
var is_talking := false
var is_typing := false
var is_waiting_for_choice := false
var full_text := ""
var typing_speed := 0.05
var player_choice := false
var input_cooldown := false  # Add cooldown flag

signal dialog_finished
signal choice_made(choice: bool)

func _ready() -> void:
	hide()
	choice_container.hide()
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

func start_dialog(lines: Array, speaker_name: String, speaker_portrait: Texture2D = null) -> void:
	dialog_lines = lines.duplicate()
	current_line = 0
	is_talking = true
	name_label.text = speaker_name
	if speaker_portrait:
		portrait.texture = speaker_portrait
	show()
	display_line()

func display_line() -> void:
	if current_line >= dialog_lines.size():
		end_dialog()
		return
	
	full_text = dialog_lines[current_line]
	
	# Check if this line is a choice
	if full_text.begins_with("[CHOICE]"):
		var question = full_text.replace("[CHOICE]", "")
		show_choice(question)
		return
	
	# Check if this line has conditional text
	if full_text.begins_with("[YES]") or full_text.begins_with("[NO]"):
		if full_text.begins_with("[YES]") and player_choice:
			full_text = full_text.replace("[YES]", "")
		elif full_text.begins_with("[NO]") and not player_choice:
			full_text = full_text.replace("[NO]", "")
		else:
			current_line += 1
			display_line()
			return
	
	dialog_label.text = ""
	is_typing = true
	_type_text()

func _type_text() -> void:
	for i in full_text.length():
		if not is_typing:
			dialog_label.text = full_text
			return
		dialog_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false

func _input(event: InputEvent) -> void:
	if not is_talking or input_cooldown:  # Check cooldown
		return
	
	# Handle choice input
	if is_waiting_for_choice:
		if event.is_action_pressed("ui_left"):
			yes_button.grab_focus()
		elif event.is_action_pressed("ui_right"):
			no_button.grab_focus()
		elif event.is_action_pressed("ui_accept"):
			if yes_button.has_focus():
				_on_yes_pressed()
			elif no_button.has_focus():
				_on_no_pressed()
		return
	
	# Handle normal dialog input
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			is_typing = false
		else:
			next_line()

func next_line() -> void:
	current_line += 1
	display_line()

func show_choice(question: String) -> void:
	dialog_label.text = question
	# Add a small delay before showing choice buttons
	await get_tree().create_timer(0.1).timeout
	choice_container.show()
	is_waiting_for_choice = true
	yes_button.grab_focus()

func _on_yes_pressed() -> void:
	player_choice = true
	choice_container.hide()
	is_waiting_for_choice = false
	emit_signal("choice_made", true)
	
	# Add input cooldown to prevent immediate advance
	input_cooldown = true
	await get_tree().create_timer(0.2).timeout
	input_cooldown = false
	
	current_line += 1
	display_line()

func _on_no_pressed() -> void:
	player_choice = false
	choice_container.hide()
	is_waiting_for_choice = false
	emit_signal("choice_made", false)
	
	# Add input cooldown to prevent immediate advance
	input_cooldown = true
	await get_tree().create_timer(0.2).timeout
	input_cooldown = false
	
	current_line += 1
	display_line()

func end_dialog() -> void:
	is_talking = false
	current_line = 0
	choice_container.hide()
	is_waiting_for_choice = false
	input_cooldown = false
	hide()
	emit_signal("dialog_finished")
