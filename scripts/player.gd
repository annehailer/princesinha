extends CharacterBody2D
class_name Player

enum PlayerState {
	idle,
	idle_power,
	walk_power,
	jump_power,
	fall_power,
	walk,
	jump,
	fall,
	dead
}

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
			jump_State(delta)
		PlayerState.dead:
			dead_state(delta)
	move_and_slide()

# ------------------------------------------- GO TO X STATE ----------------------------------------------

func go_to_idle_state():
	status = PlayerState.idle
	if has_shoot_power:
		sprite.play("idle_power")
	else:
		sprite.play("idle")


func go_to_walk_state():
	status = PlayerState.walk
	if has_shoot_power:
		sprite.play("walk_power")
	else:
		sprite.play("walk")


func go_to_jump_state():
	status = PlayerState.jump
	if has_jump_power:
		sprite.play("jump_power")
	else:
		sprite.play("jump")


func go_to_dead_state():
	if status == PlayerState.dead: return
	status = PlayerState.dead
	#if has_shoot_power:
		#sprite.play("hurt_power")
	#else:
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


func dead_state(_delta):
	pass

func jump_State(delta):
	move(delta)

# ---------------------------------------------- JUMPING -----------------------------------------------------

# SEGURANDO O BOTÃO → sobe mais (COM POWER UP)
	if has_jump_power:
		if Input.is_action_pressed("jump") and hold_time < MAX_HOLD_TIME and velocity.y < 0:
			velocity.y -= HOLD_FORCE * delta
			hold_time += delta

	# SOLTOU → corta o pulo
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

# --------------------------------------------------- DYING -------------------------------------------------

func die():
	global_position = spawn_pos


func check_if_fall():
	if global_position.y > 400:
		die()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		#hit_enemy(area)
		pass
	elif area.is_in_group("EnemyBullet"):
		hit_enemy_bullet()


func hit_enemy_bullet():
	go_to_dead_state()

# ------------------------------------------- RESPAWN -----------------------------------------------------

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
	print("Ganhou pulo forte")

func give_shoot_power():
	has_shoot_power = true
	print("Ganhou tiro")

func give_all_powers():
	has_jump_power = true
	has_shoot_power = true
	print("Ganhou todos os poderes")
	sprite.play("idle_power")
