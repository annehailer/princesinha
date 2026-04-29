extends StaticBody2D

@onready var area_2d: Area2D = $Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var broken_timer: Timer = $BrokenTimer
@onready var reset_timer: Timer = $ResetTimer


var start_position
var is_broken = false

func _ready() -> void:
	start_position = global_position


func _process(delta: float) -> void:
	if is_broken:
		return
	var bodies = area_2d.get_overlapping_bodies()
	for body in bodies:
		var player: CharacterBody2D = body
		if player.is_on_floor():
			is_broken = true
			sprite.play("broken")
			broken_timer.start()


func _on_broken_timer_timeout() -> void:
	reset_timer.start()
	sprite.play("falling")
	set_collision_layer_value(1, false) # desativa
	var pixels = 40 #pixeis pra baixo
	var final_position = global_position + Vector2.DOWN * pixels
	var fall_tween = create_tween()
	fall_tween.set_trans(Tween.TRANS_QUAD)
	fall_tween.set_ease(Tween.EASE_IN)
	fall_tween.tween_property(self, "global_position", final_position, 0.5)
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(sprite, "modulate:a", 0, 0.5)
	
	
	
func _on_reset_timer_timeout() -> void:
	is_broken = false
	sprite.play("default")
	set_collision_layer_value(1, true) # reativa
	global_position = start_position
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(sprite, "modulate:a", 1, 0.5)
