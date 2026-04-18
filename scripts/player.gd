extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	dead
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var reload_timer: Timer = $ReloadTimer

const BULLET = preload("uid://c2cueqjl5qdo1")
@onready var bullet_start_position: Node2D = %BulletStartPosition



const MAX_SPEED = 23
var friction: float = 4
var acceleration: float = 50

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
	velocity.y = -JUMP_VELOCITY

func go_to_dead_state():
	status = PlayerState.dead
	sprite.play("dead")
	velocity.x = 0
	reload_timer.start()


func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func dead_state(_delta):
	pass

func jump_State(delta):
	move(delta)
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return



@export var bullet_scene: PackedScene

func shoot_behavior():
	if Input.is_action_just_pressed("shoot"):
		do_shooting()


func do_shooting():
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
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()



func hit_enemy(area: Area2D):
	if velocity.y > 0:
		# inimigo morre
		area.get_parent().take_damage()
		ScreenShake.do_screen_shake(3.5, 0.5)
		go_to_jump_state()
	else:
		# player morre
		if status != PlayerState.dead:
			go_to_dead_state()

func hit_lethal_area():
	go_to_dead_state()



func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
