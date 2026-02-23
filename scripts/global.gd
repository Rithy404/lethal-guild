extends Node

var spawn_position: Vector2 = Vector2.ZERO
var from_scene: String = ""
var player_rank: String = ""
var has_taken_test: bool = false
# Quest System - Add these
var active_quest: Dictionary = {}
var has_active_quest: bool = false
var quest_progress: int = 0
var quest_target: int = 0
