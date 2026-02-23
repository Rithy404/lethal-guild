extends CanvasLayer

@onready var panel: ColorRect = $Panel
@onready var wasted_label: Label = $Panel/WastedLabel
@onready var countdown_label: Label = $Panel/CountdownLabel

signal respawn_player

func _ready() -> void:
	hide()

	# Fullscreen panel
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Countdown label at center
	countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# WASTED label ABOVE the countdown (centered)
	wasted_label.set_anchors_preset(Control.PRESET_CENTER)
	wasted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wasted_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func show_death_screen():
	show()

	# Fade in black
	panel.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(panel, "modulate:a", 1.0, 1.0)
	await fade_tween.finished

	# Show WASTED
	wasted_label.modulate.a = 1.0
	wasted_label.text = "WASTED"

	await get_tree().create_timer(1.0).timeout

	# Countdown
	await countdown_from_5()

	emit_signal("respawn_player")

	# Fade out panel
	var fadeout_tween = create_tween()
	fadeout_tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await fadeout_tween.finished

	hide()


func countdown_from_5():
	for i in range(5, 0, -1):
		countdown_label.text = str(i)
		countdown_label.modulate.a = 1.0
		await get_tree().create_timer(1.0).timeout
