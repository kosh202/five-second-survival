
extends Area2D
## Coletável de Essência de Comida.

signal collected(amount: int)

const VALUE := 1
const RADIUS := 12.0

var _player_inside := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	# Brilho externo.
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(1.0, 0.65, 0.12, 0.20))

	# Núcleo dourado.
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.68, 0.12))

	# Reflexo claro.
	draw_circle(Vector2(-3.0, -3.0), 4.0, Color(1.0, 0.92, 0.52))


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	collected.emit(VALUE)
	queue_free()
