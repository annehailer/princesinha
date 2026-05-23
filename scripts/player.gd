extends CharacterBody2D
class_name Player

enum PlayerState {
	idle,
	walk,
	jump,
	hurt,
	dead
}

enum PlayerSize {
	NORMAL,
	MINI
}

const MINI_SPEED_MULTIPLIER := 1.25
const MINI_JUMP_MULTIPLIER := 1.18
const INVINCIBILITY_TIME := 1.4


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var reload_timer: Timer = $ReloadTimer

const HOLD_FORCE := 900.0
const MAX_HOLD_TIME := 0.2

var hold_time := 0.0



const MAX_SPEED = 23
var friction: float = 6
var acceleration: float = 80
var start_jump_timer: bool = false
var set_jump_timer: float = 0
var set_jump_cooldown: float = 0.15

const JUMP_VELOCITY = 350.0

var spawn_pos: Vector2


var status: PlayerState

var size_status := PlayerSize.NORMAL
var is_invincible := false
var invincibility_token := 0


# ------------------------------------------------- PHYSICS ------------------------------------------------ @

func move(delta):
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * (MAX_SPEED * 5), (acceleration * 5) * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction)
	
	if direction < 0:
		sprite.flip_h = true
	elif direction > 0:
		sprite.flip_h = false



func _ready() -> void:
	#Engine.time_scale = 0.5
	spawn_pos = global_position
	go_to_idle_state()
	store_normal_body_values()

func _process(delta: float) -> void:
	if bullet_timer > 0:
		bullet_timer -= delta

func _physics_process(delta: float) -> void:
	shoot_behavior()
	check_if_fall()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.dead:
			dead_state(delta)
	move_and_slide()

# ------------------------------------------- GO TO X STATE ----------------------------------------------

func go_to_idle_state():
	status = PlayerState.idle
	if has_shoot_power:
		sprite.play("idle_pink")
	else:
		sprite.play("idle")


func go_to_walk_state():
	status = PlayerState.walk
	if has_shoot_power:
		sprite.play("walk_pink")
	else:
		sprite.play("walk")


func go_to_jump_state():
	status = PlayerState.jump
	if has_shoot_power:
		sprite.play("jump_pink")
	else:
		sprite.play("jump")


func go_to_dead_state():
	if status == PlayerState.dead:
		return

	if has_shoot_power:
		status = PlayerState.hurt
		sprite.play("hurt_pink")
		do_blink()

		has_shoot_power = false
		return
	else:
		status = PlayerState.dead
		Globals.score = 0
		sprite.play("dead")
		velocity.x = 0
		reload_timer.start()
	do_blink()

# ----------------------------------------------- STATES ------------------------------------------------

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	if Input.is_action_just_pressed("jump"):
		apply_jump_force()
		go_to_jump_state()
		return
	set_jump_redo(delta)

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		apply_jump_force()
		go_to_jump_state()
		return
	set_jump_redo(delta)

func hurt_state(delta):
	move(delta)

	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()


func dead_state(_delta):
	pass

func jump_state(delta):
	move(delta)

# ---------------------------------------------- JUMPING -----------------------------------------------------

	# SEGURANDO O BOTÃO: sobe mais (com power up)
	if has_jump_power:
		if Input.is_action_pressed("jump") and hold_time < MAX_HOLD_TIME and velocity.y < 0:
			velocity.y -= HOLD_FORCE * delta
			hold_time += delta
	
	# SOLTOU: corta o pulo
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# CAIU NO CHÃO
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
	
		start_jump_timer = false
		set_jump_timer = set_jump_cooldown
		return

func apply_jump_force():
	velocity.y = -JUMP_VELOCITY
	hold_time = 0.0

#------------------------------------------------ SHOOTING ----------------------------------------------

const BULLET = preload("uid://c2cueqjl5qdo1")
@onready var spawn_bubble_gum_posRight: Marker2D = %spawn_bubble_gum_posRight
@onready var spawn_bubble_gum_posLeft: Marker2D = %spawn_bubble_gum_posLeft

var bullet_cooldown: float = 0.5
var bullet_timer: float = 0 

func shoot_behavior():
	if !has_shoot_power:
		return
	
	if bullet_timer > 0: return
	
	if Input.is_action_just_pressed("shoot"):
		do_shooting()


func do_shooting():
	bullet_timer = bullet_cooldown
	
	var bullet_instance = BULLET.instantiate()
	var player_bullet: PlayerBullet = bullet_instance
	if sprite.flip_h: player_bullet.moving_right = false
	add_sibling(bullet_instance)
	if sprite.flip_h: bullet_instance.global_position = spawn_bubble_gum_posLeft.global_position
	else: bullet_instance.global_position = spawn_bubble_gum_posRight.global_position

# -------------------------------------------- TAKE DAMAGE ----------------------------------------------

func take_damage() -> void:
	if status == PlayerState.dead or is_invincible:
		return

	if has_jump_power or has_shoot_power:
		lose_powers()
		go_to_hurt_state()
		start_invincibility()
		return

	if size_status == PlayerSize.NORMAL:
		go_to_mini_state()
		go_to_hurt_state()
		start_invincibility()
		return

	go_to_dead_state()

func go_to_hurt_state() -> void:
	status = PlayerState.hurt
	sprite.play("hurt_pink" if has_shoot_power else "hurt")
	velocity.x = 0
	do_blink()


func lose_powers() -> void:
	has_jump_power = false
	has_shoot_power = false
	go_to_normal_size()

func go_to_normal_size() -> void:
	size_status = PlayerSize.NORMAL
	apply_body_size()


func start_invincibility() -> void:
	invincibility_token += 1
	var current_token := invincibility_token
	is_invincible = true

	var elapsed := 0.0
	while elapsed < INVINCIBILITY_TIME and current_token == invincibility_token:
		sprite.modulate.a = 0.35
		await get_tree().create_timer(0.08).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.08).timeout
		elapsed += 0.16

	if current_token == invincibility_token:
		sprite.modulate.a = 1.0
		is_invincible = false
		
		
# -------------------------------------------- MINI PLAYER ------------------------------------------

func go_to_mini_state() -> void:
	size_status = PlayerSize.MINI
	has_jump_power = false
	has_shoot_power = false
	apply_body_size()

func lose_life_and_respawn() -> void:
	is_invincible = false
	invincibility_token += 1
	sprite.modulate.a = 1.0
	Globals.lose_life()

	if Globals.lives <= 0:
		Globals.score = 0
		Globals.coins = 0
		Globals.reset_lives()

	reload_timer.start()

@onready var ground_collision: CollisionShape2D = $ColGround
@onready var body_collision: CollisionShape2D = $BodyArea/CollisionShape2D
@onready var feet_collision: CollisionShape2D = $FeetArea/CollisionShape2D
var normal_sprite_scale: Vector2
var normal_sprite_position: Vector2
var normal_ground_scale: Vector2
var normal_body_scale: Vector2
var normal_body_position: Vector2
var normal_feet_scale: Vector2
var normal_feet_position: Vector2

func apply_body_size() -> void:
	if size_status == PlayerSize.MINI:
		sprite.scale = normal_sprite_scale * 0.68
		sprite.position = normal_sprite_position + Vector2(0, 6.4)
		ground_collision.scale = Vector2(normal_ground_scale.x * 0.7, normal_ground_scale.y)
		body_collision.scale = Vector2(normal_body_scale.x * 0.65, normal_body_scale.y * 0.62)
		body_collision.position = normal_body_position + Vector2(0, 5.0)
		feet_collision.scale = Vector2(normal_feet_scale.x * 0.7, normal_feet_scale.y * 0.8)
		feet_collision.position = normal_feet_position
	else:
		sprite.scale = normal_sprite_scale
		sprite.position = normal_sprite_position
		ground_collision.scale = normal_ground_scale
		body_collision.scale = normal_body_scale
		body_collision.position = normal_body_position
		feet_collision.scale = normal_feet_scale
		feet_collision.position = normal_feet_position


func store_normal_body_values() -> void:
	normal_sprite_scale = sprite.scale
	normal_sprite_position = sprite.position
	normal_ground_scale = ground_collision.scale
	normal_body_scale = body_collision.scale
	normal_body_position = body_collision.position
	normal_feet_scale = feet_collision.scale
	normal_feet_position = feet_collision.position
	
	
# ---------------------------------------------- DYING ----------------------------------------------


func check_if_fall():
	if global_position.y > 400:
		go_to_dead_state()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyBullet"):
		go_to_dead_state()


	if area.is_in_group("BlueStar"):
		area.queue_free()
		print("pegou blue star")
		give_jump_power()
	
	if area.is_in_group("PinkStar"):
		area.queue_free()
		give_shoot_power()

# -------------------------------------- HEARTS / HEALTH ----------------------------------------------

pass

# ------------------------------------------- RESPAWN -----------------------------------------------

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

#--------------------------------------- BLINK ANIMATION --------------------------------------------------

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

#------------------------------------------------- JUMP RE-DO -----------------------------------------------

func set_jump_redo(delta: float):
	if status != PlayerState.jump:
		if !is_on_floor() && start_jump_timer == false:
			set_jump_timer = set_jump_cooldown
			start_jump_timer = true
	if start_jump_timer:
		if set_jump_timer > 0:
			set_jump_timer -= delta
		if set_jump_timer <= 0:
			if status == PlayerState.jump: return 
			go_to_jump_state()
			start_jump_timer = false

#---------------------------------------------- RECEBER POWER UPS ------------------------------------------

var has_jump_power := false
var has_shoot_power := false

func give_jump_power():
	has_jump_power = true
	print("ganhou pulo forte")

func give_shoot_power():
	has_shoot_power = true
	print("ganhou tiro")

func give_all_powers():
	has_jump_power = true
	has_shoot_power = true
	print("ganhou todos os poderes (+pulo e tiro)")
	sprite.play("idle_power")
