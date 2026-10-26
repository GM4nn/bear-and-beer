extends Node2D
## Búsqueda compartida dentro de la carpa. Solo el servidor mueve y adjudica objetos.
const LIENZO := Vector2(1280, 720)
const RADIO := 115.0
## Más difícil: pilas más bajas que se caen más rápido, más cachivaches y ollas
## rotas de señuelo (llevar una rota a la salida no cuenta).
const LIMITE_PILA := 6
const AVISO_CAIDA := 1.5
const CACHIVACHES := 34
const SENUELOS := 2
## Tipo de dibujo de la olla rota (señuelo); ver busqueda_olla_vista.gd.
const TIPO_ROTA := 7
const DANO := 12
const SALIDA := Rect2(540, 160, 200, 85)
var conseguida := false
var estado := "esperando"
var participantes: Array = []
var encuentro := 0
var objetos: Array = []
var manos := {}
var aportes := {}
var pilas := [0, 0]
var riesgo := [0.0, 0.0]
var tiempo := 0.0
var lado_caida := -1
var mensaje := "Vuelvan todos a la tienda y pulsen E para buscar la olla"
var _entradas := {}
var _reloj := 0.0
var _golpe_interno := false
var vista: CanvasLayer
var _replica := 0.0

func _ready() -> void:
	add_to_group("busqueda_olla")
	process_physics_priority = 16
	vista = preload("res://scripts/busqueda_olla_vista.gd").new()
	vista.name = "Vista"
	add_child(vista)

func _process(delta: float) -> void:
	if not multiplayer.is_server() or multiplayer.get_peers().is_empty():
		return
	_replica += delta
	if _replica < 0.05:
		return
	_replica = 0.0
	var datos := {}
	for clave in ["conseguida", "estado", "participantes", "encuentro", "objetos", "manos", "aportes", "pilas", "riesgo", "tiempo", "lado_caida", "mensaje"]:
		datos[clave] = get(clave)
	# Una instantánea atómica y comprimida: el montón supera el límite MTU de
	# MultiplayerSynchronizer. ENet fragmenta este RPC fiable cuando hace falta.
	_recibir.rpc(var_to_bytes(datos).compress(FileAccess.COMPRESSION_DEFLATE))

@rpc("authority", "call_remote", "reliable")
func _recibir(paquete: PackedByteArray) -> void:
	if multiplayer.is_server():
		return
	var datos: Dictionary = bytes_to_var(paquete.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE))
	for clave in ["conseguida", "estado", "participantes", "encuentro", "objetos", "manos", "aportes", "pilas", "riesgo", "tiempo", "lado_caida", "mensaje"]:
		set(clave, datos[clave])

func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")

func jugador(id: int) -> Node2D:
	return get_parent().get_node_or_null("Jugadores/%d" % id)

func lugar() -> Vector2:
	return get_parent().get_node("Carpa").position + Vector2(0, 65)

func habilitada() -> bool:
	return _partida().rescate.listo() and get_tree().get_first_node_in_group("estacion").fogata.encendida

func dentro(id: int) -> bool:
	return id in participantes

func apto(j: Node2D) -> bool:
	return j != null and j.vida > 0 and not j.caido and j.aturdimiento <= 0 and j.altura <= 1 and j.apoyo_id == 0 and j._torre().encima(j) == null and j._pieza_cargada() == null and j.bebiendo <= 0 and j.dormido <= 0 and j.vomitando <= 0 and j.nausea <= 0 and j.rodando <= 0 and not j.combate.volando and not j.en_forcejeo() and not j.en_fogata() and not j.en_rescate()

func interactuar(j: Node2D) -> bool:
	if not multiplayer.is_server() or get_tree().paused or _partida().finalizada:
		return false
	var id := j.name.to_int()
	if dentro(id):
		cancelar("Un compa salió. Vuelvan a entrar todos con E")
		return true
	if conseguida or j.position.distance_to(lugar()) > RADIO:
		return false
	if not habilitada():
		j._avisar_bebida.rpc("Primero rescaten a los oseznos y enciendan la fogata")
		return true
	if j._pieza_cargada() != null:
		return false # Permitir soltar lo que lleva antes de entrar.
	if not apto(j):
		j._avisar_bebida.rpc("Acércate a pie y con las manos libres")
		return true
	if estado != "esperando" or not Red.jugadores.has(id):
		return true
	if participantes.is_empty():
		encuentro += 1
	participantes.append(id)
	manos[id] = {"pos": Vector2(200 + participantes.size() * 120, 590), "objeto": -1, "dolor": 0.0, "offset": Vector2.ZERO}
	j.cancelar_entrada_pausa()
	j._cancelar_golpes()
	j.combo.reiniciar()
	for otro in Red.jugadores:
		var compa := jugador(otro)
		if compa == null or compa.caido:
			mensaje = "Primero revivan a todos: nadie se queda fuera"
			return true
	if participantes.size() == Red.jugadores.size() and participantes.size() >= 2:
		_empezar()
	else:
		mensaje = "Esperando al equipo: %d/%d dentro · cada compa pulsa E" % [participantes.size(), Red.jugadores.size()]
	return true

func _empezar() -> void:
	estado = "buscando"
	tiempo = 0.0
	_entradas.clear()
	aportes.clear()
	for id in participantes:
		aportes[id] = false
		_entradas[id] = {"seq": -1, "pulsa": false, "cuando": -100.0, "movimiento": -100.0, "pos": manos[id].pos, "vel": Vector2.ZERO, "offset": Vector2.ZERO}
	_desordenar()
	mensaje = "¡Los compas dejaron esto hecho un desmadre!"

func _desordenar() -> void:
	objetos.clear()
	pilas = [0, 0]
	riesgo = [0.0, 0.0]
	lado_caida = -1
	# La olla queda debajo de los objetos, nunca seleccionable a través de ellos.
	# Es más chica y puede quedar en cualquier parte del montón.
	objetos.append({"tipo": 0, "pos": Vector2(randf_range(500, 780), randf_range(345, 480)), "tam": Vector2(100, 74), "dueno": 0, "lado": -1, "vel": Vector2.ZERO, "vuelo": 0.0, "lanzador": 0})
	var huecos: Array = []
	for i in CACHIVACHES:
		huecos.append(Vector2(430 + (i % 6) * 84 + randf_range(-20, 20), 310 + (i / 6) * 34 + randf_range(-14, 14)))
	huecos.shuffle()
	for i in CACHIVACHES:
		var tipo := 1 + i % 6
		var tam := Vector2(145, 95)
		# Dos ollas rotas parecidas a la buena, revueltas en el montón.
		if i < SENUELOS:
			tipo = TIPO_ROTA
			tam = Vector2(100, 74)
		objetos.append({"tipo": tipo, "pos": huecos[i], "tam": tam, "dueno": 0, "lado": -1, "vel": Vector2.ZERO, "vuelo": 0.0, "lanzador": 0})
	for id in manos:
		manos[id].objeto = -1

func rect_objeto(indice: int) -> Rect2:
	var o: Dictionary = objetos[indice]
	return Rect2(o.pos - o.tam * 0.5, o.tam)

func libre() -> bool:
	if objetos.is_empty():
		return false
	var area := rect_objeto(0).grow(-10)
	for i in range(1, objetos.size()):
		if rect_objeto(i).intersects(area):
			return false
	return true

func seleccionar(punto: Vector2) -> int:
	# Un objeto agarrado se dibuja por encima del resto y no puede robarse.
	for o in objetos:
		if o.dueno != 0 and Rect2(o.pos - o.tam * 0.5, o.tam).has_point(punto):
			return -1
	for i in range(objetos.size() - 1, -1, -1):
		if rect_objeto(i).has_point(punto):
			return i if i != 0 or libre() else -1
	return -1

@rpc("any_peer", "call_remote", "reliable")
func mover(numero: int, secuencia: int, punto: Vector2, pulsa: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = multiplayer.get_unique_id()
	if not multiplayer.is_server() or get_tree().paused or estado != "buscando" or _partida().finalizada or numero != encuentro or not _entradas.has(id):
		return
	if not punto.is_finite() or not Rect2(Vector2.ZERO, LIENZO).has_point(punto) or secuencia <= _entradas[id].seq:
		return
	var e: Dictionary = _entradas[id]
	var dt := clampf(_reloj - float(e.cuando), 0.016, 0.12)
	var nueva: Vector2 = Vector2(manos[id].pos).move_toward(punto, 1800.0 * dt)
	var desplazamiento := nueva - Vector2(manos[id].pos)
	if desplazamiento.length() > 0.5:
		e.vel = desplazamiento / dt
		e.movimiento = _reloj
	elif _reloj - float(e.movimiento) > 0.12:
		e.vel = Vector2.ZERO
	e.pos = nueva
	e.cuando = _reloj
	e.seq = secuencia
	manos[id].pos = nueva
	if manos[id].dolor > 0:
		e.pulsa = false
		return
	if pulsa and not e.pulsa:
		var indice := seleccionar(nueva)
		if indice >= 0:
			objetos[indice].dueno = id
			objetos[indice].lado = -1
			objetos[indice].vuelo = 0.0
			manos[id].objeto = indice
			e.offset = Vector2(objetos[indice].pos) - nueva
			manos[id].offset = e.offset
	var agarrado: int = manos[id].objeto
	if agarrado >= 0:
		objetos[agarrado].pos = (nueva + Vector2(e.offset)).clamp(Vector2(80, 180), Vector2(1200, 600))
		if not pulsa:
			_soltar(id, true)
	e.pulsa = pulsa

func _soltar(id: int, lanzar: bool) -> void:
	var indice: int = manos[id].objeto
	if indice < 0:
		return
	var o: Dictionary = objetos[indice]
	o.dueno = 0
	manos[id].objeto = -1
	if indice == 0 and lanzar and SALIDA.has_point(o.pos):
		if aportes.values().all(func(v): return v):
			_ganar()
			return
		mensaje = "Todos deben ayudar: cada compa aparta al menos un objeto"
	if indice != 0 and lanzar and o.tipo == TIPO_ROTA and SALIDA.has_point(o.pos):
		mensaje = "¡Esa olla está rota! Busquen la buena"
	if indice != 0 and lanzar:
		o.lanzador = id
		o.vel = Vector2(_entradas[id].vel).limit_length(1100)
		o.vuelo = 0.25
		# Aportar exige sacar el objeto del montón central, no solo hacer clic.
		if o.pos.x < 340 or o.pos.x > 940:
			aportes[id] = true
	else:
		o.vel = Vector2.ZERO
		o.vuelo = 0.0

func zona_caida(lado: int) -> Rect2:
	return Rect2(55 if lado == 0 else 865, 240, 360, 400)

func origen_brazo(id: int) -> Vector2:
	var i := participantes.find(id)
	return Vector2(100 + (i + 0.5) * 1080.0 / max(1, participantes.size()), 760)

func bajo_pila(id: int, lado: int) -> bool:
	var zona := zona_caida(lado)
	var punto: Vector2 = manos[id].pos
	var origen := origen_brazo(id)
	if zona.has_point(punto):
		return true
	var esquinas := [zona.position, Vector2(zona.end.x, zona.position.y), zona.end, Vector2(zona.position.x, zona.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(origen, punto, esquinas[i], esquinas[(i + 1) % 4]) != null:
			return true
	return false

func _derrumbar(lado: int) -> void:
	estado = "derrumbe"
	tiempo = 0.0
	lado_caida = lado
	mensaje = "¡Se vino todo encima! Retiren las manos y vuelvan a buscar"
	for id in participantes:
		_soltar(id, false)
		_entradas[id].pulsa = false
		if bajo_pila(id, lado):
			manos[id].dolor = 1.4
			_golpe_interno = true
			jugador(id)._perder_vida(DANO)
			_golpe_interno = false
	for i in objetos.size():
		objetos[i].origen = objetos[i].pos
		objetos[i].destino = Vector2(randf_range(510, 770), randf_range(345, 495))
	# Una caída mortal obliga a salir y revivir; jamás se continúa sin un compa.
	if participantes.any(func(id): return jugador(id).caido):
		cancelar("Revivan al compa herido y vuelvan a entrar todos")

func _ganar() -> void:
	conseguida = true
	estado = "encontrada"
	tiempo = 0.0
	mensaje = "¡Encontraron la olla! Llévenla a la fogata"
	for id in manos:
		manos[id].objeto = -1
	for o in objetos:
		o.dueno = 0
	get_parent().get_node("Olla").soltar(lugar() + Vector2(75, 15))

func cancelar(texto := "Búsqueda interrumpida. Vuelvan a entrar todos con E") -> void:
	if not multiplayer.is_server():
		return
	participantes.clear()
	_entradas.clear()
	manos.clear()
	objetos.clear()
	aportes.clear()
	pilas = [0, 0]
	riesgo = [0.0, 0.0]
	estado = "esperando"
	mensaje = texto

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or multiplayer.multiplayer_peer == null:
		return
	_reloj += delta
	if participantes.is_empty():
		return
	if _partida().finalizada or not habilitada() or participantes.any(func(id): return not Red.jugadores.has(id) or not apto(jugador(id)) or jugador(id).position.distance_to(lugar()) > RADIO):
		cancelar()
		return
	if estado != "esperando" and participantes.size() != Red.jugadores.size():
		cancelar()
		return
	tiempo += delta
	if estado == "encontrada":
		if tiempo > 2.0:
			cancelar("¡Olla recuperada! Llévenla a la fogata")
		return
	if estado == "derrumbe":
		for o in objetos:
			o.pos = Vector2(o.origen).lerp(o.destino, clampf(tiempo / 0.85, 0, 1))
		if tiempo >= 1.0:
			_desordenar()
			estado = "buscando"
		return
	if estado != "buscando":
		return
	for id in participantes:
		manos[id].dolor = maxf(0.0, float(manos[id].dolor) - delta)
		if _reloj - float(_entradas[id].cuando) > 0.45:
			_soltar(id, false)
			_entradas[id].pulsa = false
	pilas = [0, 0]
	for i in range(1, objetos.size()):
		var o: Dictionary = objetos[i]
		if o.dueno != 0:
			continue
		if o.vuelo > 0:
			o.pos = (Vector2(o.pos) + Vector2(o.vel) * delta).clamp(Vector2(95, 240), Vector2(1185, 590))
			o.vel = Vector2(o.vel).move_toward(Vector2.ZERO, 2000 * delta)
			o.vuelo -= delta
			continue
		o.lado = 0 if o.pos.x < 340 else 1 if o.pos.x > 940 else -1
		if o.lado >= 0:
			if aportes.has(o.lanzador):
				aportes[o.lanzador] = true
			var n: int = pilas[o.lado]
			pilas[o.lado] += 1
			o.pos = Vector2((190 if o.lado == 0 else 1090) + sin(n * 2.7) * 35, 565 - n * 29)
	for lado in 2:
		riesgo[lado] = float(riesgo[lado]) + delta if pilas[lado] >= LIMITE_PILA else 0.0
		if riesgo[lado] >= AVISO_CAIDA:
			_derrumbar(lado)
			return

func _notification(que: int) -> void:
	if que == NOTIFICATION_PAUSED and is_inside_tree() and multiplayer.is_server():
		for id in _entradas:
			_soltar(id, false)
			_entradas[id].pulsa = false

## Bots y pruebas usan los mismos cursores y las mismas reglas que un humano.
func plan_bot(id: int) -> Dictionary:
	if estado != "buscando" or not manos.has(id):
		return {"pos": Vector2(640, 600), "pulsa": false}
	var agarrado: int = manos[id].objeto
	if agarrado >= 0:
		var destino := SALIDA.get_center() if agarrado == 0 else Vector2(225 if pilas[0] <= pilas[1] else 1055, 420)
		return {"pos": destino - Vector2(manos[id].offset), "pulsa": Vector2(objetos[agarrado].pos).distance_to(destino) > 38}
	if _entradas.has(id) and _entradas[id].pulsa:
		return {"pos": manos[id].pos, "pulsa": false}
	if libre() and aportes.values().all(func(v): return v) and objetos[0].dueno == 0:
		return {"pos": objetos[0].pos, "pulsa": true}
	# Retirar primero lo que tapa la olla; usar también el borde visible de una pieza.
	var area := rect_objeto(0).grow(40)
	for i in range(objetos.size() - 1, 0, -1):
		if objetos[i].dueno != 0 or objetos[i].lado >= 0:
			continue
		if not rect_objeto(i).intersects(area) and aportes.get(id, false):
			continue
		for offset in [Vector2.ZERO, Vector2(-55, -30), Vector2(55, -30), Vector2(-55, 30), Vector2(55, 30)]:
			var punto: Vector2 = objetos[i].pos + offset
			if seleccionar(punto) == i:
				return {"pos": punto, "pulsa": Vector2(manos[id].pos).distance_to(punto) < 35}
	return {"pos": Vector2(640, 610), "pulsa": false}
