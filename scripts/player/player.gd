class_name Player
extends CharacterBody2D
## Comida jogável. Move-se com WASD/setas, ataca sozinha no alcance e avisa a HUD.

signal health_changed(current: int, maximum: int)
signal died

const MAX_HEALTH := 5
const INVULNERABILITY_SECONDS := 0.75
const RADIUS := 26.0
const INITIAL_MOVE_SPEED := 240.0
const INITIAL_ATTACK_RANGE := 280.0
const INITIAL_ATTACK_INTERVAL := 0.65
const INITIAL_ATTACK_DAMAGE := 1
const MIN_ATTACK_INTERVAL := 0.20

const CRUMB_SCENE := preload("res://scenes/player/crumb_projectile.tscn")

var health: int = MAX_HEALTH
var is_dead: bool = false
var move_speed: float = INITIAL_MOVE_SPEED
var attack_range: float = INITIAL_ATTACK_RANGE
var attack_interval: float = INITIAL_ATTACK_INTERVAL
var attack_damage: int = INITIAL_ATTACK_DAMAGE

var _invulnerable: bool = false
var _invulnerability_left: float = 0.0
var _attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("player")
	queue_redraw()


func _draw() -> void:
	# Pizza provisória: crosta, queijo e calabresas (sem sprites).
	draw_circle(Vector2.ZERO, RADIUS, Color(0.72, 0.42, 0.16))
	draw_circle(Vector2.ZERO, RADIUS - 5.0, Color(0.96, 0.82, 0.30))
	draw_circle(Vector2(-8, -6), 5.5, Color(0.78, 0.18, 0.16))
	draw_circle(Vector2(7, -2), 4.5, Color(0.82, 0.22, 0.18))
	draw_circle(Vector2(-2, 8), 5.0, Color(0.74, 0.16, 0.14))
	draw_circle(Vector2(9, 8), 3.5, Color(0.80, 0.20, 0.16))


func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)

	if is_dead:
		velocity = Vector2.ZERO
		return

	# get_vector já normaliza diagonais para a velocidade não ficar maior.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_update_auto_attack(delta)


func take_damage(amount: int) -> void:
	if is_dead or _invulnerable or amount <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)

	if health == 0:
		_die()
		return

	_invulnerable = true
	_invulnerability_left = INVULNERABILITY_SECONDS
	modulate = Color(1.0, 1.0, 1.0, 0.45)


func _update_invulnerability(delta: float) -> void:
	if not _invulnerable:
		return

	_invulnerability_left -= delta
	if _invulnerability_left <= 0.0:
		_invulnerable = false
		modulate = Color.WHITE


func _update_auto_attack(delta: float) -> void:
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_fire_at(target)
	_attack_cooldown = attack_interval


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := attack_range

	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if node is Bacteria and (node as Bacteria).is_dead:
			continue
		var enemy := node as Node2D
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest


func _fire_at(target: Node2D) -> void:
	var crumb := CRUMB_SCENE.instantiate()
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(crumb)
	crumb.global_position = global_position
	crumb.setup(target, attack_damage)


func apply_upgrade(upgrade_id: StringName) -> void:
	match upgrade_id:
		&"damage":
			attack_damage += 1
		&"attack_speed":
			attack_interval = maxf(MIN_ATTACK_INTERVAL, attack_interval * 0.85)
		&"range":
			attack_range += 50.0
		&"move_speed":
			move_speed += 25.0


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	modulate = Color(0.55, 0.55, 0.55, 0.85)
	died.emit()
