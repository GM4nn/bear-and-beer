extends Node2D
## Encuentro de miel: servidor autoritativo, plantel fijo y réplica atómica.
const CENTRO := Vector2(5900, 665)
const RADIO := 210.0
const SACUDIDAS := 10
## Oleadas: 1 enjambres, 2 fusiones, 3 musculosas, 4 emboscada mixta,
## 5 musculosas que escupen miel y 6 la reina (con 3 fases).
const OLA_REINA := 6
const CAMPOS := ["estado", "ola", "completada", "tiempo", "encuentro", "pegados", "mensaje"]
var estado := "esperando"
var ola := 0
var completada := false
var tiempo := 0.0
var encuentro := 0
var pegados := {}
var mensaje := "Reúnanse todos debajo del lago para conseguir miel"
var enemigos: Array = []
var _reloj := 0.0
var _envio := 0.0
var _inmunidad := {}
var _equipo: Array = []

func _ready() -> void:
	add_to_group("oleadas_miel")
	y_sort_enabled = true
	for i in 16:
		var e := preload("res://scripts/enemigo_oleada.gd").new()
		e.name = "Enemigo%d" % i
		add_child(e)
		enemigos.append(e)
	var vista := preload("res://scripts/oleadas_miel_vista.gd").new()
	vista.name = "Vista"
	add_child(vista)

func partida() -> Node:
	return get_tree().get_first_node_in_group("partida")

func jugador(id: int) -> Node2D:
	return get_parent().get_node_or_null("Jugadores/%d" % id)

func habilitada() -> bool:
	return partida().busqueda_olla.conseguida and not completada

func activa() -> bool:
	return estado in ["aviso", "combate", "descanso"]

func restantes() -> int:
	return enemigos.filter(func(e): return e.vivo()).size()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or partida().finalizada:
		return
	_reloj += delta
	for id in pegados.keys():
		var j := jugador(id)
		if j == null or j.caido:
			pegados.erase(id)
	if not habilitada():
		return
	if activa():
		# Cambiar el plantel a mitad del combate reinicia el encuentro, sin entregar miel.
		if _equipo.size() != Red.jugadores.size() or not _equipo.all(func(id): return Red.jugadores.has(id)):
			cancelar()
			return
		tiempo -= delta
		if estado == "combate" and restantes() == 0:
			if ola == OLA_REINA:
				ganar()
			else:
				estado = "descanso"
				tiempo = 3.0
				mensaje = "Oleada superada · preparen el siguiente ataque"
		elif estado in ["aviso", "descanso"] and tiempo <= 0:
			iniciar_ola(ola + 1)
		return
	var juntos := 0
	for id in Red.jugadores:
		var j := jugador(id)
		if j != null and not j.caido and j.vida > 0 and j.puede_actuar() and j.altura <= 1 and j.apoyo_id == 0 and j.position.distance_to(CENTRO) <= RADIO:
			juntos += 1
	mensaje = "Miel · reúnanse TODOS debajo del lago: %d/%d" % [juntos, Red.jugadores.size()]
	if juntos >= 2 and juntos == Red.jugadores.size():
		tiempo += delta
		if tiempo >= 2.0:
			encuentro += 1
			_equipo = Red.jugadores.keys()
			partida().abeja_musculosa.cancelar()
			estado = "aviso"
			tiempo = 3.0
			mensaje = "¡Se acercan los enjambres!"
	else:
		tiempo = 0.0

func iniciar_ola(numero: int) -> void:
	if not multiplayer.is_server():
		return
	ola = numero
	estado = "combate"
	var mitad := ceili(_equipo.size() / 2.0)
	# Cada entrada es [tipo, se fusiona].
	var plantel: Array = []
	match ola:
		1:
			for i in 4 + mitad:
				plantel.append(["enjambre", false])
		2:
			for i in 5 + mitad:
				plantel.append(["enjambre", i < 2])
		3:
			for i in 2 + mitad:
				plantel.append(["musculosa", false])
		4:
			for i in 1 + mitad:
				plantel.append(["musculosa", false])
			for i in 4:
				plantel.append(["enjambre", i < 2])
		5:
			for i in 2 + mitad:
				plantel.append(["musculosa_miel", false])
		_:
			plantel.append(["reina", false])
	for i in enemigos.size():
		var e: Node2D = enemigos[i]
		e.estado = "inactivo"
		if i >= plantel.size():
			continue
		var tipo: String = plantel[i][0]
		var sitio := CENTRO + Vector2((-1 if i % 2 == 0 else 1) * (290 + 45 * (i / 2)), (i % 3 - 1) * 20)
		e.activar("musculosa" if tipo == "musculosa_miel" else tipo, sitio, plantel[i][1], _equipo.size())
		e.escupe_miel = tipo == "musculosa_miel"
	mensaje = ["", "Oleada 1/5 · enjambres", "Oleada 2/5 · ¡dos enjambres se fusionan!", "Oleada 3/5 · abejas musculosas",
		"Oleada 4/5 · ¡emboscada! musculosas y enjambres", "Oleada 5/5 · musculosas que escupen miel",
		"¡ABEJA REINA! · esquiven sus puños y su miel"][ola]


## La reina cambia de fase y llama refuerzos a sus lados (usa lugares libres).
func refuerzos(fase: int, junto: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var mitad := ceili(_equipo.size() / 2.0)
	var nuevos: Array = []
	if fase == 2:
		for i in 2 + mitad:
			nuevos.append("enjambre")
	else:
		nuevos.append("musculosa")
		for i in 2:
			nuevos.append("enjambre")
	var lado := -1
	for e in enemigos:
		if nuevos.is_empty():
			break
		if e.vivo():
			continue
		e.activar(nuevos.pop_front(), junto + Vector2(lado * randf_range(260, 380), randf_range(-40, 40)), false, _equipo.size())
		lado = -lado
	mensaje = "¡LA REINA SE ENOJA! · fase %d/3 · llamó refuerzos" % fase

func ganar() -> void:
	if not multiplayer.is_server() or completada:
		return
	completada = true
	estado = "completada"
	pegados.clear()
	mensaje = "¡Miel conseguida! Llévenla a la olla para cocinar"
	get_parent().get_node("Miel").soltar(CENTRO + Vector2(90, 0))

func cancelar() -> void:
	estado = "esperando"
	ola = 0
	tiempo = 0
	pegados.clear()
	_inmunidad.clear()
	for e in enemigos:
		e.estado = "inactivo"
	mensaje = "Reúnanse todos debajo del lago para conseguir miel"

func empapar(j: Node2D) -> void:
	var id := j.name.to_int()
	if not multiplayer.is_server() or not activa() or j.caido or j.es_invulnerable() or pegados.has(id) or _inmunidad.get(id, 0.0) > _reloj:
		return
	j._torre().romper_desde(j)
	j._cancelar_golpes()
	j.combo.reiniciar()
	j.combate.cancelar()
	j._interrumpir_bebida()
	pegados[id] = {"pasos": 0, "ultimo": 0, "reloj": -1.0}

@rpc("any_peer", "call_local", "reliable")
func sacudir(ronda: int, lado: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	if not multiplayer.is_server() or get_tree().paused or partida().finalizada or ronda != encuentro or lado not in [-1, 1] or not pegados.has(id):
		return
	var j := jugador(id)
	if j == null or j.caido:
		return
	var dato: Dictionary = pegados[id]
	if lado == dato.ultimo or _reloj - dato.reloj < 0.07:
		return
	dato.ultimo = lado
	dato.reloj = _reloj
	dato.pasos += 1
	if dato.pasos >= SACUDIDAS:
		pegados.erase(id)
		_inmunidad[id] = _reloj + 3.0

func entrada_miel(j: Node2D, delta: float) -> void:
	if not j.is_multiplayer_authority():
		return
	var lado := 0
	if not j._bot.is_empty():
		j._bot_espera -= delta
		if j._bot_espera <= 0:
			j._bot_espera = 0.18
			lado = 1 if pegados[j.name.to_int()].ultimo <= 0 else -1
	else:
		var izquierda := Input.is_action_just_pressed("izquierda")
		var derecha := Input.is_action_just_pressed("derecha")
		if izquierda != derecha:
			lado = -1 if izquierda else 1
	if lado != 0:
		if multiplayer.is_server():
			sacudir(encuentro, lado)
		else:
			sacudir.rpc_id(1, encuentro, lado)

func _process(delta: float) -> void:
	if not multiplayer.is_server() or multiplayer.get_peers().is_empty():
		return
	_envio += delta
	if _envio < 0.05:
		return
	_envio = 0
	var datos := {}
	for clave in CAMPOS:
		datos[clave] = get(clave)
	datos.enemigos = enemigos.map(func(e): return e.datos())
	_recibir.rpc(var_to_bytes(datos).compress(FileAccess.COMPRESSION_DEFLATE))

@rpc("authority", "call_remote", "reliable")
func _recibir(paquete: PackedByteArray) -> void:
	if multiplayer.is_server():
		return
	var datos: Dictionary = bytes_to_var(paquete.decompress_dynamic(65536, FileAccess.COMPRESSION_DEFLATE))
	for clave in CAMPOS:
		set(clave, datos[clave])
	for i in enemigos.size():
		enemigos[i].aplicar(datos.enemigos[i])
