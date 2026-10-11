extends CharacterBody2D
## Jugador (cubo de prototipo). Vista lateral con profundidad: `position` es
## dónde pisa en el suelo del bosque y `altura` qué tan arriba está al saltar.
## Cada quien mueve a su propio personaje y el anfitrión decide a quién le
## llegan los golpes y quién carga cada pieza (GDD sección 6).

const VELOCIDAD := 220.0
const VELOCIDAD_FONDO := 150.0
const FRENO_CARGANDO := 0.75
const SALTO := 420.0
const GRAVEDAD := 1200.0
const ALCANCE_GOLPE := 46.0
const FONDO_GOLPE := 20.0
const ALTURA_GOLPE := 36.0
const ALCANCE_AGARRAR := 44.0
const ESPERA_GOLPE := 0.35
const DANO_GOLPE := 10
const EMPUJON := 300.0
const EMPUJON_ARRIBA := 300.0
const VIDA_MAX := 100
const COLORES: Array[Color] = [
	Color("e0533d"), Color("3d8be0"), Color("5fc24a"),
	Color("e8c33a"), Color("a45fd6"), Color("e88a3a"),
]

var vida := VIDA_MAX
var mirando := 1
var altura := 0.0
## Tiene presionado el botón de agarrar (sirve para construir en la estación).
var manteniendo := false
var color_indice := 0
var nombre := ""

var _vel_altura := 0.0
var _volando := false
var _espera := 0.0
var _aturdido := 0.0
var _parpadeo := 0.0
var _golpe_visible := 0.0
var _bot := ""
var _bot_espera := 0.0
var _bot_desvio := 0.0
var _bot_lado := Vector2.ZERO

@onready var visual: Node2D = $Visual
@onready var sombra: ColorRect = $Sombra
@onready var cuerpo: ColorRect = $Visual/Cuerpo
@onready var ojo: ColorRect = $Visual/Ojo
@onready var golpe: ColorRect = $Visual/Golpe
@onready var etiqueta: Label = $Visual/Vida


func _enter_tree() -> void:
	# El nodo se llama como el id del jugador que lo controla.
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group("jugadores")
	if is_multiplayer_authority():
		var args := OS.get_cmdline_user_args()
		_bot = "mision" if "--bot-mision" in args else "pelea" if "--bot" in args else ""


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_espera -= delta
	_aturdido -= delta

	var en_suelo := altura <= 0.0 and _vel_altura <= 0.0
	if en_suelo:
		altura = 0.0
		_vel_altura = 0.0
		_volando = false
	else:
		_vel_altura -= GRAVEDAD * delta
		altura = maxf(altura + _vel_altura * delta, 0.0)

	if _aturdido > 0.0 or _volando:
		manteniendo = false
		if en_suelo:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	else:
		var dir := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
		var salta := Input.is_action_just_pressed("saltar")
		var pega := Input.is_action_just_pressed("golpear")
		var agarra := Input.is_action_just_pressed("agarrar")
		manteniendo = Input.is_action_pressed("agarrar")
		if _bot:
			var bot := _bot_pelea() if _bot == "pelea" else _bot_mision(delta)
			dir = bot.dir
			salta = false
			pega = bot.pega
			agarra = bot.agarra
			manteniendo = bot.mantiene

		var freno := FRENO_CARGANDO if _pieza_cargada() else 1.0
		velocity = Vector2(dir.x * VELOCIDAD, dir.y * VELOCIDAD_FONDO) * freno
		if dir.x != 0.0:
			mirando = int(signf(dir.x))
		if salta and en_suelo:
			_vel_altura = SALTO
		if pega and _espera <= 0.0:
			_espera = ESPERA_GOLPE
			golpear.rpc(mirando)
		if agarra:
			if multiplayer.is_server():
				pedir_agarrar()
			else:
				pedir_agarrar.rpc_id(1)

	move_and_slide()


func _process(delta: float) -> void:
	_parpadeo -= delta
	_golpe_visible -= delta
	visual.position.y = -altura
	sombra.modulate.a = clampf(1.0 - altura / 200.0, 0.3, 1.0)
	cuerpo.color = Color.WHITE if _parpadeo > 0.0 else COLORES[color_indice % COLORES.size()]
	ojo.position.x = 4.0 if mirando > 0 else -12.0
	golpe.visible = _golpe_visible > 0.0
	golpe.position.x = 16.0 if mirando > 0 else -16.0 - golpe.size.x
	etiqueta.text = "%s\n%d" % [nombre, vida]
	if is_multiplayer_authority():
		var camara := get_viewport().get_camera_2d()
		if camara:
			camara.global_position = global_position


@rpc("authority", "call_local", "reliable")
func golpear(dir: int) -> void:
	mirando = dir
	_golpe_visible = 0.12
	if not multiplayer.is_server():
		return
	# Fuego amigo: el golpe le pega a cualquier otro jugador que esté enfrente,
	# más o menos en la misma línea del suelo y a la misma altura.
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and _alcanza(otro.position, dir) and absf(otro.altura - altura) <= ALTURA_GOLPE:
			print("%s golpea a %s (vida %d)" % [name, otro.name, otro.vida])
			otro.recibir_golpe.rpc(dir, DANO_GOLPE)
			# Si te pegan, sueltas lo que cargas.
			var pieza: Node2D = otro._pieza_cargada()
			if pieza:
				pieza.soltar(otro.position)
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		if _alcanza(cosa.position, dir):
			cosa.golpeada(dir)


@rpc("any_peer", "call_local", "reliable")
func recibir_golpe(dir: int, dano: int) -> void:
	# Solo el anfitrión reparte daño.
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.15
	if is_multiplayer_authority():
		velocity = Vector2(EMPUJON * dir, 0.0)
		_vel_altura = EMPUJON_ARRIBA
		_volando = true
		_aturdido = 0.25
		_perder_vida(dano)


## Daño sin empujón (piquetes de abeja y cosas así).
@rpc("any_peer", "call_local", "reliable")
func recibir_dano(dano: int) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.1
	if is_multiplayer_authority():
		_perder_vida(dano)


## El jugador le pide al anfitrión agarrar la pieza más cercana, o soltar /
## entregar la que ya carga.
@rpc("any_peer", "call_remote", "reliable")
func pedir_agarrar() -> void:
	if not multiplayer.is_server() or not _lo_pide_su_dueno():
		return
	var cargada := _pieza_cargada()
	if cargada:
		var estacion := get_tree().get_first_node_in_group("estacion")
		if not (estacion and estacion.intentar_entregar(cargada, position)):
			cargada.soltar(position)
		return
	var cerca: Node2D = null
	for pieza: Node2D in get_tree().get_nodes_in_group("piezas"):
		if pieza.portador == 0 and not pieza.entregada and _mas_cerca(pieza, cerca):
			cerca = pieza
	if cerca and position.distance_to(cerca.position) <= ALCANCE_AGARRAR:
		cerca.agarrar(name.to_int())


@rpc("any_peer", "call_remote", "reliable")
func soltar_por_caida(donde: Vector2) -> void:
	if multiplayer.is_server() and _lo_pide_su_dueno():
		var cargada := _pieza_cargada()
		if cargada:
			cargada.soltar(donde)


func _perder_vida(dano: int) -> void:
	vida -= dano
	if vida > 0:
		return
	# Por ahora reaparece en el punto más cercano; el estado "caído" viene después.
	if multiplayer.is_server():
		soltar_por_caida(position)
	else:
		soltar_por_caida.rpc_id(1, position)
	var punto: Node2D = null
	for p: Node2D in get_tree().get_nodes_in_group("reaparicion"):
		if _mas_cerca(p, punto):
			punto = p
	vida = VIDA_MAX
	velocity = Vector2.ZERO
	altura = 0.0
	_vel_altura = 0.0
	_volando = false
	if punto:
		position = punto.position


func _alcanza(donde: Vector2, dir: int) -> bool:
	var d := donde - position
	return d.x * dir > -8.0 and absf(d.x) <= ALCANCE_GOLPE and absf(d.y) <= FONDO_GOLPE


func _mas_cerca(nodo: Node2D, que: Node2D) -> bool:
	return que == null or position.distance_to(nodo.position) < position.distance_to(que.position)


func _lo_pide_su_dueno() -> bool:
	var quien := multiplayer.get_remote_sender_id()
	return quien == 0 or quien == get_multiplayer_authority()


func _pieza_cargada() -> Node2D:
	for pieza: Node2D in get_tree().get_nodes_in_group("piezas"):
		if pieza.portador == name.to_int():
			return pieza
	return null


# --- Bots de prueba (argumentos --bot y --bot-mision) ---

func _bot_pelea() -> Dictionary:
	var objetivo: Node2D = null
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and _mas_cerca(otro, objetivo):
			objetivo = otro
	var d := objetivo.position - position if objetivo else Vector2.ZERO
	if d.x != 0.0:
		mirando = int(signf(d.x))
	return {
		"dir": Vector2(signf(d.x) if absf(d.x) > 30.0 else 0.0, signf(d.y) if absf(d.y) > 8.0 else 0.0),
		"pega": objetivo != null and absf(d.x) < ALCANCE_GOLPE and absf(d.y) < FONDO_GOLPE,
		"agarra": false, "mantiene": false,
	}


func _bot_mision(delta: float) -> Dictionary:
	_bot_espera -= delta
	_bot_desvio -= delta
	var orden := {"dir": Vector2.ZERO, "pega": false, "agarra": false, "mantiene": false}
	var estacion: Node2D = get_tree().get_first_node_in_group("estacion")
	if estacion == null or estacion.alimentados or "--bot-flojo" in OS.get_cmdline_user_args() and estacion.terminada:
		return orden

	var destino: Vector2 = estacion.position
	var llego := 50.0
	var al_llegar := "agarra"
	if _pieza_cargada() == null:
		if estacion.terminada:
			destino = estacion.lugar_oseznos()
			llego = 40.0
			al_llegar = "mantiene"
		elif estacion.completa():
			al_llegar = "mantiene"
		else:
			var libre: Node2D = null
			for pieza: Node2D in get_tree().get_nodes_in_group("piezas"):
				if pieza.portador == 0 and not pieza.entregada and _mas_cerca(pieza, libre):
					libre = pieza
			if libre == null:
				return orden
			destino = libre.position
			llego = 30.0

	var d := destino - position
	if d.length() <= llego:
		if al_llegar == "mantiene":
			orden.mantiene = true
		elif _bot_espera <= 0.0:
			_bot_espera = 0.5
			orden.agarra = true
		return orden

	# Si se atora contra un árbol o una roca, camina de lado un momento.
	if _bot_desvio <= 0.0 and get_real_velocity().length() < 20.0:
		_bot_desvio = 0.7
		_bot_lado = Vector2(0.0, [-1.0, 1.0].pick_random()) if absf(d.x) > absf(d.y) else Vector2([-1.0, 1.0].pick_random(), 0.0)
	orden.dir = _bot_lado if _bot_desvio > 0.3 else d.normalized()
	return orden
