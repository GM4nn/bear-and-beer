extends Node
## Entrada local en coordenadas de un lienzo común; el servidor juzga cada compa.
const PREPARACION := 3.0
const PASOS := 6
const TOLERANCIA := 0.28
## Tiempo al empezar cada objetivo para volver a picar el clic sin castigo.
const GRACIA_INICIO := 0.15
const LIENZO := Vector2(1280, 720)
const BORDE := 2.0 # Mitad del grosor del contorno que también ve el jugador.
var entradas := {}
var errores := {}
var cubierto := {}
var reloj := 0.0
var secuencia := 0
var _intento := -1
var _pulsado := false
var _cursor := Vector2.ZERO
var _envio := 0.0
var _tiempo_mostrado := 0.0
var _paso_mostrado := -1
var _encuentro_mostrado := -1
var _estado_mostrado := ""
var _vista: Control
var _texto: Label
var _estado: Label
var _caja_texto: PanelContainer
var _caja_estado: PanelContainer
var _barras: Array[ProgressBar] = []
var _nombres: Array[Label] = []
var _capa: CanvasLayer

func _ready() -> void:
	process_physics_priority = 20
	process_priority = 20
	_capa = CanvasLayer.new()
	_capa.layer = 8
	add_child(_capa)
	_vista = Control.new()
	_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(_vista)
	_vista.draw.connect(_dibujar)
	# Recuadros como el de la misión: café oscuro con borde ámbar y la letra del juego.
	_caja_texto = _recuadro()
	_texto = _etiqueta(_caja_texto, 24)
	_caja_estado = _recuadro()
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja_estado.add_child(columna)
	_estado = _etiqueta(columna, 16)
	var filas := HBoxContainer.new()
	filas.alignment = BoxContainer.ALIGNMENT_CENTER
	filas.add_theme_constant_override("separation", 18)
	filas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(filas)
	for i in 3:
		var bloque := VBoxContainer.new()
		bloque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		filas.add_child(bloque)
		var nombre := Label.new()
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.add_theme_font_size_override("font_size", 14)
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bloque.add_child(nombre)
		var barra := ProgressBar.new()
		barra.custom_minimum_size = Vector2(150, 12)
		barra.max_value = 1.0
		barra.show_percentage = false
		barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fondo := StyleBoxFlat.new()
		fondo.bg_color = Color("20140b")
		fondo.border_color = Color("6b4626")
		fondo.set_border_width_all(1)
		fondo.set_corner_radius_all(4)
		barra.add_theme_stylebox_override("background", fondo)
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = Color("8cff8c")
		relleno.set_corner_radius_all(4)
		barra.add_theme_stylebox_override("fill", relleno)
		bloque.add_child(barra)
		_nombres.append(nombre)
		_barras.append(barra)
	get_window().focus_exited.connect(_soltar)

func _recuadro() -> PanelContainer:
	var panel := PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.14, 0.08, 0.04, 0.9)
	caja.border_color = TemaUI.AMBAR
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(8)
	caja.content_margin_left = 20
	caja.content_margin_right = 20
	caja.content_margin_top = 8
	caja.content_margin_bottom = 10
	caja.shadow_color = Color(0, 0, 0, 0.35)
	caja.shadow_size = 6
	panel.add_theme_stylebox_override("panel", caja)
	panel.theme = TemaUI.tema()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista.add_child(panel)
	return panel


func _etiqueta(padre: Control, letra: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", letra)
	l.add_theme_color_override("font_color", TemaUI.CREMA)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l

func iniciar() -> void:
	limpiar()
	for id in get_parent().participantes:
		entradas[id] = {"pos": Vector2.ZERO, "pulsa": false, "cuando": -100.0, "secuencia": -1, "paso": -1, "visto": -1.0, "dentro": false}
		errores[id] = 0.0
		cubierto[id] = 0.0

func limpiar() -> void:
	entradas.clear()
	errores.clear()
	cubierto.clear()
	_pulsado = false
	_envio = 0.0
	_paso_mostrado = -1
	_encuentro_mostrado = -1

func _conectado() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

## No acepta aciertos ni identidades del cliente: calcula el contacto con el reloj visto.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func mover(numero: int, paso: int, orden: int, cursor: Vector2, pulsado: bool, tiempo_visto: float = -1.0) -> void:
	var r := get_parent()
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = multiplayer.get_unique_id()
	if not multiplayer.is_server() or get_tree().paused or r._partida().finalizada or numero != r.encuentro or r.estado not in ["preparando", "ritmo"] or not entradas.has(id):
		return
	if paso != r.paso or orden <= entradas[id].secuencia or not cursor.is_finite() or cursor.x < 0 or cursor.y < 0 or cursor.x > 1 or cursor.y > 1:
		return
	# El cliente devuelve el reloj replicado que está dibujando, nunca un acierto.
	# Limitar antigüedad y avance impide escoger libremente otro tramo del camino.
	var visto: float = r.tiempo if tiempo_visto == -1.0 else tiempo_visto
	var margen := clampf(float(Red.latencias.get(id, 0)) / 1000.0 + 0.2, 0.2, 0.8)
	if not is_finite(visto) or visto < 0 or visto > r.tiempo + 0.02 or visto < r.tiempo - margen:
		return
	# La cuenta atrás y el trazado tienen relojes distintos aunque sea el mismo paso.
	if entradas[id].paso == paso and entradas[id].get("estado", "") == r.estado and visto < float(entradas[id].get("visto", -1.0)):
		return
	var piso: int = r.participantes.find(id)
	entradas[id] = {"pos": cursor, "pulsa": pulsado, "cuando": reloj, "secuencia": orden, "paso": paso, "visto": visto, "estado": r.estado,
		"dentro": contiene_cursor(paso, piso, visto if r.estado == "ritmo" else 0.0, cursor)}

func contiene_cursor(paso: int, piso: int, tiempo_visto: float, cursor: Vector2) -> bool:
	var p := clampf((tiempo_visto - aviso()) / duracion(), 0, 1)
	return ((cursor - objetivo(paso, piso, p)) * LIENZO).length() <= radio() + BORDE

## El número de oseznos rescatados ya se replica: todos usan el mismo reto,
## incluso después de cargar una partida o reintentar el segundo osezno.
func segundo() -> bool:
	return get_parent().rescatados >= 1

func aviso() -> float:
	return 0.8 if segundo() else 0.9

func duracion() -> float:
	return 1.35 if segundo() else 1.5

func radio() -> float:
	return 40.0 if segundo() else 44.0

func tipo(paso: int) -> int:
	return [1, 2, 3, 1, 3, 2][paso % PASOS] if segundo() else paso % 3

func objetivo(paso: int, _piso: int, progreso: float) -> Vector2:
	var u := clampf(progreso, 0, 1)
	var p: Vector2
	# El segundo cambia orden, sentido y altura, y añade curvas en S.
	var v := 1.0 - u if segundo() else u
	match tipo(paso):
		0: # Círculo: sostener sin salir hasta que cierre el anillo.
			p = Vector2(280 if paso == 0 else 680, 320 if paso == 0 else 425)
		1: # Deslizador curvo.
			var a := Vector2(260, 440) if paso == 1 else Vector2(680, 280)
			var b := Vector2(660, 300) if paso == 1 else Vector2(300, 430)
			p = a.lerp(b, v) + Vector2(0, sin(v * PI) * (-65 if paso == 1 else 65))
		2: # Vuelta completa: el segundo invierte el giro y parte desde arriba.
			var angulo := v * TAU - (PI * 0.5 if segundo() else 0.0)
			p = Vector2(480, 350) + Vector2(cos(angulo), sin(angulo)) * (75 if segundo() else 65)
		_: # Dos cambios de dirección suaves, sin esquinas imposibles de seguir.
			p = Vector2(330 + 300 * v, 350 + sin(v * TAU) * 55)
			if paso == 4:
				p = Vector2(960 - p.x, 700 - p.y)
	if segundo() and tipo(paso) == 1:
		p.y = 700 - p.y
	# Todos ven el mismo recorrido; cada cursor conserva su validación individual.
	return p / LIENZO

func progreso() -> float:
	var r := get_parent()
	return clampf((r.tiempo - aviso()) / duracion(), 0, 1) if r.estado == "ritmo" else 0.0

func progreso_mostrado() -> float:
	return clampf((_tiempo_mostrado - aviso()) / duracion(), 0, 1) if _estado_mostrado == "ritmo" else 0.0

func _physics_process(delta: float) -> void:
	if not _conectado() or not multiplayer.is_server():
		return
	reloj += delta
	var r := get_parent()
	if r.estado != "ritmo":
		return
	var peor := 0.0
	for piso in r.participantes.size():
		var id: int = r.participantes[piso]
		var dato: Dictionary = entradas.get(id, {})
		var fresco: bool = not dato.is_empty() and reloj - dato.cuando < 0.4 and dato.paso == r.paso
		var pulsa: bool = fresco and dato.pulsa
		# Juzgar cada muestra contra el círculo que se veía al enviarla. No volver
		# a comparar un cursor viejo contra un círculo que ya avanzó entre paquetes.
		var dentro: bool = pulsa and dato.get("dentro", false)
		var trazando: bool = r.tiempo >= aviso()
		# Entre objetivos (mientras se cierra el anillo) se puede soltar el clic;
		# solo cuenta como error salirse o soltar ya trazando, con un respiro
		# para volver a picar justo cuando arranca.
		if trazando and not dentro and r.tiempo >= aviso() + GRACIA_INICIO:
			errores[id] = float(errores[id]) + delta
		else:
			errores[id] = 0.0
		if trazando and dentro:
			cubierto[id] = float(cubierto[id]) + delta
		r.avances[piso] = clampf(float(cubierto[id]) / duracion(), 0, 1)
		peor = maxf(peor, float(errores[id]) / TOLERANCIA)
		if errores[id] >= TOLERANCIA:
			r._fallar(true, [id])
			return
	r.miedo = peor
	r.calma = (r.paso + progreso()) / PASOS
	if r.tiempo >= aviso() + duracion():
		var fallidos: Array = r.participantes.filter(func(id): return float(cubierto.get(id, 0.0)) < duracion() * 0.8)
		if not fallidos.is_empty():
			r._fallar(true, fallidos)
			return
		if r.paso == PASOS - 1:
			r.completar_reto()
		else:
			r.paso += 1
			r.tiempo = 0.0
			for id in r.participantes:
				errores[id] = 0.0
				cubierto[id] = 0.0

func _soltar() -> void:
	_pulsado = false

func _notification(que: int) -> void:
	if que == NOTIFICATION_PAUSED:
		_soltar()
	elif que == NOTIFICATION_UNPAUSED and is_inside_tree() and _conectado() and multiplayer.is_server():
		var r := get_parent()
		if r.estado in ["preparando", "ritmo"]:
			# La pausa puede soltar el mouse: repetir el objetivo actual con aviso.
			r.estado = "preparando"
			r.tiempo = 0.0
			iniciar()

func _input(evento: InputEvent) -> void:
	if not _conectado() or get_tree().paused:
		return
	var r := get_parent()
	if not r.contiene(multiplayer.get_unique_id()) or r.estado not in ["preparando", "ritmo"]:
		return
	if evento is InputEventMouse:
		_cursor = (evento.position - _vista.position) / _vista.scale / LIENZO
		_cursor = _cursor.clamp(Vector2.ZERO, Vector2.ONE)
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
			_pulsado = evento.pressed
		elif evento is InputEventMouseMotion:
			_pulsado = (evento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not _conectado():
		_vista.hide()
		return
	var r := get_parent()
	var yo := multiplayer.get_unique_id()
	var piso: int = r.participantes.find(yo)
	_vista.visible = piso >= 0 and r.estado in ["preparando", "ritmo"]
	if not _vista.visible:
		return
	var tamano := get_viewport().get_visible_rect().size
	_vista.scale = Vector2.ONE * minf(tamano.x / LIENZO.x, tamano.y / LIENZO.y)
	_vista.position = (tamano - LIENZO * _vista.scale) * 0.5
	if _intento != r.encuentro:
		_intento = r.encuentro
		_pulsado = false
		secuencia = 0
	_envio += delta
	if _envio >= 0.04 and _encuentro_mostrado == r.encuentro and _paso_mostrado == r.paso and _estado_mostrado == r.estado:
		_envio = 0.0
		secuencia += 1
		var j: Node = r._jugador(yo)
		var cursor := objetivo(r.paso, piso, progreso_mostrado()) if j != null and not j._bot.is_empty() else _cursor
		var pulsa: bool = true if j != null and not j._bot.is_empty() else _pulsado
		if multiplayer.is_server():
			mover(r.encuentro, r.paso, secuencia, cursor, pulsa, _tiempo_mostrado)
		else:
			mover.rpc_id(1, r.encuentro, r.paso, secuencia, cursor, pulsa, _tiempo_mostrado)
	var titulo := "OSEZNO 2 · MÁS RÁPIDO" if segundo() else "OSEZNO 1"
	_texto.text = titulo + (" · PREPÁRATE %d\nCuando se cierre el anillo, mantén clic y síguelo" % maxi(1, ceili(PREPARACION - r.tiempo)) if r.estado == "preparando" else "\nOBJETIVO %d / %d · %s" % [r.paso + 1, PASOS, ["SOSTÉN", "SIGUE LA CURVA", "DA LA VUELTA", "SIGUE LA S"][tipo(r.paso)]])
	_texto.add_theme_color_override("font_color", TemaUI.AMBAR if r.estado == "preparando" else TemaUI.CREMA)
	_estado.text = "Mantén clic mientras sigues el círculo · Entre objetivos puedes soltar · Si uno falla, ¡caen todos!"
	for i in 3:
		var hay: bool = i < r.participantes.size()
		_nombres[i].get_parent().visible = hay
		if hay:
			var j: Node = r._jugador(r.participantes[i])
			var color: Color = j.COLORES[j.color_indice % j.COLORES.size()] if j else Color.WHITE
			_nombres[i].text = "%s · %d%%" % [j.nombre if j else "Compa", roundi(float(r.avances[i]) * 100)]
			_nombres[i].add_theme_color_override("font_color", color.lightened(0.3))
			_barras[i].value = float(r.avances[i])
	# Arriba (donde va la misión, que se oculta durante el reto) y abajo, centrados.
	_caja_texto.reset_size()
	_caja_estado.reset_size()
	_caja_texto.position = Vector2((LIENZO.x - _caja_texto.size.x) * 0.5, 96)
	_caja_estado.position = Vector2((LIENZO.x - _caja_estado.size.x) * 0.5, LIENZO.y - _caja_estado.size.y - 14)
	# Estos datos corresponden al círculo que se dibuja ahora y verá el usuario
	# antes del siguiente envío; no atribuir su cursor al siguiente cuadro.
	_tiempo_mostrado = r.tiempo
	_paso_mostrado = r.paso
	_encuentro_mostrado = r.encuentro
	_estado_mostrado = r.estado
	_vista.queue_redraw()

func _dibujar() -> void:
	var r := get_parent()
	var piso: int = r.participantes.find(multiplayer.get_unique_id())
	if piso < 0:
		return
	var color := Color("59e5ef")
	var ancho := radio()
	var puntos := PackedVector2Array()
	for n in 49:
		puntos.append(objetivo(r.paso, piso, n / 48.0) * LIENZO)
	if tipo(r.paso) != 0:
		_vista.draw_polyline(puntos, Color(0.02, 0.05, 0.08, 0.8), ancho * 2, true)
		_vista.draw_polyline(puntos, Color(color, 0.55), 4, true)
	var centro := objetivo(r.paso, piso, progreso()) * LIENZO
	_vista.draw_circle(centro, ancho, Color(0.02, 0.05, 0.08, 0.8))
	_vista.draw_arc(centro, ancho, 0, TAU, 64, color, 4, true)
	_vista.draw_circle(centro, 8, Color.WHITE)
	var espera: float = clampf(1.0 - r.tiempo / aviso(), 0, 1) if r.estado == "ritmo" else 1.0
	if espera > 0:
		_vista.draw_arc(centro, ancho + 65 * espera, 0, TAU, 64, Color.WHITE, 2, true)
	else:
		_vista.draw_arc(centro, ancho + 8, -PI * 0.5, -PI * 0.5 + TAU * progreso(), 64, Color("8cff8c"), 4, true)
	_vista.draw_string(ThemeDB.fallback_font, centro + Vector2(-9, -16), str(r.paso + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	if r.paso < PASOS - 1:
		var siguiente := objetivo(r.paso + 1, piso, 0) * LIENZO
		_vista.draw_arc(siguiente, 22, 0, TAU, 32, Color(color, 0.4), 2, true)
		_vista.draw_string(ThemeDB.fallback_font, siguiente + Vector2(-6, 6), str(r.paso + 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(color, 0.6))
	if _cursor != Vector2.ZERO:
		var acertando := contiene_cursor(r.paso, piso, r.tiempo if r.estado == "ritmo" else 0.0, _cursor)
		var color_cursor := Color("8cff8c") if acertando else Color("ff7766")
		_vista.draw_arc(_cursor * LIENZO, 12, 0, TAU, 24, color_cursor if _pulsado else Color.WHITE, 2, true)
