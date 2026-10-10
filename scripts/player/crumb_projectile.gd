extends Area2D
## Farelo provisório disparado pelo jogador. Segue o alvo e aplica dano uma vez.

const SPEED := 480.0
const LIFETIME_SECONDS := 1.25
const RADIUS := 6.0

var _target: Node2D
var _direction := Vector2.RIGHT
var _damage := 1
var _lifetime_left := LIFETIME_SECONDS
var _spent := false


func setup(target: Node2D, damage: int) -> void:
	_target = target
	_damage = damage
	if is_instance_valid(_target):
		_direction = global_position.direction_to(_target.global_position)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.93, 0.78, 0.38))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.72, 0.42, 0.16), false, 1.5)


func _physics_process(delta: float) -> void:
	if _spent:
		return

	_lifetime_left -= delta
	if _lifetime_left <= 0.0:
		queue_free()
		return

	if is_instance_valid(_target):
		_direction = global_position.direction_to(_target.global_position)

	global_position += _direction * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if _spent or not body is Bacteria:
		return

	_spent = true
	(body as Bacteria).take_damage(_damage)
	queue_free()
