extends Area2D
class_name PlayerBullet
var speed: float = 120
var damage: float = 10
var moving_right: bool = true



func _physics_process(delta: float) -> void:
	var direction := 1 if moving_right else -1
	position.x += speed * direction * delta

func _on_self_destruct_timer_timeout() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyBullet"):
		area.queue_free()
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
