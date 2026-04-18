extends Node

var main_camera: Camera2D        # referência para a câmera verdadeira
var shake_intensity: float = 0.0
var active_shake_time: float = 0.0
var shake_decay: float = 5.0
var shake_time: float = 0.0
var shake_time_speed: float = 20.0
var noise = FastNoiseLite.new()


func do_screen_shake(intensity: float, time: float):
	if main_camera == null:
		main_camera = get_viewport().get_camera_2d()
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0

	shake_intensity = intensity
	active_shake_time = time
	shake_time = 0.0


func _physics_process(delta: float) -> void:
	if main_camera == null:
		return

	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta

		main_camera.offset = Vector2(
			noise.get_noise_2d(shake_time, 0) * shake_intensity,
			noise.get_noise_2d(0, shake_time) * shake_intensity
		)

		shake_intensity = max(shake_intensity - shake_decay * delta, 0)
	else:
		main_camera.offset = lerp(main_camera.offset, Vector2.ZERO, 10.5 * delta)
