extends Area2D

@export var next_level: String = ""

func _on_body_entered(_body: Node2D) -> void:
	call_deferred("load_next_scene")

func load_next_scene():
	if next_level.is_empty():
		push_warning("Next level is empty.")
		print("Next level is empty. (ERROR)")
		return

	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
