extends CharacterBody2D

enum SkeletonState {
	walk,
	attack,
	dead
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node2D = $BoneStartPosition


const SPINNING_BONE = preload("uid://dv7eoyldq1xb4")


const SPEED = 20.0
const JUMP_VELOCITY = -400.0
var direction = 1

var status: SkeletonState

var can_throw = true

func _ready() -> void:
	sprite.material = sprite.material.duplicate()
	go_to_walk_state()


func _physics_process(delta: float) -> void:
	# Add the gravity.
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
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO


func walk_state(_delta):
	if status == SkeletonState.dead: return
	velocity.x = SPEED * direction
	
	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if player_detector.is_colliding():
		go_to_attack_state()
		return


func attack_state(_delta):
	if sprite.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

func dead_state(_delta):
	pass


func take_damage():
	do_blink()
	go_to_dead_state()

func throw_bone():
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(self.direction)

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


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		go_to_walk_state()
		return
