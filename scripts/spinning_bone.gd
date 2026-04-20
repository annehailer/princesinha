extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var speed = 160
var direction = 1



func _process(delta: float) -> void:
	position.x += speed * delta * direction


func set_direction(skeleton_direction):
	direction = skeleton_direction
	sprite.flip_h = direction < 0


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerBullet"):
		area.queue_free()
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
