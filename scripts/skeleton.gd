extends CharacterBody2D
class_name Skeleton

enum SkeletonState {
	walk,
	attack,
	dead
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_hitbox: Area2D = %body_hitbox
@onready var head_hitbox: Area2D = %head_hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node2D = $BoneStartPosition
var is_on_screen: bool = false


const SPINNING_BONE = preload("uid://dv7eoyldq1xb4")


const SPEED = 20.0
const JUMP_VELOCITY = -400.0
var direction = -1

var status: SkeletonState

var can_throw = true

func _ready() -> void:
	sprite.material = sprite.material.duplicate()
	go_to_walk_state()

func _process(delta: float) -> void:
	if bone_timer > 0:
		bone_timer -= delta
	#print(is_on_screen)

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.attack:
			attack_state(delta)
		SkeletonState.dead:
			dead_state(delta)
	
	move_and_slide()

# --------------------------------------- GO TO X STATE --------------------------------------

func go_to_walk_state():
	status = SkeletonState.walk
	sprite.play("walk")

func go_to_attack_state():
	status = SkeletonState.attack
	sprite.play("attack")
	velocity = Vector2.ZERO
	can_throw = true


func go_to_dead_state():
	status = SkeletonState.dead
	sprite.play("dead")
	#body_hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	#head_hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	#body_hitbox.monitoring = false
	#head_hitbox.monitoring = false
	velocity = Vector2.ZERO

# ----------------------------------------- STATES ------------------------------------------------

func walk_state(_delta):
	if status == SkeletonState.dead: return
	if sprite.frame == 3 or sprite.frame == 4:
		velocity.x = SPEED * direction
	else:
		velocity.x = 0
	
# ---------------------------------------------- RAY CAST ------------------------------
	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if player_detector.is_colliding():
		#print("detectou player")
		if !is_on_screen: return
		#print("tela")
		if bone_timer > 0: return
		go_to_attack_state()
		return


func attack_state(_delta):
	if sprite.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

func dead_state(_delta):
	pass

# --------------------------------------- DAMAGE / HIT ------------------------------------- 

func take_damage():
	if status == SkeletonState.dead: return
	do_blink()
	go_to_dead_state()

var bone_cooldown: float = 2.0
var bone_timer: float = 0

func throw_bone():
	bone_timer = bone_cooldown
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(self.direction)
	go_to_walk_state()

#--------------------------------------- BLINK ANIMATION --------------------------

var blink_duration: float = 0.8
var blink_tween: Tween


func do_blink():
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	
	_set_flash(1.0)
	
	blink_tween = create_tween()
	
	blink_tween.tween_method(
		_set_flash,
		1.0,
		0.0,
		blink_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_flash(value: float):
	sprite.material.set_shader_parameter("flash_pct", value)


#---------------------------------------------------------------------------------------


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		go_to_walk_state()
		return


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	is_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	is_on_screen = false
	if status == SkeletonState.attack: go_to_walk_state()


func kill_player(player: Player) -> void:
	await get_tree().create_timer(0.05).timeout
	
	if !is_instance_valid(player):
		return
	
	if status == SkeletonState.dead:
		return
	
	player.go_to_dead_state()


func _on_hitbox_area_entered(area: Area2D) -> void:
	# player morre se encostar no esqueleto
	if status == SkeletonState.dead: return
	if area.is_in_group("PlayerBody"):
		var player: Player = area.get_parent()
		kill_player(player)
	# esqueleto morre se a bala encostar nele
	if area.is_in_group("BubbleGum"):
		take_damage()
		ScreenShake.do_screen_shake(2, 0.5)
		area.get_parent().queue_free()


func _on_head_hitbox_area_entered(area: Area2D) -> void:
	if status == SkeletonState.dead: return
	if area.is_in_group("PlayerFeet"):
		take_damage()
		var player: Player = area.get_parent()
		player.apply_jump_force()
		ScreenShake.do_screen_shake(3.5, 0.5)
