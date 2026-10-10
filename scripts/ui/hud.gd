class_name HUD
extends CanvasLayer
## Interface: vida, tempo, XP, melhorias, Game Over e reinício.

signal restart_requested
signal upgrade_chosen(upgrade_id: StringName)

const UPGRADE_TEXT := {
	&"damage": ["Mais dano", "As migalhas causam +1 de dano."],
	&"attack_speed": ["Ataque mais rápido", "O intervalo entre disparos cai 15% (mínimo 0,20 s)."],
	&"range": ["Maior alcance", "O ataque automático alcança +50 pixels."],
	&"move_speed": ["Mais velocidade", "A pizza se move +25 pixels por segundo."],
}

@onready var _health_label: Label = $Margin/VBox/HealthLabel
@onready var _time_label: Label = $Margin/VBox/TimeLabel
@onready var _level_label: Label = $Margin/VBox/LevelLabel
@onready var _xp_label: Label = $Margin/VBox/XpLabel
@onready var _xp_bar: ProgressBar = $Margin/VBox/XpBar
@onready var _game_over: Control = $GameOver
@onready var _restart_button: Button = $GameOver/Center/Panel/VBox/RestartButton
@onready var _upgrade_panel: Control = $UpgradePanel
@onready var _option_buttons: Array[Button] = [
	$UpgradePanel/Center/Panel/VBox/Option1,
	$UpgradePanel/Center/Panel/VBox/Option2,
	$UpgradePanel/Center/Panel/VBox/Option3,
]

var _current_choices: Array[StringName] = []


func _ready() -> void:
	_game_over.visible = false
	_upgrade_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	for i in _option_buttons.size():
		_option_buttons[i].pressed.connect(_on_option_pressed.bind(i))


func update_health(current: int, maximum: int) -> void:
	_health_label.text = "Vida: %d / %d" % [current, maximum]


func update_time(seconds: float) -> void:
	_time_label.text = "Tempo: %.1fs" % seconds


func update_experience(level: int, current_xp: int, xp_to_next: int) -> void:
	_level_label.text = "Nível: %d" % level
	_xp_label.text = "XP: %d / %d" % [current_xp, xp_to_next]
	_xp_bar.max_value = maxf(1.0, float(xp_to_next))
	_xp_bar.value = clampf(float(current_xp), 0.0, _xp_bar.max_value)


func show_game_over() -> void:
	hide_upgrade_panel()
	_game_over.visible = true
	_restart_button.grab_focus()


func show_upgrade_choices(choices: Array[StringName]) -> void:
	if _game_over.visible or choices.size() < 3:
		return

	_current_choices = choices.duplicate()
	for i in 3:
		var texts: Array = UPGRADE_TEXT.get(choices[i], ["Melhoria", ""])
		_option_buttons[i].text = "%s\n%s" % [texts[0], texts[1]]

	_upgrade_panel.visible = true
	_option_buttons[0].grab_focus()


func hide_upgrade_panel() -> void:
	_upgrade_panel.visible = false
	_current_choices.clear()


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _current_choices.size():
		return
	var upgrade_id := _current_choices[index]
	hide_upgrade_panel()
	upgrade_chosen.emit(upgrade_id)


func _on_restart_pressed() -> void:
	restart_requested.emit()
