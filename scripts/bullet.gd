extends CharacterBody2D
class_name PlayerBullet
var speed: float = 120
var damage: float = 10
var moving_right: bool = true



func _physics_process(delta: float) -> void:
	var direction: int
	if moving_right: direction = 1
	else: direction = -1
	velocity = Vector2((speed * 100) * direction, 0) * delta
	move_and_slide()

func _on_self_destruct_timer_timeout() -> void:
	queue_free()

func _on_area_2d_area_entered(_area: Area2D) -> void:
	queue_free()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	queue_free()
