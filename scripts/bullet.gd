extends CharacterBody2D
class_name PlayerBullet

var speed: float = 90
var moving_right: bool = true
var max_fall_speed: float = 200
var gravity: float = 5
var kick_force: float = 18


func _physics_process(delta: float) -> void:
	var dir_x := 1 if moving_right else -1
	
	velocity.x = dir_x * (speed * 100) * delta
	velocity.y += (gravity * 100) * delta
	
	velocity.y = min(velocity.y, max_fall_speed)
	
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
		if body is TileMapLayer:
			kick()


#func _on_area_2d_area_entered(area: Area2D) -> void:
#	if area.is_in_group("SkeletonBody"):
#		var skeleton: Skeleton = area.get_parent()
#		skeleton.take_damage()
#		ScreenShake.do_screen_shake(2, 0.5)
#		queue_free()


func _on_check_walls_area_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		queue_free()


func kick():
	do_pump()
	velocity.y = -kick_force * 10



func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("af sumi :c")
	queue_free()



#------------- Pump Anim -------------

var pump_tween: Tween

func do_pump():
	if pump_tween and pump_tween.is_running():
		pump_tween.kill()
	
	pump_tween = create_tween()
	
	pump_tween.tween_property(self, "scale", Vector2(1.4, 0.6), 0.06)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	pump_tween.tween_property(self, "scale", Vector2(0.7, 1.3), 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	pump_tween.tween_property(self, "scale", Vector2.ONE, 0.12)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
