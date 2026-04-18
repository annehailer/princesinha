extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var speed = 60
var direction = 1



func _process(delta: float) -> void:
	position.x += speed * delta * direction

func set_direction(skeleton_direction):
	direction = skeleton_direction
	sprite.flip_h = direction < 0
		# faz a mesma coisa doq a linha de cima (15)
	#if direction > 0:
		#sprite.flip_h = false
	#else:
		#sprite.flip_h = true

func _on_self_destruct_timer_timeout() -> void:
	queue_free()
