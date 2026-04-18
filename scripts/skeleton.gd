extends CharacterBody2D

enum SkeletonState {
	walk,
	dead
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector


const SPEED = 20.0
const JUMP_VELOCITY = -400.0

var status: SkeletonState

var direction = 1

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
		SkeletonState.dead:
			dead_state(delta)
	
	move_and_slide()


func go_to_walk_state():
	status = SkeletonState.walk
	sprite.play("walk")


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



func dead_state(_delta):
	pass


func take_damage():
	do_blink()
	go_to_dead_state()



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
