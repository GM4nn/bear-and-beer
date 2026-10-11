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
const MAX_CERVEZAS := 6
const BORRACHERA_POR_CERVEZA := 30.0
const ESPERA_SOBRIEDAD := 12.0
const BAJADA_BORRACHERA := 0.5
const CURA_CERVEZA := 35
const TIEMPO_BEBER := 2.0
const TIEMPO_REVIVIR := 3.0
const RADIO_REVIVIR := 60.0
const DURACION_RODAR := 0.32
const ESPERA_RODAR := 1.1
const NIVELES := ["Sobrio", "Alegre", "Pedo", "Hasta atrás"]
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
var cervezas := 0
var borrachera := 0.0
var caido := false
var reanimacion := 0.0
var bebiendo := 0.0
var dormido := 0.0
var vomitando := 0.0
var rodando := 0.0
var espera_rodar := 0.0
var direccion_rodar := Vector2.RIGHT
var proteccion := 0.0
var aturdimiento := 0.0

var _sueno := 0.0
var _espera_sobriedad := 0.0
var _aviso_bebida := ""
var _tiempo_aviso_bebida := 0.0
var _inicio_vuelo := Vector2.ZERO
var _tiempo_vuelo := 0.0
var _midiendo_vuelo := false
var _dano_ataque := DANO_GOLPE

var _vel_altura := 0.0
var _volando := false
var _espera := 0.0
var _espera_servidor := 0.0
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
	# El movimiento pertenece al jugador; la vida siempre al anfitrión.
	$SincronizadorVida.set_multiplayer_authority(1)


func _ready() -> void:
	add_to_group("jugadores")
	_partida().registrar(self)
	if is_multiplayer_authority():
		var args := OS.get_cmdline_user_args()
		_bot = "mision" if "--bot-mision" in args else "pelea" if "--bot" in args else ""


func _physics_process(delta: float) -> void:
	if _partida().finalizada:
		manteniendo = false
		return
	if multiplayer.is_server():
		_espera_servidor = maxf(_espera_servidor - delta, 0.0)
		_actualizar_estado(delta)
	if not is_multiplayer_authority():
		return
	_espera -= delta
	_aturdido -= delta
	if caido or bebiendo > 0 or dormido > 0 or vomitando > 0:
		manteniendo = false
		velocity = Vector2.ZERO
		return
	if rodando > 0:
		manteniendo = false
		velocity = direccion_rodar * 500.0
		move_and_slide()
		return

	var en_suelo := altura <= 0.0 and _vel_altura <= 0.0
	if en_suelo:
		altura = 0.0
		_vel_altura = 0.0
		_volando = false
	else:
		_vel_altura -= GRAVEDAD * delta
		altura = maxf(altura + _vel_altura * delta, 0.0)

	if _aturdido > 0.0 or aturdimiento > 0.0 or _volando:
		manteniendo = false
		if en_suelo:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	else:
		var dir := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
		var salta := Input.is_action_just_pressed("saltar")
		var pega := Input.is_action_just_pressed("golpear")
		var agarra := Input.is_action_just_pressed("agarrar")
		manteniendo = Input.is_action_pressed("agarrar")
		if Input.is_action_just_pressed("beber"):
			if multiplayer.is_server():
				pedir_beber()
			else:
				pedir_beber.rpc_id(1)
			manteniendo = false
			return
		if Input.is_action_just_pressed("esquivar"):
			if multiplayer.is_server():
				pedir_rodar(dir)
			else:
				pedir_rodar.rpc_id(1, dir)
			manteniendo = false
			return
		if _bot:
			var bot := _bot_pelea() if _bot == "pelea" else _bot_mision(delta)
			dir = bot.dir
			salta = false
			pega = bot.pega
			agarra = bot.agarra
			manteniendo = bot.mantiene

		var nivel := nivel_borrachera()
		if dir != Vector2.ZERO and nivel > 0:
			var onda := sin(Time.get_ticks_msec() * 0.004 + float(name.to_int() % 20))
			dir = dir.rotated(onda * [0.0, 0.12, 0.4, 1.15][nivel])
		var freno := FRENO_CARGANDO if _pieza_cargada() else 1.0
		freno *= 0.65 if nivel == 3 else 1.0
		velocity = Vector2(dir.x * VELOCIDAD, dir.y * VELOCIDAD_FONDO) * freno
		if dir.x != 0.0:
			mirando = int(signf(dir.x))
		if salta and en_suelo:
			_vel_altura = SALTO
		if pega and _espera <= 0.0:
			_espera = ESPERA_GOLPE
			if multiplayer.is_server():
				golpear(mirando)
			else:
				golpear.rpc_id(1, mirando)
		if agarra:
			if multiplayer.is_server():
				pedir_agarrar()
			else:
				pedir_agarrar.rpc_id(1)

	move_and_slide()


func _process(delta: float) -> void:
	_tiempo_aviso_bebida = maxf(_tiempo_aviso_bebida - delta, 0.0)
	_parpadeo -= delta
	_golpe_visible -= delta
	visual.position.y = -altura
	visual.rotation = PI / 2 if caido else sin(Time.get_ticks_msec() * 0.008) * 0.1 * nivel_borrachera()
	if rodando > 0:
		visual.rotation = TAU * (1.0 - rodando / DURACION_RODAR) * (mirando if direccion_rodar.x == 0 else signf(direccion_rodar.x))
	sombra.modulate.a = clampf(1.0 - altura / 200.0, 0.3, 1.0)
	cuerpo.color = Color.WHITE if _parpadeo > 0.0 else COLORES[color_indice % COLORES.size()]
	ojo.position.x = 4.0 if mirando > 0 else -12.0
	golpe.visible = _golpe_visible > 0.0
	golpe.position.x = 16.0 if mirando > 0 else -16.0 - golpe.size.x
	etiqueta.text = "%s · %d\n%s" % [nombre, vida, texto_estado()]
	etiqueta.rotation = -visual.rotation
	etiqueta.global_position = global_position + Vector2(-70, -84 - altura)
	if is_multiplayer_authority():
		var camara := get_viewport().get_camera_2d()
		if camara:
			camara.global_position = global_position


@rpc("authority", "call_local", "reliable")
func golpear(dir: int) -> void:
	if not multiplayer.is_server():
		return
	if dir not in [-1, 1] or _espera_servidor > 0.0 or not puede_actuar():
		return
	var nivel := nivel_borrachera()
	_dano_ataque = [10, 15, 22, 30][nivel]
	_espera_servidor = 0.7 if nivel == 3 else ESPERA_GOLPE
	# Borracho puedes equivocarte de lado: también cuenta como fuego amigo.
	if nivel == 2 and randf() < 0.2:
		dir = -dir
	_mostrar_golpe.rpc(dir)
	# Fuego amigo: el golpe le pega a cualquier otro jugador que esté enfrente,
	# más o menos en la misma línea del suelo y a la misma altura.
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and _alcanza(otro.position, dir) and absf(otro.altura - altura) <= ALTURA_GOLPE:
			print("%s golpea a %s (vida %d)" % [name, otro.name, otro.vida])
			otro.recibir_golpe(dir, _dano_ataque, 1.8 if nivel == 3 else 1.0, name.to_int())
	# Enemigos y cosas del escenario (abejas, jefe, olla, oseznos).
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		if _alcanza(cosa.global_position, dir, cosa.ancho):
			cosa.golpeada(dir, self)


@rpc("any_peer", "call_local", "reliable")
func _mostrar_golpe(dir: int) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	mirando = dir
	_golpe_visible = 0.12


## Solo el anfitrión aplica daño. `fuerza` multiplica el empujón.
func recibir_golpe(dir: int, dano: int, fuerza: float, atacante := 0) -> void:
	if not multiplayer.is_server() or caido or es_invulnerable() or _partida().finalizada:
		return
	if atacante != 0:
		_partida().sumar(name.to_int(), "fuego_amigo", mini(vida, dano))
	_interrumpir_bebida()
	aturdimiento = maxf(aturdimiento, 0.5 * fuerza)
	_inicio_vuelo = position
	_tiempo_vuelo = 0.25
	_midiendo_vuelo = true
	var pieza := _pieza_cargada()
	if pieza:
		pieza.soltar(position)
	_aplicar_empujon.rpc(dir, fuerza)
	_perder_vida(dano)


@rpc("any_peer", "call_local", "reliable")
func _aplicar_empujon(dir: int, fuerza: float) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.15
	if is_multiplayer_authority():
		velocity = Vector2(EMPUJON * dir * fuerza, 0.0)
		_vel_altura = EMPUJON_ARRIBA * fuerza
		_volando = true
		_aturdido = 0.25


## Te deja sin poder moverte unos segundos (rugido de Mamá Osa).
func aturdir(segundos: float) -> void:
	if multiplayer.is_server() and not caido and not es_invulnerable() and not _partida().finalizada:
		_interrumpir_bebida()
		aturdimiento = maxf(aturdimiento, segundos)
		_aplicar_aturdimiento.rpc(segundos)


@rpc("any_peer", "call_local", "reliable")
func _aplicar_aturdimiento(segundos: float) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.3
	if is_multiplayer_authority():
		_aturdido = maxf(_aturdido, segundos)


## Daño sin empujón (piquetes de abeja y cosas así).
func recibir_dano(dano: int) -> void:
	if not multiplayer.is_server() or caido or es_invulnerable() or _partida().finalizada:
		return
	_interrumpir_bebida()
	_mostrar_dano.rpc()
	_perder_vida(dano)


@rpc("any_peer", "call_local", "reliable")
func _mostrar_dano() -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.1


## El jugador le pide al anfitrión agarrar la pieza más cercana, o soltar /
## entregar la que ya carga.
@rpc("any_peer", "call_remote", "reliable")
func pedir_agarrar() -> void:
	if not multiplayer.is_server() or not _lo_pide_su_dueno() or not puede_actuar() or altura > 12:
		return
	if companero_caido() != null and _pieza_cargada() == null:
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
		return
	for cerveza in get_tree().get_nodes_in_group("cervezas"):
		if cerveza.recoger(self):
			return


func _perder_vida(dano: int) -> void:
	if not multiplayer.is_server() or dano <= 0:
		return
	vida = maxi(vida - dano, 0)
	if vida > 0:
		return
	caido = true
	bebiendo = 0.0
	rodando = 0.0
	dormido = 0.0
	vomitando = 0.0
	reanimacion = 0.0
	var cargada := _pieza_cargada()
	if cargada:
		cargada.soltar(position)
	_reaparecer.rpc(position)


@rpc("any_peer", "call_local", "reliable")
func _reaparecer(donde: Vector2) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	velocity = Vector2.ZERO
	altura = 0.0
	_vel_altura = 0.0
	_volando = false
	_aturdido = 0.0
	manteniendo = false
	position = donde


func _alcanza(donde: Vector2, dir: int, ancho := 0.0) -> bool:
	var d := donde - position
	var alcance := 90.0 if nivel_borrachera() == 3 else ALCANCE_GOLPE
	return (d.x * dir > -8.0 - ancho and absf(d.x) <= alcance + ancho
			and absf(d.y) <= FONDO_GOLPE + ancho * 0.4)


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


func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")


func nivel_borrachera() -> int:
	return mini(int(borrachera / 25.0), 3)


func dano_actual() -> int:
	return _dano_ataque


func puede_actuar() -> bool:
	return not caido and bebiendo <= 0 and dormido <= 0 and vomitando <= 0 \
		and rodando <= 0 and aturdimiento <= 0 and not _partida().finalizada


func es_invulnerable() -> bool:
	return proteccion > 0 or rodando > DURACION_RODAR - 0.2


func companero_caido() -> Node2D:
	for otro in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and otro.caido and position.distance_to(otro.position) <= RADIO_REVIVIR:
			return otro
	return null


func puede_ayudar() -> bool:
	return puede_actuar() and altura <= 12 and _pieza_cargada() == null


func texto_estado() -> String:
	if caido:
		return "CAÍDO · E/Y: %d%%" % (reanimacion * 100)
	if bebiendo > 0:
		return "Bebiendo… %d%%" % ((1 - bebiendo / TIEMPO_BEBER) * 100)
	if vomitando > 0:
		return "¡BUAAARGH!"
	if dormido > 0:
		return "Zzz…"
	if rodando > 0:
		return "Rodando"
	if aturdimiento > 0:
		return "Aturdido"
	if nivel_borrachera() == 3 and _golpe_visible > 0:
		return "¡Ven pa'cá!"
	return NIVELES[nivel_borrachera()]


func aviso_bebida() -> String:
	return _aviso_bebida if _tiempo_aviso_bebida > 0 else ""


@rpc("any_peer", "call_local", "reliable")
func _avisar_bebida(texto: String) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_aviso_bebida = texto
	_tiempo_aviso_bebida = 3.0


func _interrumpir_bebida() -> void:
	if bebiendo > 0:
		bebiendo = 0.0
		_avisar_bebida.rpc("Bebida interrumpida · conservas la chela")


@rpc("authority", "call_local", "reliable")
func pedir_beber() -> void:
	if not multiplayer.is_server() or not puede_actuar():
		return
	if cervezas <= 0:
		_avisar_bebida.rpc("Sin chelas · recoge más con E / Y")
		return
	if altura > 0:
		_avisar_bebida.rpc("Espera a tocar el suelo para beber")
		return
	if _pieza_cargada() != null:
		_avisar_bebida.rpc("Suelta la pieza con E / Y para beber")
		return
	bebiendo = TIEMPO_BEBER
	manteniendo = false


@rpc("authority", "call_local", "reliable")
func pedir_rodar(direccion: Vector2) -> void:
	if not multiplayer.is_server() or not puede_actuar() or espera_rodar > 0 or altura > 0:
		return
	if not direccion.is_finite():
		return
	direccion_rodar = direccion.normalized() if direccion.length() > 0.1 else Vector2(mirando, 0)
	rodando = DURACION_RODAR
	espera_rodar = ESPERA_RODAR
	manteniendo = false
	var pieza := _pieza_cargada()
	if pieza:
		pieza.soltar(position)


func _actualizar_estado(delta: float) -> void:
	rodando = maxf(rodando - delta, 0)
	espera_rodar = maxf(espera_rodar - delta, 0)
	proteccion = maxf(proteccion - delta, 0)
	aturdimiento = maxf(aturdimiento - delta, 0)
	dormido = maxf(dormido - delta, 0)
	vomitando = maxf(vomitando - delta, 0)
	if _midiendo_vuelo:
		_tiempo_vuelo -= delta
		_partida().registrar_vuelo(name.to_int(), position.distance_to(_inicio_vuelo))
		if _tiempo_vuelo <= 0 and altura <= 0:
			_midiendo_vuelo = false
	if caido:
		var ayudantes := []
		for otro in get_tree().get_nodes_in_group("jugadores"):
			if otro != self and otro.manteniendo and otro.puede_ayudar() \
					and otro.companero_caido() == self:
				ayudantes.append(otro)
		reanimacion = minf(reanimacion + delta * ayudantes.size() / TIEMPO_REVIVIR, 1.0) if not ayudantes.is_empty() else 0.0
		if reanimacion >= 1.0:
			for ayudante in ayudantes:
				_partida().sumar(ayudante.name.to_int(), "rescates")
			levantar()
		return
	if bebiendo > 0:
		bebiendo = maxf(bebiendo - delta, 0)
		if bebiendo == 0:
			cervezas -= 1
			vida = mini(vida + CURA_CERVEZA, VIDA_MAX)
			borrachera += BORRACHERA_POR_CERVEZA
			_espera_sobriedad = ESPERA_SOBRIEDAD
			_partida().sumar(name.to_int(), "cervezas")
			_avisar_bebida.rpc("¡Salud! +30 de borrachera")
			if borrachera >= 100:
				vomitando = 2.5
				borrachera = 70.0
				_partida().vomitar(self)
	else:
		var tiempo_sobrio := maxf(delta - _espera_sobriedad, 0.0)
		_espera_sobriedad = maxf(_espera_sobriedad - delta, 0.0)
		borrachera = maxf(borrachera - tiempo_sobrio * BAJADA_BORRACHERA, 0)
	if nivel_borrachera() == 3 and bebiendo <= 0 and rodando <= 0 and altura <= 0 and aturdimiento <= 0:
		_sueno += delta
		if _sueno >= 6.0:
			_sueno = 0.0
			dormido = 2.5
			var jefe := get_tree().get_first_node_in_group("jefe")
			if jefe and jefe.activa and jefe.estado != "derrotada":
				_partida().sumar(name.to_int(), "dormidas")
	else:
		_sueno = 0.0


func levantar() -> void:
	if not multiplayer.is_server() or not caido:
		return
	caido = false
	vida = 40
	reanimacion = 0.0
	proteccion = 1.5
	aturdimiento = 0.0
	_midiendo_vuelo = false
	_reaparecer.rpc(position)


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
	if estacion == null or "--bot-flojo" in OS.get_cmdline_user_args() and estacion.terminada:
		return orden
	if estacion.alimentados:
		# Misión cumplida: a pelear contra el jefe.
		var jefe: Node2D = get_tree().get_first_node_in_group("jefe")
		if jefe and jefe.visible and jefe.vida > 0:
			var hacia := jefe.position - position
			mirando = 1 if hacia.x >= 0.0 else -1
			if _alcanza(jefe.position, mirando, jefe.ancho - 8.0):
				orden.pega = true
			else:
				orden.dir = (hacia - Vector2(mirando * 60.0, 0.0)).normalized()
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
