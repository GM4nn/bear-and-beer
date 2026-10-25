extends Node
## Registra las acciones de entrada del GDD (sección 3) al arrancar el juego.


signal cambiaron
const CONFIG := "user://controles.cfg"
const NOMBRES := {"izquierda": "Mover a la izquierda", "derecha": "Mover a la derecha",
	"arriba": "Mover al fondo", "abajo": "Mover al frente", "saltar": "Saltar",
	"golpear": "Puño derecho", "puno_izquierdo": "Puño izquierdo", "cabezazo": "Cabezazo",
	"patada": "Patada", "parada": "Parada a tiempo", "esquivar": "Rodar",
	"agarrar": "Interactuar / revivir / hombros", "beber": "Beber", "lanzar": "Botella / lanzar compa"}
var originales := {}

func _ready() -> void:
	_accion("izquierda", [KEY_A, KEY_LEFT])
	_accion("derecha", [KEY_D, KEY_RIGHT])
	_accion("arriba", [KEY_W, KEY_UP])
	_accion("abajo", [KEY_S, KEY_DOWN])
	_accion("saltar", [KEY_SPACE], [JOY_BUTTON_A])
	_accion("golpear", [KEY_H], [JOY_BUTTON_X])
	_accion("puno_izquierdo", [KEY_J])
	_eje("puno_izquierdo", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_accion("cabezazo", [KEY_K], [JOY_BUTTON_LEFT_STICK])
	_accion("patada", [KEY_L], [JOY_BUTTON_DPAD_DOWN])
	_accion("agarrar", [KEY_E], [JOY_BUTTON_Y])
	_accion("beber", [KEY_Q], [JOY_BUTTON_RIGHT_SHOULDER])
	_accion("esquivar", [KEY_SHIFT], [JOY_BUTTON_B])
	_accion("lanzar", [KEY_R], [JOY_BUTTON_LEFT_SHOULDER])
	_accion("empujar_compa", [], [JOY_BUTTON_RIGHT_STICK])
	_accion("parada", [KEY_F])
	_eje("parada", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_eje("izquierda", JOY_AXIS_LEFT_X, -1.0)
	_eje("derecha", JOY_AXIS_LEFT_X, 1.0)
	_eje("arriba", JOY_AXIS_LEFT_Y, -1.0)
	_eje("abajo", JOY_AXIS_LEFT_Y, 1.0)

	for accion in NOMBRES:
		originales[accion] = InputMap.action_get_events(accion).duplicate()
	cargar()


func tecla(accion: String) -> String:
	var nombres := PackedStringArray()
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			nombres.append(OS.get_keycode_string(evento.physical_keycode if evento.physical_keycode else evento.keycode))
	return " / ".join(nombres)


func asignar(accion: String, codigo: int, guardar := true) -> String:
	if not NOMBRES.has(accion) or codigo <= 0 or codigo in [KEY_ESCAPE, KEY_ENTER, KEY_TAB]:
		return "Esc, Enter y Tab se reservan para los menús."
	for otra in NOMBRES:
		if otra == accion:
			continue
		for evento in InputMap.action_get_events(otra):
			if evento is InputEventKey and evento.physical_keycode == codigo:
				return "Esa tecla ya se usa para: " + NOMBRES[otra]
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			InputMap.action_erase_event(accion, evento)
	var nuevo := InputEventKey.new()
	nuevo.physical_keycode = codigo
	InputMap.action_add_event(accion, nuevo)
	Input.action_release(accion)
	if guardar:
		var archivo := ConfigFile.new()
		for a in NOMBRES:
			var codigos := []
			for ev in InputMap.action_get_events(a):
				if ev is InputEventKey:
					codigos.append(ev.physical_keycode)
			archivo.set_value("teclas", a, codigos)
		archivo.save(CONFIG)
	cambiaron.emit()
	return ""


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(CONFIG) != OK:
		return
	# Validar el conjunto completo antes de reemplazarlo (permite intercambiar teclas).
	var mapa := {}
	var usadas := []
	for accion in NOMBRES:
		var defecto := []
		for ev in originales[accion]:
			if ev is InputEventKey:
				defecto.append(ev.physical_keycode)
		var lista = archivo.get_value("teclas", accion, defecto)
		if not lista is Array or lista.is_empty():
			return
		for codigo in lista:
			if not codigo is int or codigo <= 0 or codigo in usadas or codigo in [KEY_ESCAPE, KEY_ENTER, KEY_TAB]:
				return
			usadas.append(codigo)
		mapa[accion] = lista
	for accion in mapa:
		for ev in InputMap.action_get_events(accion):
			if ev is InputEventKey:
				InputMap.action_erase_event(accion, ev)
		for codigo in mapa[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = codigo
			InputMap.action_add_event(accion, ev)
	cambiaron.emit()


func restaurar() -> void:
	for accion in originales:
		InputMap.action_erase_events(accion)
		for ev in originales[accion]:
			InputMap.action_add_event(accion, ev)
	if FileAccess.file_exists(CONFIG):
		DirAccess.remove_absolute(CONFIG)
	cambiaron.emit()


func _accion(nombre: String, teclas: Array, botones: Array = []) -> void:
	InputMap.add_action(nombre, 0.3)
	for tecla in teclas:
		var ev := InputEventKey.new()
		ev.physical_keycode = tecla
		InputMap.action_add_event(nombre, ev)
	for boton in botones:
		var ev := InputEventJoypadButton.new()
		ev.button_index = boton
		InputMap.action_add_event(nombre, ev)


func _eje(nombre: String, eje: JoyAxis, valor: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = eje
	ev.axis_value = valor
	InputMap.action_add_event(nombre, ev)


func indicaciones(texto: String) -> String:
	var acciones := {"H": "golpear", "J": "puno_izquierdo", "K": "cabezazo", "L": "patada",
		"E": "agarrar", "Q": "beber", "R": "lanzar", "F": "parada"}
	var patron := RegEx.create_from_string("\\b[HJKLEQRF]\\b")
	var encontrados := patron.search_all(texto)
	encontrados.reverse()
	for hallazgo in encontrados:
		texto = texto.left(hallazgo.get_start()) + tecla(acciones[hallazgo.get_string()]) + texto.substr(hallazgo.get_end())
	return texto
