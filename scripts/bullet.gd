extends CharacterBody2D
class_name PlayerBullet
var speed: float = 120
var damage: float = 10
var moving_right: bool = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var direction: int
	if moving_right: direction = 1
	else: direction = -1
	velocity = Vector2((speed * 100) * direction, 0) * delta
	move_and_slide()
