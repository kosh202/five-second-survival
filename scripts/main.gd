extends Node2D
## Cena raiz: liga jogador, inimigo, HUD, cronômetro e reinício.

@onready var _player: Player = $Player
@onready var _hud: HUD = $HUD

var _elapsed_seconds: float = 0.0
var _game_over: bool = false


func _ready() -> void:
	_player.health_changed.connect(_hud.update_health)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_restart)
	_hud.update_health(_player.health, _player.MAX_HEALTH)
	_hud.update_time(0.0)


func _process(delta: float) -> void:
	if _game_over:
		if Input.is_action_just_pressed("restart"):
			_restart()
		return

	_elapsed_seconds += delta
	_hud.update_time(_elapsed_seconds)


func _on_player_died() -> void:
	_game_over = true
	_hud.show_game_over()


func _restart() -> void:
	get_tree().reload_current_scene()
