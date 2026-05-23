extends Control

const HEART_CONTAINER = preload("uid://bpolt4mpolmfy")

@onready var coins_counter: Label = $Container/CoinsContainer/CoinsCounter as Label
@onready var timer_counter: Label = get_node_or_null("Container/TimerContainer/TimerCounter") as Label
@onready var score_counter: Label = $Container/ScoreContainer/ScoreCounter as Label

var heart_container: Control


func _ready() -> void:
	coins_counter.text = str("%04d" % Globals.coins)
	score_counter.text = str("%06d" % Globals.score)
	setup_heart_container()
	Globals.lives_changed.connect(update_hearts)
	update_hearts(Globals.lives, Globals.max_lives)


func _process(delta: float) -> void:
	coins_counter.text = str("%04d" % Globals.coins)
	score_counter.text = str("%06d" % Globals.score)


func setup_heart_container() -> void:
	var hud := get_parent()
	heart_container = hud.get_node_or_null("HeartContainer") as Control
	if heart_container == null:
		heart_container = HEART_CONTAINER.instantiate()
		hud.add_child(heart_container)


func update_hearts(current_lives: int, max_lives: int) -> void:
	if heart_container == null:
		return

	var grid := heart_container.get_node_or_null("GridContainer")
	if grid == null:
		return

	var index := 0
	for heart in grid.get_children():
		if heart is CanvasItem:
			heart.visible = index < max_lives
			heart.modulate.a = 1.0 if index < current_lives else 0.2
			index += 1
