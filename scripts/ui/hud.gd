class_name HUD
extends CanvasLayer
## Interface: vida, tempo de sobrevivência e tela de Game Over.

signal restart_requested

@onready var _health_label: Label = $Margin/VBox/HealthLabel
@onready var _time_label: Label = $Margin/VBox/TimeLabel
@onready var _game_over: Control = $GameOver
@onready var _restart_button: Button = $GameOver/Center/Panel/VBox/RestartButton


func _ready() -> void:
	_game_over.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)


func update_health(current: int, maximum: int) -> void:
	_health_label.text = "Vida: %d / %d" % [current, maximum]


func update_time(seconds: float) -> void:
	_time_label.text = "Tempo: %.1fs" % seconds


func show_game_over() -> void:
	_game_over.visible = true
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	restart_requested.emit()
