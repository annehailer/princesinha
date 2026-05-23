extends Node

signal lives_changed(current_lives: int, max_lives: int)

var coins := 0
var score := 0
var max_lives := 3
var lives := max_lives

var checkpoint_scene_path := ""
var checkpoint_position := Vector2.ZERO

const COINS_PER_EXTRA_LIFE := 100
const MAX_HEART_SLOTS := 30


func set_lives(value: int) -> void:
	lives = clamp(value, 0, MAX_HEART_SLOTS)
	lives_changed.emit(lives, max_lives)


func lose_life() -> void:
	set_lives(lives - 1)


func reset_lives() -> void:
	set_lives(max_lives)


func set_checkpoint(scene_path: String, position: Vector2) -> void:
	checkpoint_scene_path = scene_path
	checkpoint_position = position


func has_checkpoint(scene_path: String) -> bool:
	return checkpoint_scene_path == scene_path and checkpoint_scene_path != ""

func add_coins(amount: int) -> void:
	coins += amount
	while coins >= COINS_PER_EXTRA_LIFE:
		coins -= COINS_PER_EXTRA_LIFE
		set_lives(lives + 1)
