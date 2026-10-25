extends Node2D
## Un encuentro por ronda a la vez, compartido por todos los panales.
## El servidor cuenta bajas, sortea la fusión y resuelve el forcejeo.
## Ciclo: se acerca → combo de boxeo → forcejeo (machacar E). Si el jugador gana,
## la noquea al instante; si pierde, queda K.O. y la abeja le sigue pegando un
## rato antes de volver a intentarlo. También se le puede bajar la vida a golpes.
const PROBABILIDAD := 0.5
const DURACION_FUSION := 1.8
const DURACION_FORCEJEO := 8.0
const FUERZA_ABEJA := 0.085
const FUERZA_PULSACION := 0.065
const INTERVALO_PULSACION := 0.075
const SEPARACION := 84.0
const VIDA_MAX := 180
const REPOSO_FUSION := 12.0
const GRUPOS_GARANTIA := 2
## Combos de boxeo (jab + recto) antes de cada forcejeo.
const GOLPES_ANTES := 3
const DURACION_GOLPE := 0.9
## Momentos del combo en que cada puño llega extendido (cuadros 4 y 7 de 12).
const CONTACTOS := [0.3, 0.6]
const DANO_GOLPE := 5
## K.O.: el jugador queda tirado y la abeja le sigue pegando.
const DURACION_PALIZA := 3.0
const INTERVALO_PALIZA := 0.6
const DANO_PALIZA := 4
const DANO_DERROTA := 15
const DURACION_MUERTE := 1.8
const ACTIVOS := ["buscando", "golpeando", "forcejeo", "paliza", "rina_osa", "forcejeo_osa"]
## Pleito con Mamá Osa cuando se pegan de casualidad: se dan de golpes y luego forcejean.
const DURACION_RINA := 2.5
const DURACION_FORCEJEO_OSA := 4.0
const INTERVALO_PUNO_OSA := 0.45
const INTERVALO_ZARPAZO_OSA := 0.65
const DANO_A_OSA := 4
const DANO_DE_OSA := 8
## Si la abeja gana el forcejeo contra la osa: daño extra y la deja mareada.
const DANO_GANA_ABEJA := 25
const MAREO_GANA_ABEJA := 1.5
## La osa es más fuerte: el forcejeo se le va cargando a ella poco a poco.
const VENTAJA_OSA := 0.1
## Al forcejear, distancia para que las patas de la osa (≈75 px al frente) toquen
## las manos de la abeja (≈51 px al frente). Medido con los cuadros normalizados.
const DISTANCIA_FORCEJEO_OSA := 160.0
const SACUDIDA_FORCEJEO := 1.1
const NO_PROVOCAR := ["derrotada", "lago", "al_lago", "llegando", "salida", "cambio_fase", "tambaleando",
	"agarrando", "lanzando", "aviso_agarre", "rivalidad"]
const ESTRELLAS := preload("res://scripts/mama_osa.gd")

var estado := "inactiva"
var bajas := 0
var _reposo := 0.0
var _grupos_sin_fusion := 0
var _premio_entregado := false
var contendiente := 0
var noqueado := 0
var encuentro := 0
var fuerza := 0.5
var tiempo := 0.0
var lado := 1
var vida := VIDA_MAX
var ganados := 0
var perdidos := 0
var golpes_previos := 0
var caminando := false
var origenes := PackedVector2Array()
var azar := RandomNumberGenerator.new()
## Para los golpes y las botellas de los jugadores (grupo "golpeables").
var ancho := 22.0
var alto_botella := 80.0
var _bajas_recientes := PackedVector2Array()
var _ultima_pulsacion := -100.0
var _busqueda := 0.0
var _blanco := 0
var _siguiente_contacto := 0
var _siguiente_puno := 0.0
var _siguiente_zarpazo := 0.0
var _vida_vista := VIDA_MAX
var _parpadeo := 0.0
var _sprite: AnimatedSprite2D
var _anuncio: Label
var _estrellas: Node2D
var _zumbido: AudioStreamPlayer


func _ready() -> void:
	add_to_group("abeja_musculosa")
	process_physics_priority = 20
	azar.randomize()
	var replica := SceneReplicationConfig.new()
	for propiedad in ["position", "estado", "bajas", "contendiente", "noqueado", "encuentro", "fuerza", "tiempo",
			"lado", "vida", "ganados", "perdidos", "origenes", "golpes_previos", "caminando"]:
		var ruta := NodePath(".:" + propiedad)
		replica.add_property(ruta)
		replica.property_set_replication_mode(ruta, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sincronizador := MultiplayerSynchronizer.new()
	sincronizador.name = "Sincronizador"
	sincronizador.replication_config = replica
	sincronizador.replication_interval = 0.05
	add_child(sincronizador)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFrames.new()
	_sprite.sprite_frames.remove_animation("default")
	# Animación -> [segundos por vuelta, si se repite].
	var animaciones := {"quieto": [1.0, true], "caminar": [0.6, true], "boxeo": [DURACION_GOLPE, true],
		"forcejeo": [0.65, true], "forcejeo_arriba": [0.9, true], "muerte": [1.1, false]}
	for anim: String in animaciones:
		_sprite.sprite_frames.add_animation(anim)
		# El forcejeo generado incluye entrada/salida; el agarre repite solo las manos extendidas.
		var n := 3 if anim == "forcejeo" else 0
		while ResourceLoader.exists("res://arte/abeja_musculosa/%s/%d.png" % [anim, n]):
			if anim == "forcejeo" and n > 6:
				break
			_sprite.sprite_frames.add_frame(anim, load("res://arte/abeja_musculosa/%s/%d.png" % [anim, n]))
			n += 1
		_sprite.sprite_frames.set_animation_speed(anim, maxi(_sprite.sprite_frames.get_frame_count(anim), 1) / animaciones[anim][0])
		_sprite.sprite_frames.set_animation_loop(anim, animaciones[anim][1])
	_sprite.scale = Vector2(3, 3)
	_sprite.offset = Vector2(0, -32)
	add_child(_sprite)
	_anuncio = Label.new()
	_anuncio.position = Vector2(-150, -165)
	_anuncio.size = Vector2(300, 36)
	_anuncio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anuncio.add_theme_color_override("font_color", Color("ffdf6b"))
	_anuncio.add_theme_color_override("font_shadow_color", Color.BLACK)
	_anuncio.add_theme_constant_override("shadow_offset_x", 2)
	_anuncio.add_theme_constant_override("shadow_offset_y", 2)
	_anuncio.z_index = 10
	add_child(_anuncio)
	# Estrellitas de mareo sobre el jugador noqueado.
	_estrellas = ESTRELLAS.Estrellas.new()
	_estrellas.z_index = 20
	_estrellas.visible = false
	add_child(_estrellas)


func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")


func _jugador(id: int) -> Node2D:
	return get_parent().get_node_or_null("Jugadores/%d" % id)


func registrar_baja(sitio: Vector2) -> void:
	if not multiplayer.is_server() or _partida().finalizada:
		return
	bajas += 1
	_bajas_recientes.append(sitio)
	if _bajas_recientes.size() < 3:
		return
	# Los grupos se consumen incluso con una musculosa activa: no se acumulan emboscadas.
	if estado == "inactiva" and _reposo <= 0:
		_grupos_sin_fusion += 1
		if azar.randf() < PROBABILIDAD or _grupos_sin_fusion >= GRUPOS_GARANTIA:
			_grupos_sin_fusion = 0
			_fusionar.rpc(_bajas_recientes, encuentro + 1)
	_bajas_recientes.clear()


@rpc("authority", "call_local", "reliable")
func _fusionar(desde: PackedVector2Array, numero: int) -> void:
	_premio_entregado = false
	origenes = desde
	position = desde[2]
	estado = "fusion"
	tiempo = 0.0
	encuentro = numero
	contendiente = 0
	noqueado = 0
	fuerza = 0.5
	vida = VIDA_MAX
	_vida_vista = VIDA_MAX
	golpes_previos = 0
	_busqueda = 0


func _elegible(j: Node2D) -> bool:
	return is_instance_valid(j) and j.puede_actuar() and not j.es_invulnerable() \
		and j.altura <= 8 and j.apoyo_id == 0 and j._sujeto <= 0 and not j._volando \
		and j.combate.parada <= 0


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if _partida().finalizada:
		cancelar()
		return
	_reposo = maxf(_reposo - delta, 0.0)
	tiempo += delta
	caminando = false
	if estado in ["buscando", "golpeando"]:
		_busqueda += delta
		if _busqueda >= 15:
			_resolver("escapo")
			return
	match estado:
		"fusion":
			if tiempo >= DURACION_FUSION:
				estado = "buscando"
				tiempo = 0
		"buscando":
			var objetivo: Node2D = null
			for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
				if _elegible(j) and position.distance_to(j.position) < 600 \
						and (objetivo == null or position.distance_to(j.position) < position.distance_to(objetivo.position)):
					objetivo = j
			if objetivo:
				lado = 1 if position.x >= objetivo.position.x else -1
				var destino: Vector2 = objetivo.position + Vector2(lado * SEPARACION, 0)
				caminando = position.distance_to(destino) > 5
				position = position.move_toward(destino, 150 * delta)
				if position.distance_to(destino) <= 5:
					if golpes_previos < GOLPES_ANTES:
						_blanco = objetivo.name.to_int()
						golpes_previos += 1
						_siguiente_contacto = 0
						estado = "golpeando"
						tiempo = 0
					else:
						_empezar(objetivo)
		"golpeando":
			if _siguiente_contacto < CONTACTOS.size() and tiempo >= CONTACTOS[_siguiente_contacto]:
				_siguiente_contacto += 1
				_punetazo(_jugador(_blanco), DANO_GOLPE, true)
			if tiempo >= DURACION_GOLPE:
				estado = "buscando"
				tiempo = 0
		"forcejeo":
			var j := _jugador(contendiente)
			if j == null or j.caido or j.vida <= 0:
				cancelar()
				return
			if tiempo > 0.35:
				fuerza = maxf(fuerza - FUERZA_ABEJA * delta, 0)
			if fuerza <= 0 or tiempo >= DURACION_FORCEJEO:
				_resolver("derrota")
		"paliza":
			var j := _jugador(noqueado)
			if j == null or j.caido or tiempo >= DURACION_PALIZA:
				_terminar_paliza(j)
				return
			# Se acerca al noqueado y le sigue pegando mientras está tirado.
			lado = 1 if position.x >= j.position.x else -1
			var destino: Vector2 = j.position + Vector2(lado * SEPARACION * 0.8, 0)
			caminando = position.distance_to(destino) > 6
			position = position.move_toward(destino, 170 * delta)
			_siguiente_puno -= delta
			if not caminando and _siguiente_puno <= 0:
				_siguiente_puno = INTERVALO_PALIZA
				_punetazo(j, DANO_PALIZA, false)
		"rina_osa":
			var oso := _oso()
			if not _osa_disponible(oso, true):
				_fin_rivalidad(oso, "nadie")
				return
			# Se pone a su lado, de frente, y se dan con todo.
			lado = 1 if position.x >= oso.position.x else -1
			oso.mirando = lado
			var destino: Vector2 = oso.position + Vector2(lado * (oso.ancho + 45), 0)
			caminando = position.distance_to(destino) > 6
			position = position.move_toward(destino, 200 * delta)
			if not caminando:
				_siguiente_puno -= delta
				_siguiente_zarpazo -= delta
				if _siguiente_puno <= 0:
					_siguiente_puno = INTERVALO_PUNO_OSA
					oso.danar_por_abeja(DANO_A_OSA)
					_impacto_rina(oso.global_position + Vector2(lado * oso.ancho * 0.5, -90))
				if _siguiente_zarpazo <= 0:
					_siguiente_zarpazo = INTERVALO_ZARPAZO_OSA
					vida = maxi(vida - DANO_DE_OSA, 0)
					_impacto_rina(global_position - Vector2(0, 60))
			if vida == 0:
				_fin_rivalidad(oso, "osa")
			elif tiempo >= DURACION_RINA:
				estado = "forcejeo_osa"
				tiempo = 0
				fuerza = 0.5
		"forcejeo_osa":
			var oso := _oso()
			if not _osa_disponible(oso, true):
				_fin_rivalidad(oso, "nadie")
				return
			position = position.move_toward(oso.position + Vector2(lado * DISTANCIA_FORCEJEO_OSA, 0), 120 * delta)
			# Nadie lo controla: se mece al azar, con ventaja para la osa.
			fuerza = clampf(fuerza + (azar.randf_range(-1, 1) * SACUDIDA_FORCEJEO - VENTAJA_OSA) * delta, 0, 1)
			if fuerza <= 0 or fuerza >= 1 or tiempo >= DURACION_FORCEJEO_OSA:
				_fin_rivalidad(oso, "abeja" if fuerza > 0.5 else "osa")
		"muriendo":
			if tiempo >= DURACION_MUERTE:
				estado = "inactiva"
		"escapo":
			if tiempo >= 1.2:
				estado = "inactiva"


func _oso() -> Node2D:
	return get_tree().get_first_node_in_group("jefe")


func _osa_disponible(oso: Node2D, ya_peleando := false) -> bool:
	if oso == null or not oso.activa or oso.fase == 4 or estado not in ACTIVOS:
		return false
	return oso.estado == "rivalidad" if ya_peleando else oso.estado not in NO_PROVOCAR


## Mamá Osa y la abeja se pegaron de casualidad: dejan a los jugadores y se pelean.
func provocar_osa() -> void:
	var oso := _oso()
	if not multiplayer.is_server() or not _osa_disponible(oso) or estado in ["rina_osa", "forcejeo_osa"]:
		return
	var atrapado := _jugador(contendiente)
	var castigado := _jugador(noqueado)
	noqueado = 0
	_soltar.rpc("rina_osa")
	for j in [atrapado, castigado]:
		if j != null:
			j.proteccion = maxf(j.proteccion, 1.0)
	_siguiente_puno = 0.2
	_siguiente_zarpazo = 0.4
	oso.empezar_rivalidad()


## ganador: "abeja", "osa" o "nadie" (la osa se fue: lago, derrota, fin de ronda).
func _fin_rivalidad(oso: Node2D, ganador: String) -> void:
	if oso != null and oso.estado == "rivalidad":
		oso.terminar_rivalidad()
		if ganador == "abeja":
			oso.danar_por_abeja(DANO_GANA_ABEJA)
			oso.tambalear(MAREO_GANA_ABEJA)
	if ganador != "osa" and vida > 0:
		# Se queda con ganas: vuelve a buscar a los jugadores.
		golpes_previos = 0
		_busqueda = 0
		estado = "buscando"
		tiempo = 0
	else:
		_resolver("noqueada")


@rpc("authority", "call_local", "reliable")
func _mostrar_impacto_rina(donde: Vector2) -> void:
	var efecto := preload("res://scripts/impacto_comic.gd").new()
	efecto.tipo = azar.randi_range(0, 3)
	get_parent().add_child(efecto)
	efecto.global_position = donde


func _impacto_rina(donde: Vector2) -> void:
	_mostrar_impacto_rina.rpc(donde)


func _punetazo(j: Node2D, dano: int, se_puede_esquivar: bool) -> void:
	# Si la osa está en la línea del puño, también se lo lleva... y se arma el pleito.
	var oso := _oso()
	if se_puede_esquivar and _osa_disponible(oso):
		var a_osa: Vector2 = oso.position - position
		if a_osa.x * -lado >= -8 and absf(a_osa.x) <= 100 + oso.ancho and absf(a_osa.y) <= 30:
			oso.danar_por_abeja(dano)
			_impacto_rina(oso.global_position - Vector2(0, 90))
			provocar_osa()
			return
	if j == null or j.caido:
		return
	var d: Vector2 = j.position - position
	if se_puede_esquivar and (d.x * -lado < -8 or absf(d.x) > 100 or absf(d.y) > 24 or j.altura > 18):
		return
	if se_puede_esquivar and j.combate.intentar_parada(self):
		return
	var antes: int = j.vida
	j.recibir_dano(dano)
	if j.vida < antes:
		j.combo.mostrar_impacto.rpc(j.position - Vector2(0, 45), _siguiente_contacto % 4, false)


func _empezar(j: Node2D) -> void:
	_partida().torre.romper_desde(j)
	var pieza: Node2D = j._pieza_cargada()
	if pieza:
		pieza.soltar(j.position)
	_ultima_pulsacion = -100
	_trabar.rpc(j.name.to_int(), position, lado)


@rpc("authority", "call_local", "reliable")
func _trabar(id: int, donde: Vector2, direccion: int) -> void:
	position = donde
	lado = direccion
	contendiente = id
	fuerza = 0.5
	tiempo = 0
	estado = "forcejeo"
	var j := _jugador(id)
	if j == null:
		return
	j._cancelar_golpes()
	j.combo.reiniciar()
	j.combate._cancelar()
	j._anim_golpe = 0
	j._anim_lanzar = 0
	j._apuntando_botella = false
	j._lanzamiento_compa = false
	j._carga_botella = 0
	j._bot_espera = 0.45
	j.manteniendo = false
	j.velocity = Vector2.ZERO
	j._vel_altura = 0
	j._volando = false
	j.altura = 0
	j.mirando = lado
	j.position = posicion_compa()


func posicion_compa() -> Vector2:
	return position - Vector2(lado * SEPARACION, 0)


func empuje_visual() -> Vector2:
	# Contra el jugador "fuerza" es la del jugador (la abeja retrocede); contra la osa, la suya (avanza).
	var empuje := fuerza - 0.5 if estado == "forcejeo" else 0.5 - fuerza
	return Vector2(lado * empuje * 18 + sin(tiempo * 22) * 1.5, 0)


@rpc("any_peer", "call_remote", "reliable")
func pulsar(numero: int) -> void:
	if not multiplayer.is_server() or _partida().finalizada or estado != "forcejeo" or numero != encuentro:
		return
	var remitente := multiplayer.get_remote_sender_id()
	if (1 if remitente == 0 else remitente) != contendiente:
		return
	# Evita ráfagas de RPC y paquetes atrasados de un forcejeo anterior.
	if tiempo - _ultima_pulsacion < INTERVALO_PULSACION:
		return
	_ultima_pulsacion = tiempo
	fuerza = minf(fuerza + FUERZA_PULSACION, 1)
	if fuerza >= 1:
		_resolver("victoria")


## La llaman los golpes, el vómito y las botellas de los jugadores (solo en el anfitrión).
func golpeada(_dir: int, quien: Node2D) -> void:
	if not multiplayer.is_server() or estado not in ACTIVOS:
		return
	vida = maxi(vida - quien.dano_actual(), 0)
	if vida == 0:
		_resolver("noqueada")


func _resolver(resultado: String) -> void:
	var j := _jugador(contendiente)
	var direccion := -lado
	match resultado:
		"victoria", "noqueada":
			if resultado == "victoria":
				ganados += 1
			var castigado := _jugador(noqueado)
			if castigado:
				castigado.proteccion = maxf(castigado.proteccion, 1.0)
			if not _premio_entregado:
				_premio_entregado = true
				_partida().soltar_arma(global_position)
			_reposo = REPOSO_FUSION
			_bajas_recientes.clear()
			vida = 0
			noqueado = 0
			_soltar.rpc("muriendo")
			if j != null:
				j.proteccion = maxf(j.proteccion, 1.2)
		"derrota":
			perdidos += 1
			_soltar.rpc("paliza")
			if j != null:
				noqueado = j.name.to_int()
				_siguiente_puno = INTERVALO_PALIZA
				j.recibir_golpe(direccion, DANO_DERROTA, 0.7)
				j.aturdir(DURACION_PALIZA)
		_:
			_soltar.rpc(resultado)
			if j != null:
				j.proteccion = maxf(j.proteccion, 1.2)


func _terminar_paliza(j: Node2D) -> void:
	noqueado = 0
	if j != null and not j.caido:
		j.proteccion = maxf(j.proteccion, 1.0)
	# Vuelve a buscar pelea: otro combo y otro forcejeo.
	golpes_previos = 0
	_busqueda = 0
	estado = "buscando"
	tiempo = 0


func cancelar() -> void:
	if multiplayer.is_server() and (estado != "inactiva" or contendiente != 0 or noqueado != 0):
		noqueado = 0
		var oso := _oso()
		if oso != null and oso.estado == "rivalidad":
			oso.terminar_rivalidad()
		_soltar.rpc("inactiva")


@rpc("authority", "call_local", "reliable")
func _soltar(resultado: String) -> void:
	var j := _jugador(contendiente)
	if j != null:
		j.manteniendo = false
		j._cancelar_golpes()
	contendiente = 0
	estado = resultado
	tiempo = 0


func _process(delta: float) -> void:
	visible = estado != "inactiva"
	# Zumbido de alas, bajito, solo mientras pelea con Mamá Osa.
	if _zumbido == null:
		_zumbido = Audio.bucle(self, "abeja_zumbido")
	var con_osa := estado in ["rina_osa", "forcejeo_osa"]
	if con_osa and not _zumbido.playing:
		_zumbido.play()
	elif not con_osa and _zumbido.playing:
		_zumbido.stop()
	# Solo se le puede pegar mientras pelea; muerta o escondida no estorba.
	if (estado in ACTIVOS) != is_in_group("golpeables"):
		if estado in ACTIVOS:
			add_to_group("golpeables")
		else:
			remove_from_group("golpeables")
	if vida < _vida_vista:
		_parpadeo = 0.12
	_vida_vista = vida
	_parpadeo -= delta
	_sprite.visible = estado not in ["inactiva", "fusion"]
	_sprite.flip_h = lado > 0
	var animacion := "quieto"
	match estado:
		"forcejeo":
			animacion = "forcejeo"
		"golpeando":
			animacion = "boxeo"
		"paliza", "rina_osa":
			animacion = "caminar" if caminando else "boxeo"
		"forcejeo_osa":
			# La osa la empuja con la pata, a su altura: empuja de frente.
			animacion = "forcejeo"
		"muriendo":
			animacion = "muerte"
		_:
			animacion = "caminar" if caminando else "quieto"
	if _sprite.animation != animacion:
		_sprite.play(animacion)
	if estado == "golpeando":
		var cuadro := clampf(tiempo / DURACION_GOLPE, 0, 0.999) * _sprite.sprite_frames.get_frame_count("boxeo")
		_sprite.set_frame_and_progress(int(cuadro), fmod(cuadro, 1))
	_sprite.position = Vector2(0, sin(Time.get_ticks_msec() * 0.008) * 2) if estado != "muriendo" else Vector2.ZERO
	_sprite.modulate = Color(4, 4, 4) if _parpadeo > 0 else Color.WHITE
	if estado in ["forcejeo", "forcejeo_osa"]:
		_sprite.position = empuje_visual()
	elif estado == "muriendo":
		_sprite.modulate.a = clampf((DURACION_MUERTE - tiempo) / 0.5, 0, 1)
	elif estado == "escapo":
		_sprite.position.y -= tiempo * tiempo * 120
		_sprite.modulate.a = maxf(1 - tiempo / 1.2, 0)
	_anuncio.text = {"fusion": "¡SE ESTÁN FUSIONANDO!", "buscando": "¡ABEJA MUSCULOSA!",
		"rina_osa": "¡PLEITO CON MAMÁ OSA!", "forcejeo_osa": "¡A VER QUIÉN PUEDE MÁS!",
		"muriendo": "¡NOQUEADA!", "escapo": "¡SE ESCAPÓ!"}.get(estado, "")
	var tirado := _jugador(noqueado) if estado == "paliza" else null
	_estrellas.visible = tirado != null
	if tirado:
		# Tirado en el suelo la cabeza queda bajita.
		_estrellas.global_position = tirado.global_position + Vector2(0, -38)
	queue_redraw()


func _draw() -> void:
	if estado == "fusion":
		var fase := clampf(tiempo / DURACION_FUSION, 0, 1)
		var centro := Vector2(0, -52)
		var textura: Texture2D = load("res://arte/zona1/abeja/0.png")
		for i in 3:
			var giro := tiempo * 11 + i * TAU / 3
			var desde := origenes[i] - global_position - Vector2(0, 35) if origenes.size() == 3 else centro
			var punto := desde.lerp(centro, fase) + Vector2(cos(giro), sin(giro)) * (1 - fase) * 70
			draw_line(centro, punto, Color(1, 0.8, 0.2, 0.4), 3)
			draw_texture(textura, punto - textura.get_size() / 2, Color(1, 1, 0.65))
		for i in 12:
			var rayo := Vector2.from_angle(i * TAU / 12 + tiempo)
			draw_line(centro + rayo * (12 + fase * 10), centro + rayo * (25 + fase * 40), Color(1, 0.85, 0.35, fase), 3)
		return
	if estado == "muriendo":
		return
	draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 24, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	# Vida de la abeja, chiquita sobre su cabeza, solo cuando ya la golpearon.
	if estado in ACTIVOS and vida < VIDA_MAX:
		var caja := Rect2(-22, -132, 44, 5)
		draw_rect(caja.grow(1), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(caja.position, Vector2(caja.size.x * vida / VIDA_MAX, caja.size.y)), Color("ffcf33"))
	# Forcejeo: solo una barrita entre los dos; verde empuja desde el lado del rival.
	if estado in ["forcejeo", "forcejeo_osa"]:
		var distancia := SEPARACION
		var oso := _oso()
		if estado == "forcejeo_osa" and oso != null:
			distancia = absf(oso.position.x - position.x)
		var caja := Rect2(-lado * distancia * 0.5 - 40, -150 if estado == "forcejeo" else -275, 80, 8)
		draw_rect(caja.grow(2), Color(0, 0, 0, 0.75))
		draw_rect(caja, Color("c75336"))
		# Rojo es la abeja; el rival empuja desde su lado: verde el jugador, café la osa.
		# (Contra el jugador "fuerza" es la parte del jugador; contra la osa, la de la abeja.)
		var parte_rival := fuerza if estado == "forcejeo" else 1.0 - fuerza
		var verde := caja.size.x * parte_rival
		var inicio := caja.position.x if lado > 0 else caja.end.x - verde
		draw_rect(Rect2(inicio, caja.position.y, verde, caja.size.y), Color("53d9a0") if estado == "forcejeo" else Color("8a5a2b"))
		draw_line(Vector2(caja.get_center().x, caja.position.y - 3), Vector2(caja.get_center().x, caja.end.y + 3), Color.WHITE, 1)
