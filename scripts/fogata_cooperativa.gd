extends Node2D
## Inventario, colocación y fricción de dos jugadores. Autoridad única del servidor.
const RADIO := 85.0
const TIEMPO := 35.0
const PREPARACION := 2.0
const RECORRIDO := 60.0
const RITMO := 0.9
const TRAZO_MIN := 0.18
const TRAZO_MAX := 0.9
const SINCRONIA := 0.28
const COMPAS := 0.4
const CALENTAR := 8.0
const ENFRIAR := 0.05
const PALO := preload("res://scripts/palo_fogata.gd")
## Brazos de borracho: se tambalean solos hacia arriba y abajo (deriva de -1 a
## 1). Con clic sostenido quedan firmes (se mueven FIRMEZA veces menos y vuelven
## poco a poco al centro) y el mouse arriba/abajo los acomoda. Si la deriva pasa
## de FUERA, las palmas no tocan el palo y frotar no calienta.
const TAMBALEO := 1.1
const FIRMEZA := 0.35
const VOLVER := 0.5
const CORREGIR := 1.0 / 110.0
const FUERA := 0.7
var inventario := {}
var suelo := {}
var colocados := 0
var encendida := false
var participantes: Array = []
var espectadores: Array = []
var encuentro := 0
var calor := 0.0
var tiempo := TIEMPO
var preparacion := 0.0
var mensaje := "Golpeen árboles y recojan dos palos con E"
var gestos := [0.0, 0.0]
var ritmo := [false, false]
var consejos := ["Sigue el ritmo", "Sigue el ritmo"]
## 1 si las palmas de cada compa están sobre el palo, 0 si se salieron.
var agarres := [1.0, 1.0]
## Qué tan desviados están los brazos de cada compa (-1 arriba, 1 abajo).
var derivas := [0.0, 0.0]
var _vaiven := [0.0, 0.0]
var _rumbo := [0.0, 0.0]
var _cambio := [0.0, 0.0]
## Con false los brazos no se tambalean (las pruebas de ritmo lo apagan).
var tambaleo := true
var _mov := {}
var _reloj := 0.0
var _pareja := -10.0
var _replica := 0.0
var _numero := 0
var _dibujos := {}
var _posiciones := {}
var vista: CanvasLayer


func _ready() -> void:
	add_to_group("fogata_cooperativa")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	vista = preload("res://scripts/fogata_vista.gd").new()
	vista.name = "VistaFogata"
	add_child(vista)
	multiplayer.peer_disconnected.connect(_desconectado)


func cantidad(id: int) -> int:
	return int(inventario.get(id, 0))


func dentro(id: int) -> bool:
	return id in participantes or id in espectadores


func faltan_palos() -> bool:
	if not habilitada():
		return false
	var cuantos := colocados + suelo.size()
	for numero in inventario.values():
		cuantos += int(numero)
	return not encendida and cuantos < 2 and not _partida().finalizada


func crear_palo(donde: Vector2) -> void:
	if not multiplayer.is_server() or not faltan_palos():
		return
	_numero += 1
	suelo[_numero] = donde
	_publicar()


func habilitada() -> bool:
	var rescate := get_tree().get_first_node_in_group("rescate_oseznos")
	return rescate == null or rescate.listo()


func _jugador(id: int) -> Node2D:
	return get_parent().get_parent().get_node_or_null("Jugadores/%d" % id)


func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")


func _apto(j: Node2D) -> bool:
	return j != null and not j.caido and j.aturdimiento <= 0 and j.bebiendo <= 0 \
		and j.dormido <= 0 and j.vomitando <= 0 and j.nausea <= 0 and j.rodando <= 0 \
		and j.altura <= 12 and j.apoyo_id == 0 and j._torre().encima(j) == null \
		and j._pieza_cargada() == null and not j.en_forcejeo() and not j.combate.volando \
		and not j.nadando() and not _partida().finalizada


## La llama pedir_agarrar, que ya comprobó la identidad del dueño.
func interactuar(j: Node2D) -> bool:
	if not multiplayer.is_server() or get_tree().paused:
		return false
	if not habilitada():
		if j.global_position.distance_to(global_position) <= RADIO:
			j._avisar_bebida.rpc("Primero rescaten a los dos oseznos del árbol")
			return true
		return false
	var id := j.name.to_int()
	if dentro(id):
		salir(id)
		return true
	if not _apto(j):
		return false
	if not encendida and j.global_position.distance_to(global_position) <= RADIO:
		if cantidad(id) > 0 and colocados < 2:
			var numero := mini(2 - colocados, cantidad(id))
			colocados += numero
			inventario[id] = cantidad(id) - numero
			mensaje = "Dos jugadores: pulsen E para encender" if colocados == 2 else "Falta colocar un palo"
			_publicar()
			return true
		if colocados == 2:
			j.cancelar_entrada_pausa()
			j.combo.reiniciar()
			j._cancelar_golpes()
			if participantes.size() < 2:
				participantes.append(id)
				mensaje = "Esperando al segundo jugador"
				if participantes.size() == 2:
					_empezar()
			else:
				espectadores.append(id)
			_publicar()
			return true
	if cantidad(id) < 2:
		var mejor := -1
		var distancia := 65.0
		for numero in suelo:
			var d: float = j.global_position.distance_to(suelo[numero])
			if d < distancia:
				distancia = d
				mejor = numero
		if mejor != -1:
			inventario[id] = cantidad(id) + 1
			suelo.erase(mejor)
			_publicar()
			return true
	return false


func _empezar() -> void:
	encuentro += 1
	_pareja = -10.0
	calor = 0
	tiempo = TIEMPO
	preparacion = PREPARACION
	_mov.clear()
	gestos = [0.0, 0.0]
	ritmo = [false, false]
	agarres = [1.0, 1.0]
	derivas = [0.0, 0.0]
	_vaiven = [0.0, 0.0]
	consejos = ["Mantén clic para tener firmes los brazos", "Mantén clic para tener firmes los brazos"]
	for id in participantes:
		_mov[id] = {"sentido": 0, "recorrido": 0.0, "completado": 0,
			"trazo": -10.0, "ultimo": -10.0, "paquete": -10.0, "pulsado": false}
	mensaje = "Mantengan clic para tener firmes los brazos y froten en su dirección"


@rpc("any_peer", "call_remote", "unreliable_ordered")
func mover(numero: int, desplazamiento: Vector2, pulsado: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = multiplayer.get_unique_id()
	if not multiplayer.is_server() or get_tree().paused or _partida().finalizada \
			or numero != encuentro or participantes.size() != 2 or id not in participantes \
			or preparacion > 0 or encendida or not desplazamiento.is_finite():
		return
	var j := _jugador(id)
	if not _apto(j) or j.global_position.distance_to(global_position) > RADIO + 10:
		return
	var m: Dictionary = _mov[id]
	m.pulsado = pulsado
	if not pulsado:
		m.recorrido = 0.0
		m.trazo = -10.0
		return
	if _reloj - m.paquete < 0.025:
		return
	m.paquete = _reloj
	var rol := participantes.find(id)
	# Mover el mouse arriba/abajo acomoda los brazos sobre el palo.
	derivas[rol] = clampf(float(derivas[rol]) + desplazamiento.y * CORREGIR, -1, 1)
	# Con los brazos fuera del palo no hay roce.
	if absf(derivas[rol]) >= FUERA:
		m.recorrido = 0.0
		m.trazo = -10.0
		consejos[rol] = "¡Endereza los brazos! (arriba/abajo)"
		return
	# Los dos frotan en horizontal (cada uno del lado contrario del palo).
	var principal := desplazamiento.x
	var otro := desplazamiento.y
	if absf(principal) < 2 and absf(otro) < 2:
		return
	if absf(principal) < absf(otro) * 1.5:
		m.recorrido = 0.0
		m.trazo = -10.0
		consejos[rol] = "Sigue tu eje"
		return
	var sentido := int(signf(principal))
	if sentido != m.sentido:
		m.sentido = sentido
		m.recorrido = 0.0
	# Una trayectoria enorme o cien paquetes en un frame no generan cien roces.
	var distancia := minf(absf(principal), 40.0)
	m.recorrido += distancia
	gestos[rol] = clampf(float(gestos[rol]) + sentido * distancia / 120.0, -1, 1)
	if m.recorrido >= RECORRIDO and sentido != m.completado:
		var intervalo: float = _reloj - m.ultimo
		var primero: bool = m.ultimo < 0
		m.completado = sentido
		m.ultimo = _reloj
		m.recorrido = 0.0
		m.trazo = -10.0
		if primero:
			consejos[rol] = "Ahora vuelve"
		elif intervalo < TRAZO_MIN:
			consejos[rol] = "Más despacio"
		elif intervalo > TRAZO_MAX:
			consejos[rol] = "Más rápido"
		else:
			m.trazo = _reloj
			consejos[rol] = "Buen ritmo"


func salir(id: int) -> void:
	if not multiplayer.is_server():
		return
	if id in participantes:
		_cancelar("Se interrumpió: pulsen E entre dos para reintentar")
	elif id in espectadores:
		espectadores.erase(id)
		_publicar()


func limpiar_gesto(id: int) -> void:
	if multiplayer.is_server() and _mov.has(id):
		_pareja = -10.0
		_mov[id].pulsado = false
		_mov[id].trazo = -10.0
		_mov[id].recorrido = 0.0
		_mov[id].ultimo = -10.0
		_mov[id].completado = 0


func _cancelar(texto: String) -> void:
	participantes.clear()
	espectadores.clear()
	_mov.clear()
	calor = 0
	preparacion = 0
	ritmo = [false, false]
	mensaje = texto
	_publicar()


func _desconectado(id: int) -> void:
	if not multiplayer.is_server():
		return
	salir(id)
	for i in range(cantidad(id)):
		_numero += 1
		suelo[_numero] = _posiciones.get(id, global_position) + Vector2(i * 24, 20)
	inventario.erase(id)
	_publicar()


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_reloj += delta
	for j in get_tree().get_nodes_in_group("jugadores"):
		_posiciones[j.name.to_int()] = j.global_position
	if _partida().finalizada:
		if not participantes.is_empty() or not espectadores.is_empty():
			_cancelar("Partida terminada")
		return
	for id in participantes.duplicate() + espectadores.duplicate():
		var j := _jugador(id)
		if not _apto(j) or j.global_position.distance_to(global_position) > RADIO + 10:
			salir(id)
	if participantes.size() != 2 or encendida:
		return
	preparacion = maxf(preparacion - delta, 0)
	_apretar(delta)
	if preparacion <= 0:
		tiempo = maxf(tiempo - delta, 0)
		for rol in range(2):
			var m: Dictionary = _mov[participantes[rol]]
			ritmo[rol] = m.pulsado and float(agarres[rol]) >= 1.0 and _reloj - m.trazo < RITMO
		if ritmo[0] and ritmo[1]:
			var a: float = _mov[participantes[0]].trazo
			var b: float = _mov[participantes[1]].trazo
			if absf(a - b) <= SINCRONIA:
				_pareja = minf(a, b)
		var juntos := coordinados()
		mensaje = "¡Juntos!" if juntos else "Acompasen los movimientos"
		calor = clampf(calor + delta * (1.0 / CALENTAR if juntos else -ENFRIAR), 0, 1)
		if calor >= 1:
			encendida = true
			participantes.clear()
			espectadores.clear()
			mensaje = "¡Fuego encendido! Ya pueden preparar la papilla"
			_publicar()
			return
		if tiempo <= 0:
			_cancelar("Se enfrió: vuelvan a pulsar E entre dos")
			return
	_replica += delta
	if _replica >= 0.1:
		_replica = 0
		_publicar()


# Brazos de borracho: se tambalean solos; con clic sostenido se mueven menos y
# vuelven poco a poco al centro.
func _apretar(delta: float) -> void:
	for rol in range(2):
		var m: Dictionary = _mov[participantes[rol]]
		if tambaleo:
			# Cambia de rumbo cada tanto (un borracho se va de lado un rato).
			_cambio[rol] -= delta
			if _cambio[rol] <= 0.0:
				_cambio[rol] = randf_range(0.7, 1.5)
				_rumbo[rol] = randf_range(-1, 1) * TAMBALEO
			_vaiven[rol] = lerpf(_vaiven[rol], _rumbo[rol], delta * 2.0)
			var firme := FIRMEZA if m.pulsado else 1.0
			derivas[rol] = clampf(float(derivas[rol]) + float(_vaiven[rol]) * firme * delta, -1, 1)
		if m.pulsado:
			derivas[rol] = move_toward(float(derivas[rol]), 0.0, VOLVER * delta * absf(derivas[rol]))
		agarres[rol] = 1.0 if absf(derivas[rol]) < FUERA else 0.0


func coordinados() -> bool:
	if participantes.size() != 2 or not ritmo[0] or not ritmo[1]:
		return false
	# Conservar el último par completo durante el siguiente vaivén evita parpadeos por latencia.
	if multiplayer.is_server():
		return _reloj - _pareja < TRAZO_MAX
	return mensaje == "¡Juntos!"


func _publicar() -> void:
	_sincronizar.rpc(inventario, suelo, colocados, encendida, participantes, espectadores,
		encuentro, calor, tiempo, preparacion, mensaje, gestos, ritmo, consejos, agarres, derivas)


@rpc("authority", "call_local", "reliable")
func _sincronizar(bolsa: Dictionary, palos: Dictionary, puestos: int, fuego: bool,
		actores: Array, mirones: Array, numero: int, avance: float, segundos: float,
		previa: float, texto: String, posiciones: Array, activos: Array, indicaciones: Array,
		palmas: Array = [1.0, 1.0], desvios: Array = [0.0, 0.0]) -> void:
	inventario = bolsa.duplicate()
	suelo = palos.duplicate()
	colocados = puestos
	encendida = fuego
	participantes = actores.duplicate()
	espectadores = mirones.duplicate()
	encuentro = numero
	calor = avance
	tiempo = segundos
	preparacion = previa
	mensaje = texto
	gestos = posiciones.duplicate()
	ritmo = activos.duplicate()
	consejos = indicaciones.duplicate()
	agarres = palmas.duplicate()
	derivas = desvios.duplicate()
	for id in _dibujos.keys():
		if not suelo.has(id):
			_dibujos[id].queue_free()
			_dibujos.erase(id)
	for id in suelo:
		if not _dibujos.has(id):
			var palo := PALO.new()
			get_parent().get_parent().add_child(palo)
			palo.global_position = suelo[id]
			_dibujos[id] = palo
	queue_redraw()


func _draw() -> void:
	if encendida:
		return
	draw_arc(Vector2.ZERO, 43, 0, TAU, 20, Color(0.9, 0.75, 0.4, 0.55), 2)
	for i in range(colocados):
		var a := Vector2(-27, -8 + i * 15)
		var b := Vector2(27, 5 - i * 15)
		draw_line(a, b, Color("29180f"), 8)
		draw_line(a, b, Color("ad7742"), 4)
