extends Area2D

@export var spawn_offset := Vector2.ZERO

var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if body is not Player:
		return

	activated = true
	var scene_path := get_tree().current_scene.scene_file_path
	Globals.set_checkpoint(scene_path, global_position + spawn_offset)
