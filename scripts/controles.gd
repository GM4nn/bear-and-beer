extends Node
## Registra las acciones de entrada del GDD (sección 3) al arrancar el juego.


func _ready() -> void:
	_accion("izquierda", [KEY_A, KEY_LEFT])
	_accion("derecha", [KEY_D, KEY_RIGHT])
	_accion("arriba", [KEY_W, KEY_UP])
	_accion("abajo", [KEY_S, KEY_DOWN])
	_accion("saltar", [KEY_SPACE], [JOY_BUTTON_A])
	_accion("golpear", [KEY_J], [JOY_BUTTON_X], MOUSE_BUTTON_LEFT)
	_accion("agarrar", [KEY_E], [JOY_BUTTON_Y])
	_accion("beber", [KEY_Q], [JOY_BUTTON_RIGHT_SHOULDER])
	_accion("esquivar", [KEY_SHIFT, KEY_K], [JOY_BUTTON_B])
	_eje("izquierda", JOY_AXIS_LEFT_X, -1.0)
	_eje("derecha", JOY_AXIS_LEFT_X, 1.0)
	_eje("arriba", JOY_AXIS_LEFT_Y, -1.0)
	_eje("abajo", JOY_AXIS_LEFT_Y, 1.0)


func _accion(nombre: String, teclas: Array, botones: Array = [], raton := MOUSE_BUTTON_NONE) -> void:
	InputMap.add_action(nombre, 0.3)
	for tecla in teclas:
		var ev := InputEventKey.new()
		ev.physical_keycode = tecla
		InputMap.action_add_event(nombre, ev)
	for boton in botones:
		var ev := InputEventJoypadButton.new()
		ev.button_index = boton
		InputMap.action_add_event(nombre, ev)
	if raton != MOUSE_BUTTON_NONE:
		var ev := InputEventMouseButton.new()
		ev.button_index = raton
		InputMap.action_add_event(nombre, ev)


func _eje(nombre: String, eje: JoyAxis, valor: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = eje
	ev.axis_value = valor
	InputMap.action_add_event(nombre, ev)
