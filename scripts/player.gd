extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	dead
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var reload_timer: Timer = $ReloadTimer



const MAX_SPEED = 23
var friction: float = 4
var acceleration: float = 50
var start_jump_timer: bool = false
var set_jump_timer: float = 0
var set_jump_cooldown: float = 0.15

const JUMP_VELOCITY = 350.0

var spawn_pos: Vector2


var status: PlayerState

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


func go_to_idle_state():
	status = PlayerState.idle
	sprite.play("idle")


func go_to_walk_state():
	status = PlayerState.walk
	sprite.play("walk")


func go_to_jump_state():
	status = PlayerState.jump
	sprite.play("jump")


func go_to_dead_state():
	status = PlayerState.dead
	sprite.play("dead")
	velocity.x = 0
	reload_timer.start()
	do_blink()


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

#------------------------------ SHOOTING ------------------

const BULLET = preload("uid://c2cueqjl5qdo1")
@onready var bullet_start_position: Node2D = %BulletStartPosition

var bullet_cooldown: float = 0.5
var bullet_timer: float = 0 

func shoot_behavior():
	if bullet_timer > 0: return
	if Input.is_action_just_pressed("shoot"):
		do_shooting()


func do_shooting():
	bullet_timer = bullet_cooldown
	
	var bullet_instance = BULLET.instantiate()
	var player_bullet: PlayerBullet = bullet_instance
	if sprite.flip_h: player_bullet.moving_right = false
	bullet_instance.position = bullet_start_position.global_position
	add_sibling(bullet_instance)


func die():
	global_position = spawn_pos


func check_if_fall():
	if global_position.y > 400:
		die()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("EnemyBullet"):
		hit_enemy_bullet()



func hit_enemy(area: Area2D):
	if velocity.y > 0:
		# inimigo morre
		area.get_parent().take_damage()
		ScreenShake.do_screen_shake(3.5, 0.5)
		#go_to_jump_state()
		apply_jump_force()
	else:
		# player morre
		if status != PlayerState.dead:
			go_to_dead_state()

func hit_enemy_bullet():
	go_to_dead_state()


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
	

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

############################################################################

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
			print("vai pro jump state")
			go_to_jump_state()
			start_jump_timer = false
