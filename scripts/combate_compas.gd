extends Node
## Parada y lanzamiento de compañeros. Las peticiones se validan en el servidor;
## los RPC de presentación pertenecen siempre al servidor, incluso en un cliente.
const VENTANA_PARADA := 0.22
const ESPERA_PARADA := 0.9
const ESPERA_LANZAMIENTO := 1.4
const DANO_COMPAZO := 40
const DANO_COMPANERO := 15

var parada := 0.0
var espera_parada := 0.0
var espera_lanzamiento := 0.0
var direccion_parada := 1
var volando := false
var direccion_vuelo := 1
var lanzador_id := 0
var tiempo_vuelo := 0.0
var destello := 0.0
var paradas_logradas := 0
var impactos_logrados := 0
var j: CharacterBody2D
var efecto: Node2D


func _ready() -> void:
	j = get_parent()
	set_multiplayer_authority(1)
	process_physics_priority = 5
	efecto = Guardia.new()
	efecto.combate = self
	efecto.z_index = 5
	j.get_node("Visual").add_child(efecto)


func _autorizado() -> bool:
	return multiplayer.is_server() and multiplayer.get_remote_sender_id() in [0, j.get_multiplayer_authority()]


@rpc("any_peer", "call_remote", "reliable")
func pedir_parada(dir: int) -> void:
	if not _autorizado() or dir not in [-1, 1] or espera_parada > 0 or not j.puede_actuar() \
			or j.altura > 12 or j._pieza_cargada() != null or j._espera_servidor > 0:
		return
	j._cancelar_golpes()
	j._espera_servidor = VENTANA_PARADA
	_empezar_parada.rpc(dir)


@rpc("authority", "call_local", "reliable")
func _empezar_parada(dir: int) -> void:
	parada = VENTANA_PARADA
	espera_parada = ESPERA_PARADA
	direccion_parada = dir
	j._apuntando_botella = false
	j._anim_golpe = 0


func intentar_parada(oso: Node2D) -> bool:
	if not multiplayer.is_server() or parada <= 0 or not j.puede_actuar() \
			or j.altura > 12 or (oso.position.x - j.position.x) * direccion_parada < 0:
		return false
	parada = 0
	_exito_parada.rpc()
	return true


@rpc("authority", "call_local", "reliable")
func _exito_parada() -> void:
	parada = 0
	Audio.efecto("parada")
	destello = 0.35
	paradas_logradas += 1
	_aviso("¡PARADA!", Color("82f5ff"))


@rpc("any_peer", "call_remote", "reliable")
func pedir_empujon(dir: int) -> void:
	if not _autorizado() or dir not in [-1, 1] or espera_lanzamiento > 0 or not j.puede_actuar() \
			or j.altura > 12 or j._pieza_cargada() != null or j._espera_servidor > 0 or parada > 0:
		return
	var objetivo: Node2D = null
	var torre: Array = j._torre()._cadena(j)
	if torre.size() > 1:
		objetivo = torre.back() # Solo sale el de arriba; los demás conservan su puesto.
	else:
		for otro in get_tree().get_nodes_in_group("jugadores"):
			var d: Vector2 = otro.position - j.position
			if otro == j or otro.altura > 12 or d.x * dir < -8 or absf(d.x) > 55 or absf(d.y) > 22:
				continue
			if not otro.puede_actuar() or otro.es_invulnerable():
				continue
			if objetivo == null or d.length_squared() < objetivo.position.distance_squared_to(j.position):
				objetivo = otro
	if objetivo == null or not objetivo.puede_actuar() or objetivo.es_invulnerable():
		return
	espera_lanzamiento = ESPERA_LANZAMIENTO
	j._espera_servidor = 0.4
	j._mostrar_lanzamiento.rpc()
	objetivo._torre().romper_desde(objetivo)
	objetivo._interrumpir_bebida()
	objetivo._cancelar_golpes()
	objetivo.aturdimiento = 0.25
	var pieza = objetivo._pieza_cargada()
	if pieza:
		pieza.soltar(objetivo.position)
	objetivo.combate._empezar_vuelo.rpc(j.name.to_int(), dir)
	objetivo._aplicar_empujon.rpc(dir, 1.5)


@rpc("authority", "call_local", "reliable")
func _empezar_vuelo(lanzador: int, dir: int) -> void:
	parada = 0
	volando = true
	direccion_vuelo = dir
	lanzador_id = lanzador
	tiempo_vuelo = 0
	j._apuntando_botella = false


func _physics_process(delta: float) -> void:
	parada = maxf(parada - delta, 0)
	espera_parada = maxf(espera_parada - delta, 0)
	espera_lanzamiento = maxf(espera_lanzamiento - delta, 0)
	destello = maxf(destello - delta, 0)
	efecto.queue_redraw()
	if not volando:
		return
	tiempo_vuelo += delta
	if not multiplayer.is_server():
		return
	if j.caido or j._partida().finalizada or tiempo_vuelo > 1.6 or (tiempo_vuelo > 0.2 and j.altura <= 0):
		_cancelar.rpc()
		return
	var oso: Node2D = get_tree().get_first_node_in_group("jefe")
	if oso == null or not oso.activa or oso.estado in ["llegando", "lago", "derrotada"]:
		return
	var d: Vector2 = oso.position - j.position
	if absf(d.x) > oso.ancho + 18 or absf(d.y) > 32 or j.altura < oso.altura - 30 or j.altura > oso.altura + oso.alto_botella:
		return
	# Consumir primero el proyectil: un mismo vuelo solo puede golpear una vez.
	var quien = j._torre().jugador(lanzador_id)
	var atacante := lanzador_id
	var dir := direccion_vuelo
	_cancelar.rpc()
	if quien == null:
		quien = j
	var dano_anterior: int = quien._dano_ataque
	quien._dano_ataque = DANO_COMPAZO
	oso.golpeada(dir, quien)
	quien._dano_ataque = dano_anterior
	oso.tambalear(0.75)
	j.recibir_golpe(-dir, DANO_COMPANERO, 0.65, atacante)
	_impacto.rpc()


@rpc("authority", "call_local", "reliable")
func _impacto() -> void:
	impactos_logrados += 1
	_aviso("¡COMPAZO!", Color("ffd06a"))


func cancelar() -> void:
	if multiplayer.is_server() and (volando or parada > 0):
		_cancelar.rpc()


@rpc("authority", "call_local", "reliable")
func _cancelar() -> void:
	volando = false
	parada = 0


func _aviso(texto: String, color: Color) -> void:
	var cartel := Label.new()
	cartel.text = texto
	cartel.z_index = 30
	cartel.add_theme_color_override("font_color", color)
	cartel.add_theme_color_override("font_outline_color", Color.BLACK)
	cartel.add_theme_constant_override("outline_size", 4)
	j.get_parent().get_parent().add_child(cartel)
	cartel.global_position = j.global_position + Vector2(-55, -j.altura - 115)
	var tween := cartel.create_tween().set_parallel(true)
	tween.tween_property(cartel, "position:y", cartel.position.y - 30, 0.65)
	tween.tween_property(cartel, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.chain().tween_callback(cartel.queue_free)


class Guardia extends Node2D:
	var combate: Node

	func _draw() -> void:
		if combate.parada <= 0 and combate.destello <= 0:
			return
		var lado: int = combate.direccion_parada
		var centro := Vector2(lado * 10, -48)
		var angulo := 0.0 if lado == 1 else PI
		draw_arc(centro, 35 if combate.destello <= 0 else 46, angulo - 1.1, angulo + 1.1,
			12, Color("82f5ff"), 4 if combate.destello <= 0 else 7)
