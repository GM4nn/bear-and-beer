extends Node2D
## Rescate cooperativo: todos siguen los objetivos con clic sostenido.
const SITIO := Vector2(7020, 650)
## Donde se sientan los oseznos: sobre la rama del árbol alto (arbol_rescate.png).
const RAMA := Vector2(-123, -304)
const ATAJAR := Vector2(-140, 20)
const INCLINACION_TREPADO := -0.26
const BAJADA_TREPADO := Vector2(0, 22)
## Alto del osezno colgado: la liana termina en sus patas, no en sus pies.
const ALTO_COLGADO := 60.0
const RADIO := 65.0
const RADIO_EQUIPO := 110.0
const DURACION_SALTO := 1.15
const DANO_RASGUNO := 12
const ARTE := preload("res://scripts/arte_objetos.gd")
var rescatados := 0
var cebo := false
var estado := "esperando"
var participantes: Array = []
## Los primeros participantes sostienen la torre; el resto juega desde el suelo.
var torre_ids: Array = []
var encuentro := 0
var miedo := 0.15
var equilibrio := 0.0
var calma := 0.0
var tiempo := 0.0
var origen_salto := Vector2.ZERO
var destino_salto := Vector2.ZERO
var mensaje := "Traigan miel y reúnan a todo el equipo junto al árbol"
var paso := 0
var avances: Array = []
var inclinaciones: Array = [0.0, 0.0]
var corrimiento := 0.0
var fase := 0.0
var reto: Node
var _crias: Array[AnimatedSprite2D] = []
var _titulo: Label

func _ready() -> void:
	# El árbol alto (Mundo/ArbolRescate) se acomoda en el editor; el rescate lo sigue.
	var arbol := get_parent().get_node_or_null("ArbolRescate") as Node2D
	position = arbol.position if arbol != null else SITIO
	add_to_group("rescate_oseznos")
	process_physics_priority = 15
	var config := SceneReplicationConfig.new()
	for propiedad in ["rescatados", "cebo", "estado", "participantes", "torre_ids", "encuentro", "miedo", "equilibrio", "calma", "tiempo", "origen_salto", "destino_salto", "mensaje", "inclinaciones", "corrimiento", "fase", "paso", "avances"]:
		var ruta := NodePath(".:" + propiedad)
		config.add_property(ruta)
		config.property_set_replication_mode(ruta, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sincronizador"
	sync.replication_config = config
	sync.replication_interval = 0.05
	add_child(sync)
	for i in 2:
		var cria := ARTE.animado({"quieto": "res://arte/zona1/objetos/quieto", "llorar": "res://arte/zona1/objetos/llorar",
			"salto": "res://arte/zona1/objetos/cria_salto", "asustado": "res://arte/zona1/objetos/cria_asustado",
			"rasguno": "res://arte/zona1/objetos/cria_rasguno", "olfatear": "res://arte/zona1/objetos/cria_olfatear",
			"trepado": "res://arte/zona1/objetos/cria_trepado", "colgado": "res://arte/zona1/objetos/cria_colgado"}, 1.5, 9)
		cria.z_index = 12
		cria.modulate = Color.WHITE if i == 0 else Color(0.88, 0.94, 1)
		add_child(cria)
		_crias.append(cria)
	_titulo = Label.new()
	_titulo.position = RAMA + Vector2(-130, -100)
	_titulo.size.x = 320
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 16)
	_titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_titulo.add_theme_constant_override("outline_size", 5)
	_titulo.z_index = 13
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)
	reto = preload("res://scripts/reto_rescate.gd").new()
	reto.name = "Reto"
	add_child(reto)
	_crear_arbol.call_deferred()

func _crear_arbol() -> void:
	var arbol := get_parent().get_node_or_null("ArbolRescate") as Node2D
	if arbol == null:
		arbol = preload("res://escenas/arbol.tscn").instantiate()
		arbol.name = "ArbolRescate"
		arbol.position = SITIO
		get_parent().add_child(arbol)
	# Árbol alto propio (más alto que una torre de tres) con la rama de los oseznos.
	if arbol.get_node_or_null("Arte") == null:
		get_parent().get_parent()._vestir(arbol, "arbol_rescate", 1.0)
	# La rama y los oseznos quedan por delante del follaje reutilizado.
	z_index = 2

func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")

func _jugador(id: int) -> Node2D:
	return get_parent().get_node_or_null("Jugadores/%d" % id)

func activo() -> bool:
	return estado in ["preparando", "ritmo", "salto", "bajando"]

func contiene(id: int) -> bool:
	return activo() and id in participantes

func listo() -> bool:
	return rescatados >= 2

func lugar() -> Vector2:
	return global_position + ATAJAR

func rama(indice: int) -> Vector2:
	return global_position + RAMA + Vector2(indice * 65, 0)

func _motivo_equipo(compas: Array) -> String:
	# Usar el registro de la partida, sin excluir muertos ni nodos pendientes.
	for id in Red.jugadores:
		var c := _jugador(id)
		if c == null:
			return "Esperen a que estén todos los jugadores"
		if c.caido or c.vida <= 0:
			return "Primero revivan a %s: deben jugar todos" % c.nombre
		if not puede_sostener(c) or c.en_forcejeo() or c.en_fogata():
			return "%s todavía no puede participar" % c.nombre
		if c not in compas and (c.position.distance_to(lugar()) > RADIO_EQUIPO or c.altura > 1 or c.apoyo_id != 0):
			return "Falta %s junto al árbol: deben jugar todos" % c.nombre
	if compas.size() != mini(3, Red.jugadores.size()):
		return "Formen la torre con %d compas; todos deben participar" % mini(3, Red.jugadores.size())
	return ""

func interactuar(j: Node2D) -> bool:
	if not multiplayer.is_server() or get_tree().paused or listo() or _partida().finalizada or j.position.distance_to(lugar()) > RADIO:
		return false
	if estado != "esperando":
		return contiene(j.name.to_int())
	var pieza: Node2D = j._pieza_cargada()
	if pieza != null and pieza.tipo == "miel" and j.apoyo_id == 0:
		cebo = true
		pieza.soltar(lugar() + Vector2(-80, 20))
		mensaje = "Miel preparada · reúnan al equipo, formen la torre y pulsen E"
		return true
	var torre: Node = _partida().torre
	var base: Node2D = torre._base(j)
	if base == null:
		return false
	var compas: Array = torre._cadena(base)
	if compas.size() < 2:
		return false
	if not cebo:
		j._avisar_bebida.rpc("Primero acerquen miel al árbol y ofrézcanla con E")
		return true
	if compas.size() > 3 or base.altura > 1 or not compas.all(func(c): return torre._equilibrado(c)):
		return true
	var motivo := _motivo_equipo(compas)
	if not motivo.is_empty():
		mensaje = motivo
		j._avisar_bebida.rpc(motivo)
		return true
	torre_ids = compas.map(func(c): return c.name.to_int())
	participantes = torre_ids.duplicate()
	for id in Red.jugadores:
		if id not in participantes:
			participantes.append(id)
	encuentro += 1
	tiempo = 0.0
	equilibrio = 0.0
	miedo = 0.15
	calma = 0.0
	paso = 0
	avances = []
	inclinaciones = [0.0, 0.0]
	corrimiento = 0.0
	fase = 0.0
	for id in participantes:
		var c := _jugador(id)
		c._cancelar_golpes()
		c._anim_golpe = 0.0
		c.manteniendo = false
		avances.append(0.0)
	estado = "preparando"
	mensaje = "Todos: mantengan el clic y sigan los círculos numerados"
	reto.iniciar()
	return true

func _manos(j: Node2D) -> Vector2:
	return j.position - Vector2(0, j.altura + 102)

func completar_reto() -> void:
	if not multiplayer.is_server() or estado != "ritmo":
		return
	origen_salto = posicion_cria()
	destino_salto = manos_torre()
	estado = "salto"
	tiempo = 0.0
	mensaje = "¡Todos acertaron! Atajando al osezno"


func cancelar() -> void:
	if multiplayer.is_server() and activo():
		_fallar(false)

func _fallar(rasguno: bool, fallidos: Array = []) -> void:
	var ids := participantes.duplicate()
	var ultimo := _jugador(torre_ids.back()) if not torre_ids.is_empty() else null
	origen_salto = posicion_cria()
	destino_salto = rama(rescatados)
	estado = "regreso"
	tiempo = 0.0
	miedo = 1.0 if rasguno else miedo
	mensaje = "¡Falló un compa! Todos caen; el osezno vuelve a la rama" if rasguno else "Rescate interrumpido; vuelvan a formar la torre"
	if rasguno and not fallidos.is_empty():
		var nombres := PackedStringArray()
		for id in fallidos:
			var compa := _jugador(id)
			nombres.append(compa.nombre if compa != null else str(Red.jugadores.get(id, {}).get("nombre", "Compa")))
		mensaje = "¡%s %s!\nTodos caen; el osezno vuelve a la rama" % ["Falló" if nombres.size() == 1 else "Fallaron", ", ".join(nombres)]
	participantes.clear()
	torre_ids.clear()
	reto.limpiar()
	# Separar todos los pisos, incluida la base. No basta con soltar al último.
	var torre: Node = _partida().torre
	for i in ids.size():
		var j := _jugador(ids[i])
		if j == null:
			continue
		torre._soltar.rpc(ids[i], j.position, j.altura, 90.0)
		j.aturdimiento = maxf(j.aturdimiento, 0.75)
		j._aplicar_empujon.rpc(-1 if i % 2 == 0 else 1, 0.65)
	if rasguno and ultimo != null:
		ultimo._perder_vida(DANO_RASGUNO)

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or not multiplayer.is_server():
		return
	if _partida().finalizada:
		cancelar()
	if activo():
		if participantes.size() != Red.jugadores.size() or not participantes.all(func(id): return Red.jugadores.has(id)) or torre_ids.is_empty():
			_fallar(false)
			return
		var base: Node2D = _jugador(participantes[0])
		if base == null or base.position.distance_to(lugar()) > RADIO or base.altura > 1:
			_fallar(false)
			return
		var cadena: Array = _partida().torre._cadena(base)
		if cadena.map(func(c): return c.name.to_int()) != torre_ids or not _motivo_equipo(cadena).is_empty():
			_fallar(false)
			return
	tiempo += delta
	match estado:
		"preparando":
			if tiempo >= reto.PREPARACION:
				estado = "ritmo"
				tiempo = 0.0
		"ritmo":
			fase += delta * 2.0
			inclinaciones = [sin(fase) * 0.18, sin(fase * 1.3) * 0.22]
			equilibrio = inclinaciones[0]
		"salto":
			if tiempo >= DURACION_SALTO:
				origen_salto = destino_salto
				destino_salto = get_tree().get_first_node_in_group("estacion").global_position + Vector2(98 + rescatados * 50, rescatados * 6)
				estado = "bajando"
				tiempo = 0.0
		"bajando":
			if tiempo >= 2.0:
				rescatados += 1
				participantes.clear()
				torre_ids.clear()
				reto.limpiar()
				estado = "esperando"
				mensaje = "¡Los dos están a salvo! Ahora preparen la fogata" if listo() else "Uno a salvo. Atajen al segundo con la torre"
		"regreso":
			if tiempo >= DURACION_SALTO:
				estado = "esperando"

func puede_sostener(j: Node2D) -> bool:
	return j != null and not j.caido and j.vida > 0 and j.bebiendo <= 0 and j.dormido <= 0 and j.vomitando <= 0 and j.nausea <= 0 and j.aturdimiento <= 0 and j.rodando <= 0 and not j.combate.volando and j._sujeto <= 0 and j._pieza_cargada() == null

func posicion_cria() -> Vector2:
	if estado in ["salto", "regreso", "bajando"]:
		var t := clampf(tiempo / (2.0 if estado == "bajando" else DURACION_SALTO), 0, 1)
		return origen_salto.lerp(destino_salto, t) - Vector2(0, sin(t * PI) * 55)
	if estado in ["preparando", "ritmo"]:
		return pivote() + Vector2(sin(angulo_columpio()), cos(angulo_columpio())) * largo_cuerda()
	return rama(rescatados)


## De dónde cuelga el osezno: se recorre despacio a lo largo de la rama, así la
## base tiene que seguirlo.
func pivote() -> Vector2:
	return rama(rescatados) + Vector2(70.0 * sin(fase * 0.23), 0)


func angulo_columpio() -> float:
	return 0.35 * sin(fase)


## Largo de la liana: en lo más bajo pasa a la altura de las manos de la torre.
func largo_cuerda() -> float:
	var alto := 182.0
	if not torre_ids.is_empty():
		var j := _jugador(torre_ids.back())
		if j != null:
			alto = j.altura + 102.0
	return maxf(lugar().y - alto - pivote().y, 60.0)


## Dónde quedan las manos del de hasta arriba, con la torre corrida e inclinada.
func manos_torre() -> Vector2:
	if torre_ids.is_empty():
		return lugar()
	var j := _jugador(torre_ids.back())
	if j == null:
		return lugar()
	return _manos(j) + Vector2(corrimiento + _desvio_piso(torre_ids.size() - 1), 0)


## Cuánto se corre a los lados el piso `nivel` por las inclinaciones de abajo.
func _desvio_piso(nivel: int) -> float:
	var x := 0.0
	for k in mini(nivel, inclinaciones.size()):
		x += sin(float(inclinaciones[k]) * 0.42) * 60.0 * 1.6
	return x

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_titulo.visible = not listo()
	_titulo.text = "OSEZNOS · %d/2 A SALVO" % rescatados
	_tambalear_torre()
	for i in 2:
		_crias[i].visible = i >= rescatados
		var lugar_cria := posicion_cria() if i == rescatados else rama(i)
		# En la rama, acostados abrazándola (su ramita dibujada va ladeada).
		var anim := "trepado"
		if i == rescatados:
			if estado in ["preparando", "ritmo"]:
				# Colgado de la liana con las patas arriba.
				anim = "colgado"
			elif estado == "regreso" and tiempo < 0.25 and miedo >= 1:
				# Antes de saltar de regreso, rasguña al de hasta arriba.
				anim = "rasguno"
				lugar_cria = origen_salto
			elif estado in ["salto", "regreso", "bajando"]:
				anim = "salto"
			elif estado == "esperando" and cebo:
				anim = "olfatear"
		_crias[i].global_position = lugar_cria + (BAJADA_TREPADO if anim == "trepado" else Vector2.ZERO)
		match anim:
			"trepado":
				_crias[i].rotation = INCLINACION_TREPADO
			"colgado":
				_crias[i].rotation = -angulo_columpio()
			_:
				_crias[i].rotation = 0.0
		if _crias[i].animation != anim:
			_crias[i].play(anim)
	queue_redraw()


## La torre se dibuja como péndulo: toda corrida por la base y cada piso de
## arriba inclinado y desplazado por los de abajo.
var _inclinados: Array = []
func _tambalear_torre() -> Vector2:
	for j in _inclinados:
		if is_instance_valid(j):
			j.visual.rotation = 0.0
			j.visual.position.x = 0.0
	_inclinados.clear()
	if estado not in ["preparando", "ritmo"] or torre_ids.is_empty():
		return Vector2.ZERO
	for nivel in torre_ids.size():
		var j := _jugador(torre_ids[nivel])
		if j == null:
			continue
		j.visual.position.x = corrimiento + _desvio_piso(nivel)
		j.visual.rotation = float(inclinaciones[nivel - 1]) * 0.42 if nivel > 0 else 0.0
		_inclinados.append(j)
	return Vector2.ZERO


func _draw() -> void:
	# La rama ya viene dibujada en el árbol alto. En el columpio, una liana.
	if estado in ["preparando", "ritmo"]:
		var arriba := pivote() - global_position
		var abajo := posicion_cria() - global_position
		abajo -= (abajo - arriba).normalized() * ALTO_COLGADO
		draw_line(arriba, abajo, Color("3b2a16"), 4)
		draw_line(arriba, abajo, Color("6b8f3a"), 2)
	if not listo():
		draw_arc(ATAJAR, RADIO * 0.65, 0, TAU, 30, Color("ffe285"), 2)
		if cebo:
			draw_circle(ATAJAR + Vector2(-35, 0), 6, Color("e8a824"))
