extends Area2D


var coin_value := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass


func _on_anim_finished() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if !area.is_in_group("PlayerBody"): return
	sprite.play("collect")
	# evita colisão dupla de moedas
	await $CollisionShape2D.call_deferred("queue_free")
	Globals.coins += coin_value
	Globals.score += 100
	print (Globals.coins)
