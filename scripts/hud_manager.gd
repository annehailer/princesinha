extends Control

@onready var coins_counter: Label = $Container/CoinsContainer/CoinsCounter as Label
@onready var timer_counter: Label = $Container/TimerContainer/TimerCounter as Label
@onready var score_counter: Label = $Container/ScoreContainer/ScoreCounter as Label


func _ready() -> void:
	coins_counter.text = str("%04d" % Globals.coins)
	score_counter.text = str("%06d" % Globals.score)


func _process(delta: float) -> void:
	coins_counter.text = str("%04d" % Globals.coins)
