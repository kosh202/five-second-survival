extends Node2D
## Cena raiz: liga jogador, HUD, cronômetro, geração de inimigos e reinício.

const BACTERIA_SCENE := preload("res://scenes/enemies/bacteria.tscn")

# Chão da arena: de (-1200, -800) a (1200, 800). A margem evita nascer dentro da parede.
const ARENA_MIN := Vector2(-1200.0, -800.0)
const ARENA_MAX := Vector2(1200.0, 800.0)
const SPAWN_MARGIN := 48.0
const SPAWN_EDGE_BAND := 100.0
const SPAWN_SAFE_DISTANCE := 220.0
const SPAWN_ATTEMPTS := 12

const MAX_ENEMIES := 15
const SPAWN_INTERVAL_START := 2.0
const SPAWN_INTERVAL_MIN := 0.6
# 2.0 → 0.6 em 70 s de sobrevivência.
const SPAWN_INTERVAL_DECAY_PER_SECOND := 0.02

const FIRST_LEVEL_XP := 30
const XP_REQUIREMENT_GROWTH := 1.25

@onready var _player: Player = $Player
@onready var _hud: HUD = $HUD
@onready var _enemies: Node2D = $Enemies

var _elapsed_seconds: float = 0.0
var _game_over: bool = false
var _spawn_cooldown: float = 0.0
var _xp: int = 0
var _level: int = 1
var _xp_to_next: int = FIRST_LEVEL_XP
var _pending_level_ups: int = 0
var _choosing_upgrade: bool = false


func _ready() -> void:
	_player.health_changed.connect(_hud.update_health)
	_player.died.connect(_on_player_died)
	_hud.restart_requested.connect(_restart)
	_hud.upgrade_chosen.connect(_on_upgrade_chosen)
	_hud.update_health(_player.health, _player.MAX_HEALTH)
	_hud.update_time(0.0)
	_hud.update_experience(_level, _xp, _xp_to_next)


func _process(delta: float) -> void:
	if _game_over:
		if Input.is_action_just_pressed("restart"):
			_restart()
		return

	_elapsed_seconds += delta
	_hud.update_time(_elapsed_seconds)
	_update_spawning(delta)


func _update_spawning(delta: float) -> void:
	_spawn_cooldown -= delta
	if _spawn_cooldown > 0.0:
		return

	if _try_spawn_bacteria():
		_spawn_cooldown = _current_spawn_interval()
	else:
		# Lotado ou sem posição válida: tenta de novo em breve, sem acelerar a horda.
		_spawn_cooldown = 0.2


func _current_spawn_interval() -> float:
	return maxf(
		SPAWN_INTERVAL_MIN,
		SPAWN_INTERVAL_START - _elapsed_seconds * SPAWN_INTERVAL_DECAY_PER_SECOND
	)


func _try_spawn_bacteria() -> bool:
	if _alive_enemy_count() >= MAX_ENEMIES:
		return false

	var spawn_position: Variant = _pick_spawn_position()
	if spawn_position == null:
		return false

	var bacteria := BACTERIA_SCENE.instantiate() as Bacteria

# Depois de 20 segundos, algumas bactérias serão velozes.
	if _elapsed_seconds >= 20.0 and randf() < 0.3:
		bacteria.configure_fast_variant()

	bacteria.defeated.connect(_on_enemy_defeated)
	
	_enemies.add_child(bacteria)
	bacteria.global_position = spawn_position as Vector2
	return true


func _alive_enemy_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Bacteria and is_instance_valid(node) and not (node as Bacteria).is_dead:
			count += 1
	return count


func _pick_spawn_position() -> Variant:
	var min_x := ARENA_MIN.x + SPAWN_MARGIN
	var max_x := ARENA_MAX.x - SPAWN_MARGIN
	var min_y := ARENA_MIN.y + SPAWN_MARGIN
	var max_y := ARENA_MAX.y - SPAWN_MARGIN
	var player_position := _player.global_position

	for _i in SPAWN_ATTEMPTS:
		var point := _random_edge_point(min_x, max_x, min_y, max_y)
		if point.distance_to(player_position) >= SPAWN_SAFE_DISTANCE:
			return point

	return null


func _random_edge_point(min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	var band := SPAWN_EDGE_BAND
	match randi() % 4:
		0:
			return Vector2(randf_range(min_x, max_x), randf_range(min_y, min_y + band))
		1:
			return Vector2(randf_range(min_x, max_x), randf_range(max_y - band, max_y))
		2:
			return Vector2(randf_range(min_x, min_x + band), randf_range(min_y, max_y))
		_:
			return Vector2(randf_range(max_x - band, max_x), randf_range(min_y, max_y))


func _on_enemy_defeated(xp_amount: int) -> void:
	if _game_over:
		return

	_xp += xp_amount
	while _xp >= _xp_to_next:
		_xp -= _xp_to_next
		_level += 1
		_xp_to_next = maxi(1, roundi(float(_xp_to_next) * XP_REQUIREMENT_GROWTH))
		_pending_level_ups += 1

	_hud.update_experience(_level, _xp, _xp_to_next)
	_try_show_next_upgrade()


func _try_show_next_upgrade() -> void:
	if _game_over or _choosing_upgrade or _pending_level_ups <= 0:
		return

	_choosing_upgrade = true
	get_tree().paused = true
	_hud.show_upgrade_choices(_pick_upgrade_ids())


func _pick_upgrade_ids() -> Array[StringName]:
	var pool: Array[StringName] = [&"damage", &"attack_speed", &"range", &"move_speed"]
	pool.shuffle()
	return [pool[0], pool[1], pool[2]]


func _on_upgrade_chosen(upgrade_id: StringName) -> void:
	if _game_over:
		_clear_upgrade_pause()
		return

	_player.apply_upgrade(upgrade_id)
	_pending_level_ups = maxi(0, _pending_level_ups - 1)
	_choosing_upgrade = false

	if _pending_level_ups > 0:
		_try_show_next_upgrade()
	else:
		_clear_upgrade_pause()


func _clear_upgrade_pause() -> void:
	_choosing_upgrade = false
	_hud.hide_upgrade_panel()
	get_tree().paused = false


func _on_player_died() -> void:
	_game_over = true
	_pending_level_ups = 0
	_clear_upgrade_pause()
	_hud.show_game_over()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
