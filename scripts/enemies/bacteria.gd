
class_name Bacteria
extends CharacterBody2D
## Inimigo que persegue o jogador e pode ser eliminado.

signal defeated(xp_amount: int)

const SPEED := 150.0
const DAMAGE := 1
const RADIUS := 18.0
const MAX_HEALTH := 4
const HIT_FLASH_SECONDS := 0.12
const XP_REWARD := 10

const FAST_SPEED := 230.0
const FAST_MAX_HEALTH := 2

@onready var _hitbox: Area2D = $Hitbox

var health: int = MAX_HEALTH
var is_dead: bool = false

var _player: Player
var _flash_left: float = 0.0
var _movement_speed: float = SPEED
var _max_health: int = MAX_HEALTH
var _xp_reward: int = XP_REWARD
var _is_fast_variant: bool = false


func configure_fast_variant() -> void:
	_is_fast_variant = true
	_movement_speed = FAST_SPEED
	_max_health = FAST_MAX_HEALTH
	_xp_reward = XP_REWARD
	health = _max_health


func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player") as Player
	health = _max_health
	queue_redraw()


func _draw() -> void:
	if _is_fast_variant:
		# Variante veloz: vermelha para se distinguir da comum.
		draw_circle(Vector2.ZERO, RADIUS, Color(0.92, 0.30, 0.20))
		draw_circle(Vector2.ZERO, RADIUS, Color(0.55, 0.12, 0.10), false, 2.0)
		draw_circle(Vector2(-6, -4), 4.5, Color(0.62, 0.12, 0.10))
		draw_circle(Vector2(5, 3), 3.5, Color(0.68, 0.16, 0.12))
		draw_circle(Vector2(2, -7), 2.5, Color(0.75, 0.20, 0.15))
		return

	# Bactéria comum: círculo verde com manchas mais escuras.
	draw_circle(Vector2.ZERO, RADIUS, Color(0.22, 0.72, 0.30))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.10, 0.38, 0.16), false, 2.0)
	draw_circle(Vector2(-6, -4), 4.5, Color(0.12, 0.48, 0.20))
	draw_circle(Vector2(5, 3), 3.5, Color(0.14, 0.52, 0.22))
	draw_circle(Vector2(2, -7), 2.5, Color(0.18, 0.60, 0.26))


func _physics_process(delta: float) -> void:
	_update_flash(delta)

	if is_dead or _player == null or not is_instance_valid(_player) or _player.is_dead:
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(_player.global_position)
	velocity = direction * _movement_speed
	move_and_slide()
	_try_damage_player()


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	health = maxi(health - amount, 0)
	_flash_left = HIT_FLASH_SECONDS
	modulate = Color(1.35, 1.35, 1.15)

	if health == 0:
		_die()


func _update_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return

	_flash_left -= delta
	if _flash_left <= 0.0 and not is_dead:
		modulate = Color.WHITE


func _try_damage_player() -> void:
	# O jogador ignora dano durante a própria invulnerabilidade.
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(DAMAGE)


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	defeated.emit(_xp_reward)
	queue_free()
