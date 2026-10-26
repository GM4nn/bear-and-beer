extends CharacterBody2D
## Jugador. Vista lateral con profundidad: `position` es
## dónde pisa en el suelo del bosque y `altura` qué tan arriba está al saltar.
## Cada quien mueve a su propio personaje y el anfitrión decide a quién le
## llegan los golpes y quién carga cada pieza (GDD sección 6).

const VELOCIDAD := 220.0
const VELOCIDAD_FONDO := 150.0
# Respuesta breve al arrancar y freno más firme para no sentirse resbaloso.
const ACELERACION := 2200.0
const FRENADO := 3200.0
const FRENO_CARGANDO := 0.75
const SALTO := 420.0
const GRAVEDAD := 1200.0
const ALCANCE_GOLPE := 46.0
const FONDO_GOLPE := 20.0
const ALTURA_GOLPE := 36.0
const ALCANCE_AGARRAR := 44.0
const ESPERA_GOLPE := 0.35
# El contacto ocurre al extender el puño, después de una preparación corta.
const TIEMPO_IMPACTO := 0.08
const CUADROS_PUNETAZO := [0.02, 0.02, 0.04, 0.03, 0.035, 0.035, 0.04, 0.04, 0.04]
const CUADROS_COMBO := {
	"puno_izquierdo": [0.01, 0.015, 0.025, 0.05, 0.035, 0.04, 0.035, 0.06, 0.05],
	"cabezazo": [0.01, 0.015, 0.025, 0.03, 0.06, 0.06, 0.06, 0.07, 0.07],
	"patada": [0.02, 0.025, 0.045, 0.07, 0.06, 0.06, 0.05, 0.065, 0.065],
}
const DANO_GOLPE := 10
const EMPUJON := 300.0
const EMPUJON_ARRIBA := 300.0
const VIDA_MAX := 100
const MAX_CERVEZAS := 6
const MAX_BOTELLAS := 6
const DANO_BOTELLA := 12
const BOTELLA_ARCO := preload("res://scripts/botella.gd")
const TIEMPO_CARGAR_BOTELLA := 1.2
const ALTURA_SUJETO := 70.0
const FRENO_NADANDO := 0.55
# Cuánto se baja el dibujo del que va en hombros, según el piso (ver _ajustar_postura_hombros).
# En el piso 2 el de abajo va sentado y sus hombros quedan 6 px más bajos que los de la base.
const BAJADA_HOMBROS := [0.0, 0.0, 6.0]
# Náusea y vómito: tiempo máximo con los cachetes inflados, arcadas (E) para
# vomitar antes, cuánto dura el vómito y su daño a lo que tenga enfrente.
const TIEMPO_NAUSEA := 4.0
const ARCADAS := 6
const FRENO_NAUSEA := 0.5
const DURACION_VOMITO := 1.3
const ALCANCE_VOMITO := 45.0
const DANO_VOMITO := 15
const DANO_VOMITO_AMIGO := 8
# Fila del cuadro (en UV) por debajo de la cual el cuerpo queda bajo el agua.
const LINEA_AGUA := 0.585
const BORRACHERA_POR_CERVEZA := 30.0
## A los 15 s sin tomar se empieza a bajar, un nivel (25) cada 15 s.
const ESPERA_SOBRIEDAD := 15.0
const BAJADA_BORRACHERA := 25.0 / 15.0
const CURA_CERVEZA := 35
const TIEMPO_BEBER := 2.0
const FRENO_BEBIENDO := 0.6
const TIEMPO_REVIVIR := 3.0
## Zona para revivir a un caído: ancha, porque acostado ocupa todo su cuerpo.
const RADIO_REVIVIR := Vector2(130.0, 55.0)
const DURACION_RODAR := 0.32
const ESPERA_RODAR := 1.1
const NIVELES := ["Sobrio", "Alegre", "Pedo", "Hasta atrás"]
const COLORES: Array[Color] = [
	Color("e0533d"), Color("3d8be0"), Color("5fc24a"),
	Color("e8c33a"), Color("a45fd6"), Color("e88a3a"),
]
# Un solo personaje para todos; el shader le pinta la playera del color de cada
# jugador. Los cuadros miran a la derecha y pasaron por
# herramientas/normalizar_sprites.ps1 (lienzo de 96x96, pies en la fila 80).
const SHADER_COLOR := preload("res://arte/jugador/color_jugador.gdshader")
const CARPETA_ARTE := "res://arte/jugador/%s/%d.png"
## Cuadros de 180x180 con los pies en la fila 153 (herramientas/normalizar_jugador.py),
## dibujados a escala 1: el desfase pone los pies en el origen del nodo.
const LIENZO_SPRITE := 180.0
const PIES_SPRITE := 153.0
const ESCALA_SPRITE := 1.0
const DESFASE_SPRITE := Vector2(0, LIENZO_SPRITE * 0.5 - PIES_SPRITE)
# Animación -> [segundos que dura una vuelta, si se repite].
const ANIMACIONES := {
	"quieto": [1.2, true], "caminar": [0.56, true], "saltar": [0.7, false],
	"golpear": [0.3, false], "lanzar": [0.4, false], "rodar": [0.32, false],
	"puno_izquierdo": [0.32, false], "parada": [0.35, false], "cabezazo": [0.40, false], "patada": [0.46, false],
	"tomar": [2.0, false], "tomar_caminar": [2.0, false], "golpeado": [0.5, false], "caido": [0.8, false],
	"dormirse": [1.2, false], "levantarse": [1.0, false], "nadar": [1.4, true],
	"nausea": [1.6, true], "vomitar": [1.3, false],
	"cargar_quieto": [1.2, true], "cargar_caminar": [0.65, true],
	"hombros_quieto": [1.2, true], "hombros_cargar": [1.2, true],
	"hombros_atrapar": [1.1, true],
	"llevar_quieto": [1.2, true], "llevar_caminar": [0.6, true],
	"cargar_golpear": [0.3, false], "hombros_golpear": [0.3, false],
	"hombros_cargar_golpear": [0.3, false],
	"forcejeo": [0.65, true],
	# Quieto y caminar según el nivel de borrachera: alegre, pedo y hasta atrás.
	"quieto_1": [2.4, true], "quieto_2": [2.2, true], "quieto_3": [3.0, true],
	"caminar_1": [0.7, true], "caminar_2": [0.85, true], "caminar_3": [1.0, true],
}

static var _cuadros: SpriteFrames

var vida := VIDA_MAX
var mirando := 1
var altura := 0.0
## Tiene presionado el botón de agarrar (sirve para construir en la estación).
var manteniendo := false
var color_indice := 0
var nombre := ""
var cervezas := 0
## Botellas vacías que le quedaron de las chelas que se tomó; se pueden lanzar.
var botellas := 0
var borrachera := 0.0
var caido := false
var reanimacion := 0.0
var arma_tiempo := 0.0
var _aguijon: Sprite2D
const MANOS := preload("res://scripts/manos_jugador.gd").MANOS
var _barra_revivir: ProgressBar
var _texto_revivir: Label
var bebiendo := 0.0
var dormido := 0.0
var vomitando := 0.0
## Segundos que le quedan aguantando el vómito (cachetes inflados).
var nausea := 0.0
## Veces que pulsó E durante la náusea.
var arcadas := 0
var rodando := 0.0
var espera_rodar := 0.0
var direccion_rodar := Vector2.RIGHT
var proteccion := 0.0
var aturdimiento := 0.0
## Id del compañero que nos sostiene. Lo decide únicamente el anfitrión.
var apoyo_id := 0

var _sueno := 0.0
var _espera_sobriedad := 0.0
var _aviso_bebida := ""
var _tiempo_aviso_bebida := 0.0
var _inicio_vuelo := Vector2.ZERO
var _tiempo_vuelo := 0.0
var _midiendo_vuelo := false
var _dano_ataque := DANO_GOLPE
var _golpe_pendiente := -1.0
var _direccion_golpe := 1
var _nivel_golpe := 0
var _tipo_golpe := 0
var _tipo_anim_golpe := 0
var _cola_golpes: Array[Dictionary] = []
## Tiempo mínimo entre el inicio de un golpe y el siguiente (las pulsaciones se guardan).
const ENTRE_GOLPES := 0.15
var _recuperacion := 0.0
var _repeticion := 0.0
var _ultimo_tipo := -1

var _vel_altura := 0.0
var _volando := false
## Segundos que le quedan sostenido en el aire por Mamá Osa.
var _sujeto := 0.0
var _espera := 0.0
var _espera_servidor := 0.0
var _aturdido := 0.0
var _parpadeo := 0.0
var _golpe_visible := 0.0
var _bot := ""
var _bot_espera := 0.0
var _bot_desvio := 0.0
var _bot_lado := Vector2.ZERO
var _bot_turno := 1
var _bot_ultimo_golpe := 0
var _bot_estaba_montado := false
var _numero_golpe := 0
var _apuntando_botella := false
var _lanzamiento_compa := false
var _carga_botella := 0.0
var combate: Node
var combo: Node

var _animacion := ""
var _posicion_vista := Vector2.ZERO
var _moviendose := 0.0
var _ritmo_pasos := 1.0
var _recorrido_visto := Vector2.ZERO
var _tiempo_recorrido := 0.0
var _rapidez_vista := 0.0
var _anim_golpe := 0.0
var _direccion_anim_golpe := 1
var _fase_paso := 0.0
var _anim_lanzar := 0.0
var _anim_levantar := 0.0
var _estaba_tirado := false
## Qué tan metido está en el agua (0 = fuera, 1 = nadando con medio cuerpo abajo).
var _hundido := 0.0
# Lo último que se oyó, para sonar solo cuando cambia (corre en todas las pantallas).
var _oido := {}
var _material: ShaderMaterial
var _chorro: CPUParticles2D
var _tecla_e: Node2D

@onready var visual: Node2D = $Visual
@onready var sombra: ColorRect = $Sombra
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var etiqueta: Label = $Visual/Vida


func _enter_tree() -> void:
	# El nodo se llama como el id del jugador que lo controla.
	set_multiplayer_authority(name.to_int())
	# El movimiento pertenece al jugador; la vida siempre al anfitrión.
	$SincronizadorVida.set_multiplayer_authority(1)


func _ready() -> void:
	add_to_group("jugadores")
	_partida().registrar(self)
	sprite.sprite_frames = _cuadros_compartidos()
	sprite.offset = DESFASE_SPRITE
	etiqueta.z_index = 10
	_posicion_vista = position
	# Cada jugador tiene su propio material para pintar la playera de su color.
	_material = ShaderMaterial.new()
	_material.shader = SHADER_COLOR
	_material.set_shader_parameter("color_jugador", COLORES[color_indice % COLORES.size()])
	sprite.material = _material
	# El aguijón va en la mano de enfrente, cuadro por cuadro (manos_jugador.gd).
	_aguijon = Sprite2D.new()
	_aguijon.texture = preload("res://arte/zona1/objetos/aguijon_mano.png")
	_aguijon.centered = false
	_aguijon.offset = Vector2(-5, -7)
	_aguijon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_aguijon.visible = false
	sprite.add_child(_aguijon)
	_chorro = _crear_chorro()
	visual.add_child(_chorro)
	_tecla_e = TeclaE.new()
	_tecla_e.position = Vector2(54, -120)
	_tecla_e.visible = false
	_tecla_e.z_index = 11
	visual.add_child(_tecla_e)
	combate = preload("res://scripts/combate_compas.gd").new()
	combate.name = "CombateCompas"
	add_child(combate)
	_barra_revivir = ProgressBar.new()
	_barra_revivir.name = "ProgresoRevivir"
	_barra_revivir.position = Vector2(-70, -44)
	_barra_revivir.size = Vector2(140, 14)
	_barra_revivir.max_value = 1.0
	_barra_revivir.show_percentage = false
	var canal_revivir := StyleBoxFlat.new()
	canal_revivir.bg_color = Color("1d120c")
	canal_revivir.border_color = Color("ffe3a1")
	canal_revivir.set_border_width_all(2)
	_barra_revivir.add_theme_stylebox_override("background", canal_revivir)
	var relleno_revivir := StyleBoxFlat.new()
	relleno_revivir.bg_color = Color("71dc78")
	_barra_revivir.add_theme_stylebox_override("fill", relleno_revivir)
	_barra_revivir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_revivir.z_index = 15
	add_child(_barra_revivir)
	_texto_revivir = Label.new()
	_texto_revivir.position = Vector2(-110, -70)
	_texto_revivir.size.x = 220
	_texto_revivir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto_revivir.add_theme_font_size_override("font_size", 13)
	_texto_revivir.add_theme_color_override("font_outline_color", Color("1d120c"))
	_texto_revivir.add_theme_constant_override("outline_size", 4)
	_texto_revivir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto_revivir.z_index = 15
	add_child(_texto_revivir)
	combo = preload("res://scripts/combo.gd").new()
	combo.name = "Combo"
	add_child(combo)
	if is_multiplayer_authority():
		var args := OS.get_cmdline_user_args()
		_bot = "torre" if "--bot-torre" in args else "mision" if "--bot-mision" in args else "pelea" if "--bot" in args else ""
		for arg in args:
			if arg.begins_with("--bot-turno="):
				_bot_turno = arg.get_slice("=", 1).to_int()


func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if _partida().finalizada:
		_cancelar_golpes()
		manteniendo = false
		return
	if multiplayer.is_server():
		arma_tiempo = maxf(arma_tiempo - delta, 0.0)
	if en_forcejeo():
		manteniendo = false
		velocity = Vector2.ZERO
		altura = 0.0
		if is_multiplayer_authority():
			var abeja: Node2D = _partida().abeja_musculosa
			position = abeja.posicion_compa()
			mirando = abeja.lado
			_bot_espera -= delta
			if Input.is_action_just_pressed("agarrar") or (not _bot.is_empty() and _bot_espera <= 0):
				_bot_espera = 0.13 # Machaca como un humano rápido.
				if multiplayer.is_server():
					abeja.pulsar(abeja.encuentro)
				else:
					abeja.pulsar.rpc_id(1, abeja.encuentro)
		return
	if multiplayer.is_server():
		_espera_servidor = maxf(_espera_servidor - delta, 0.0)
		_repeticion = maxf(_repeticion - delta, 0.0)
		_recuperacion = maxf(_recuperacion - delta, 0.0)
		_actualizar_estado(delta)
		_procesar_cola_golpes()
		_actualizar_golpe(delta)
	if en_miel():
		manteniendo = false
		velocity = Vector2.ZERO
		_cancelar_golpes()
		if is_multiplayer_authority():
			altura = 0
			_vel_altura = 0
			_partida().oleadas_miel.entrada_miel(self, delta)
		return
	if en_tienda():
		manteniendo = false
		velocity = Vector2.ZERO
		if is_multiplayer_authority() and Input.is_action_just_pressed("agarrar"):
			if multiplayer.is_server():
				pedir_agarrar()
			else:
				pedir_agarrar.rpc_id(1)
		return
	if en_rescate():
		manteniendo = false
		velocity = Vector2.ZERO
		return
	if en_fogata():
		manteniendo = false
		velocity = Vector2.ZERO
		if is_multiplayer_authority():
			if not _bot.is_empty():
				_bot_fogata(delta)
			elif Input.is_action_just_pressed("agarrar"):
				if multiplayer.is_server():
					pedir_agarrar()
				else:
					pedir_agarrar.rpc_id(1)
		return
	if not is_multiplayer_authority():
		return
	_espera -= delta
	if Input.is_action_just_pressed("parada"):
		if multiplayer.is_server():
			combate.pedir_parada(mirando)
		else:
			combate.pedir_parada.rpc_id(1, mirando)
	if Input.is_action_just_pressed("empujar_compa"):
		if multiplayer.is_server():
			combate.pedir_empujon(mirando)
		else:
			combate.pedir_empujon.rpc_id(1, mirando)
	_controlar_lanzamiento(delta)
	_aturdido -= delta
	if apoyo_id != 0:
		_controlar_hombros()
		return
	# Mientras se levanta del suelo todavía no puede moverse.
	if _anim_levantar > 0.0 and _sujeto <= 0.0 and not _volando:
		manteniendo = false
		velocity = Vector2.ZERO
		return
	if _sujeto > 0.0:
		_sujeto -= delta
		manteniendo = false
		velocity = Vector2.ZERO
		altura = ALTURA_SUJETO
		_vel_altura = 0.0
		return
	if caido or dormido > 0 or vomitando > 0:
		manteniendo = false
		velocity = Vector2.ZERO
		# Perder el equilibrio sobre hombros también cae dormido o vomitando.
		if altura > 0.0:
			_vel_altura -= GRAVEDAD * delta
			altura = maxf(altura + _vel_altura * delta, 0.0)
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
		var tipo_ataque := _entrada_ataque()
		var pega := tipo_ataque >= 0
		var agarra := Input.is_action_just_pressed("agarrar")
		manteniendo = Input.is_action_pressed("agarrar")
		# Con náusea, cada E es una arcada: al juntar suficientes, vomita.
		if nausea > 0.0 and agarra:
			if multiplayer.is_server():
				pedir_arcada()
			else:
				pedir_arcada.rpc_id(1)
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
			# La misión decide cuándo montar para el rescate; en combate ayuda a la torre.
			var modo := "mision" if _bot == "torre" and not _bot_osa_presente() else _bot
			var bot := _bot_torre(delta) if modo == "torre" else _bot_pelea() if modo == "pelea" else _bot_mision(delta)
			dir = bot.dir
			salta = bot.get("salta", false)
			pega = bot.pega
			tipo_ataque = int(bot.get("tipo", 0))
			agarra = bot.agarra
			manteniendo = bot.mantiene
			# Un bot sin nada que hacer no se queda flotando: sale a la orilla.
			if dir == Vector2.ZERO and nadando() and modo != "torre":
				dir = _bot_rumbo(position)

		var nivel := nivel_borrachera()
		if dir != Vector2.ZERO and nivel > 0:
			var onda := sin(Time.get_ticks_msec() * 0.004 + float(name.to_int() % 20))
			dir = dir.rotated(onda * [0.0, 0.12, 0.4, 1.15][nivel])
		var freno := FRENO_CARGANDO if _pieza_cargada() else 1.0
		freno *= 0.65 if nivel == 3 else 1.0
		if nausea > 0.0:
			freno *= FRENO_NAUSEA
			salta = false
		# Se puede caminar con la chela en la boca, más despacio y sin brincar.
		if bebiendo > 0.0:
			freno *= FRENO_BEBIENDO
			salta = false
		# En el lago se nada despacio y no se puede saltar.
		if nadando():
			freno *= FRENO_NADANDO
			salta = false
		var objetivo := Vector2(dir.x * VELOCIDAD, dir.y * VELOCIDAD_FONDO) * freno
		var respuesta := FRENADO if dir == Vector2.ZERO else ACELERACION
		velocity = velocity.move_toward(objetivo, respuesta * delta)
		if dir.x != 0.0:
			mirando = int(signf(dir.x))
		if salta and en_suelo:
			_vel_altura = SALTO
		if pega and (_bot.is_empty() or _espera <= 0.0):
			_espera = ESPERA_GOLPE # Ritmo de los bots; las pulsaciones humanas no se descartan.
			if multiplayer.is_server():
				golpear(mirando, tipo_ataque)
			else:
				golpear.rpc_id(1, mirando, tipo_ataque)
		if agarra:
			if multiplayer.is_server():
				pedir_agarrar()
			else:
				pedir_agarrar.rpc_id(1)

	move_and_slide()


func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_tiempo_aviso_bebida = maxf(_tiempo_aviso_bebida - delta, 0.0)
	_parpadeo -= delta
	_golpe_visible -= delta
	_anim_golpe -= delta
	_anim_lanzar -= delta
	# Una trepada breve evita aparecer de golpe en el segundo nivel.
	visual.position.y = move_toward(visual.position.y, -altura, 900.0 * delta) if apoyo_id != 0 else -altura
	sombra.modulate.a = clampf(1.0 - altura / 200.0, 0.3, 1.0)
	sombra.visible = apoyo_id == 0
	# La mano conserva el lado del ataque aunque se cambie de dirección andando.
	sprite.flip_h = (_direccion_anim_golpe if _anim_golpe > 0.0 else mirando) < 0
	_material.set_shader_parameter("destello", 0.8 if _parpadeo > 0.0 else 0.0)
	_material.set_shader_parameter("empapado", 1.0 if en_miel() else 0.0)
	# Al meterse al lago se va hundiendo hasta la cintura y se mece con el agua.
	_hundido = move_toward(_hundido, 1.0 if nadando() and not caido else 0.0, delta * 4.0)
	_sonidos()
	_material.set_shader_parameter("linea_agua", lerpf(1.0, LINEA_AGUA, _hundido))
	if _hundido > 0.0:
		visual.position.y += _hundido * (6.0 + 2.0 * sin(Time.get_ticks_msec() * 0.005))
	sombra.visible = sombra.visible and _hundido < 0.5
	queue_redraw()
	_actualizar_animacion(delta)
	_ajustar_postura_hombros()
	_poner_aguijon()
	if en_forcejeo():
		sprite.position += _partida().abeja_musculosa.empuje_visual()
	sprite.rotation = combate.tiempo_vuelo * 9.0 * combate.direccion_vuelo if combate.volando else 0.0
	if combate.volando:
		# Girar alrededor del cuerpo, conservando su posición respecto a los pies.
		sprite.position.y = -60
		sprite.offset.y += 60.0 / sprite.scale.y
	if combate.parada > 0:
		sprite.flip_h = combate.direccion_parada < 0
	# El chorro de vómito sale de la boca hacia donde mira, al inicio del vómito.
	_chorro.emitting = vomitando > DURACION_VOMITO - 0.9
	_chorro.position = Vector2(mirando * 22.0, -98.0)
	_chorro.direction = Vector2(mirando, 0.25)
	# Solo quien tiene náusea ve la tecla que debe machacar, junto a su cabeza.
	# También avisa que mantenga E junto a un compa caído para revivirlo.
	_tecla_e.visible = (nausea > 0 or en_forcejeo() or (companero_caido() != null and puede_ayudar())) \
		and is_multiplayer_authority()
	# En el forcejeo va del lado contrario a la abeja, para no taparla ni quedar bajo el nombre.
	_tecla_e.position = Vector2(-mirando * 60, -90) if en_forcejeo() else Vector2(54, -120)
	var en_torre := apoyo_id != 0 or _torre().encima(self) != null
	_barra_revivir.visible = caido
	_barra_revivir.value = reanimacion
	_texto_revivir.visible = caido
	_texto_revivir.text = "Reanimando · %d%%" % roundi(reanimacion * 100) if reanimacion > 0 else "Mantén %s para revivir" % Controles.tecla("agarrar")
	# Tu nombre y vida ya están en tu tarjeta; sobre los demás, solo nombre y vida.
	etiqueta.visible = not is_multiplayer_authority()
	etiqueta.text = "%s · %d" % [nombre, vida]
	# A un lado de cada piso: las etiquetas no tapan las caras del de arriba.
	etiqueta.global_position = global_position + Vector2(32 if en_torre else -70,
		visual.position.y - (90 if en_torre else 170))
	if is_multiplayer_authority():
		var camara := get_viewport().get_camera_2d()
		if camara:
			camara.global_position = global_position


# Elige la animación según lo que está haciendo; corre igual en todas las pantallas.
func _actualizar_animacion(delta: float) -> void:
	# El dueño usa la velocidad real (también detecta paredes); para los demás
	# medimos un tramo corto para que los paquetes de red no corten los pasos.
	var recorrido := position - _posicion_vista
	_posicion_vista = position
	if is_multiplayer_authority():
		var real := get_real_velocity()
		_rapidez_vista = Vector2(real.x / VELOCIDAD, real.y / VELOCIDAD_FONDO).length()
		# move_and_slide no se llama en algunos estados inmóviles.
		if velocity.is_zero_approx():
			_rapidez_vista = 0.0
	else:
		_tiempo_recorrido += delta
		# Ignorar teletransportes y reapariciones al medir el ritmo.
		if recorrido.length() < 60.0:
			_recorrido_visto += recorrido.abs()
		if _tiempo_recorrido >= 0.08:
			var real := _recorrido_visto / _tiempo_recorrido
			_rapidez_vista = Vector2(real.x / VELOCIDAD, real.y / VELOCIDAD_FONDO).length()
			_recorrido_visto = Vector2.ZERO
			_tiempo_recorrido = 0.0
	_moviendose = maxf(_moviendose - delta, 0.0)
	if _rapidez_vista > 0.03:
		_moviendose = 0.06
	_ritmo_pasos = move_toward(_ritmo_pasos, clampf(_rapidez_vista, 0.35, 1.25), delta * 8.0)

	# Al despertar o ser reanimado se levanta del suelo en vez de aparecer parado.
	var tirado := caido or dormido > 0 or noqueado()
	if _estaba_tirado and not tirado:
		_anim_levantar = ANIMACIONES["levantarse"][0]
	_estaba_tirado = tirado
	_anim_levantar -= delta

	# Las animaciones de cargar traen dibujadas las piernas del de arriba: solo
	# se usan si de verdad lleva a alguien (si no, salen piernas fantasma).
	var cargando := _torre().encima(self) != null
	var animacion := "quieto"
	if caido or noqueado():
		animacion = "caido"
	elif en_forcejeo():
		animacion = "forcejeo"
	elif combate.volando:
		animacion = "rodar"
	# La guardia se ve completa aunque la ventana de parada sea más corta; un golpe la corta.
	elif combate.parada > 0 or (aturdimiento <= 0 and altura <= 12 \
			and combate.espera_parada > combate.ESPERA_PARADA - ANIMACIONES["parada"][0]):
		animacion = "parada"
	elif _hundido > 0.5:
		animacion = "nadar"
	elif dormido > 0:
		animacion = "dormirse"
	elif _anim_levantar > 0.0:
		animacion = "levantarse"
	elif rodando > 0:
		animacion = "rodar"
	elif bebiendo > 0:
		animacion = "tomar_caminar" if _moviendose > 0.0 else "tomar"
	elif vomitando > 0:
		animacion = "vomitar"
	elif nausea > 0:
		animacion = "nausea"
	elif aturdimiento > 0:
		animacion = "golpeado"
	elif _anim_lanzar > 0.0:
		animacion = _ataque_hombros(cargando) if apoyo_id != 0 or cargando else "lanzar"
	elif _anim_golpe > 0.0:
		animacion = _ataque_hombros(cargando) if _tipo_anim_golpe == 0 else combo.ANIMACIONES[_tipo_anim_golpe]
	elif apoyo_id != 0 and _atrapando_osezno():
		# El de hasta arriba de la torre alza los brazos para atajar al osezno.
		animacion = "hombros_atrapar"
	elif apoyo_id != 0:
		animacion = "hombros_cargar" if cargando else "hombros_quieto"
	elif cargando:
		animacion = "cargar_caminar" if _moviendose > 0.0 and altura <= 0 else "cargar_quieto"
	elif altura > 0.0:
		animacion = "saltar"
	elif _moviendose > 0.0:
		animacion = "caminar"
	# En la torre las piernas del de arriba las dibuja quien lo carga: los dos
	# siguen con animaciones de torre (parada, patadas, combos...) o alguien se
	# queda sin piernas o con cuatro.
	if (apoyo_id != 0 or cargando) and not (caido or noqueado() or combate.volando) \
			and not animacion.begins_with("hombros") and not animacion.begins_with("cargar"):
		if _anim_golpe > 0.0 or _anim_lanzar > 0.0:
			animacion = _ataque_hombros(cargando)
		elif apoyo_id != 0:
			animacion = "hombros_cargar" if cargando else "hombros_quieto"
		else:
			animacion = "cargar_caminar" if _moviendose > 0.0 and altura <= 0 else "cargar_quieto"
	# Con una pieza (olla, leña, miel...) camina con los brazos al frente cargándola.
	if animacion in ["quieto", "caminar"] and _pieza_cargada() != null:
		animacion = "llevar_" + animacion
	# Borracho se para y camina distinto según qué tan tomado anda.
	if animacion in ["quieto", "caminar"] and nivel_borrachera() > 0:
		animacion += "_%d" % nivel_borrachera()
	if animacion != _animacion:
		# Guardar la fase normalizada para volver al mismo paso tras un puñetazo
		# o cambiar de borrachera, incluso si los ciclos tienen distintos cuadros.
		if _animacion.begins_with("caminar"):
			_fase_paso = (sprite.frame + sprite.frame_progress) / sprite.sprite_frames.get_frame_count(_animacion)
		elif _animacion.begins_with("quieto"):
			_fase_paso = 0.0
		_animacion = animacion
		sprite.play(animacion)
		if animacion.begins_with("tomar"):
			# Al empezar o dejar de caminar sigue el mismo trago, no empieza otro.
			var trago := (1.0 - bebiendo / TIEMPO_BEBER) * sprite.sprite_frames.get_frame_count(animacion)
			sprite.set_frame_and_progress(mini(int(trago), sprite.sprite_frames.get_frame_count(animacion) - 1), fmod(trago, 1.0))
		if animacion.begins_with("caminar"):
			var paso := _fase_paso * sprite.sprite_frames.get_frame_count(animacion)
			sprite.set_frame_and_progress(int(paso), fmod(paso, 1.0))
	# El ritmo de caminar no altera los tiempos de golpes, rodada ni bebida.
	sprite.speed_scale = _ritmo_pasos if animacion.begins_with("caminar") or animacion in ["cargar_caminar", "llevar_caminar"] else 1.0


func _ataque_hombros(cargando: bool) -> String:
	if apoyo_id != 0:
		return "hombros_cargar_golpear" if cargando else "hombros_golpear"
	return "cargar_golpear" if cargando else "golpear"


## Todos se dibujan del mismo tamaño. El que va arriba se baja lo necesario para
## Las piernas del de arriba las dibuja quien lo carga; el de arriba no trae piernas
## (herramientas/cortar_piernas_jinete.py) y su cadera queda detrás de la cabeza del de
## abajo, con el torso asomando por encima (ALTURA_HOMBROS en torre.gd).
func _ajustar_postura_hombros() -> void:
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE * ESCALA_SPRITE
	sprite.offset = DESFASE_SPRITE
	# La cabeza y los brazos del que carga van por delante de las piernas del de
	# arriba: cuantos más lleve encima, más adelante se dibuja.
	var arriba := 0
	var pasajero: Node2D = _torre().encima(self)
	while pasajero != null and arriba < 3:
		arriba += 1
		pasajero = _torre().encima(pasajero)
	visual.z_index = arriba
	if apoyo_id == 0:
		return
	var piso := 1
	var apoyo: Node2D = _torre().jugador(apoyo_id)
	if apoyo != null and apoyo.apoyo_id != 0:
		piso = 2
	sprite.position.y = BAJADA_HOMBROS[piso]


# Las animaciones se arman una sola vez con los cuadros de arte/jugador/<nombre>/
# y las comparten todos los jugadores.
static func _cuadros_compartidos() -> SpriteFrames:
	if _cuadros == null:
		_cuadros = SpriteFrames.new()
		_cuadros.remove_animation("default")
		for anim: String in ANIMACIONES:
			_cuadros.add_animation(anim)
			var carpeta := "golpear_fluido" if anim == "golpear" else anim
			# El forcejeo repite solo la postura de empuje, sin volver a bajar los brazos.
			var n := 1 if anim == "forcejeo" else 0
			while ResourceLoader.exists(CARPETA_ARTE % [carpeta, n]):
				var duracion: float = CUADROS_PUNETAZO[mini(n, CUADROS_PUNETAZO.size() - 1)] if anim.ends_with("golpear") else 1.0
				if CUADROS_COMBO.has(anim):
					duracion = CUADROS_COMBO[anim][n]
				var textura: Texture2D = load(CARPETA_ARTE % [carpeta, n])
				_cuadros.add_frame(anim, textura, duracion)
				n += 1
			_cuadros.set_animation_speed(anim, 1.0 if anim.ends_with("golpear") or CUADROS_COMBO.has(anim) else maxi(_cuadros.get_frame_count(anim), 1) / ANIMACIONES[anim][0])
			_cuadros.set_animation_loop(anim, ANIMACIONES[anim][1])
	return _cuadros


@rpc("authority", "call_local", "reliable")
func golpear(dir: int, tipo := 0) -> void:
	if not multiplayer.is_server():
		return
	if dir not in [-1, 1] or tipo < 0 or tipo > 3 or _espera_servidor > 0.0 or not puede_actuar():
		return
	# Repetir un puño exige recoger el brazo; alternar mantiene el combo rápido.
	if tipo == _ultimo_tipo and _repeticion > 0.0:
		return
	# Los ataques nuevos requieren equilibrio; la torre conserva sus puños coordinados.
	if tipo != 0 and (apoyo_id != 0 or _torre().encima(self) != null or _pieza_cargada() != null):
		_avisar_bebida.rpc("E/Y: baja o suelta lo que cargas para usar el combo")
		return
	if _golpe_pendiente >= 0 or not _cola_golpes.is_empty() or _recuperacion > 0:
		# Guardar una secuencia corta, sin sobrescribir un contacto que aún no ocurrió.
		if _cola_golpes.size() < 3 and (_cola_golpes.is_empty() or _cola_golpes.back().tipo != tipo):
			_cola_golpes.append({"dir": dir, "tipo": tipo})
		return
	_iniciar_golpe(dir, tipo)


func _iniciar_golpe(dir: int, tipo: int) -> void:
	# El estado puede cambiar mientras una entrada espera su contacto anterior.
	if tipo != 0 and (apoyo_id != 0 or _torre().encima(self) != null or _pieza_cargada() != null):
		_cola_golpes.clear()
		return
	var nivel := nivel_borrachera()
	# Borracho puedes equivocarte de lado: también cuenta como fuego amigo.
	if nivel == 2 and randf() < 0.2:
		dir = -dir
	_direccion_golpe = dir
	_nivel_golpe = nivel
	_tipo_golpe = tipo
	_golpe_pendiente = combo.IMPACTOS[tipo]
	_recuperacion = ENTRE_GOLPES
	_ultimo_tipo = tipo
	_repeticion = 0.30
	_mostrar_golpe.rpc(dir, tipo)


func _cancelar_golpes() -> void:
	_golpe_pendiente = -1.0
	_cola_golpes.clear()


func _procesar_cola_golpes() -> void:
	if not puede_actuar() or _espera_servidor > 0:
		_cola_golpes.clear()
		return
	if _golpe_pendiente < 0 and _recuperacion <= 0 and not _cola_golpes.is_empty():
		var siguiente: Dictionary = _cola_golpes.pop_front()
		_iniciar_golpe(siguiente.dir, siguiente.tipo)


## Solo el anfitrión resuelve un contacto por ataque; el dibujo no hace daño.
func _actualizar_golpe(delta: float) -> void:
	if _golpe_pendiente < 0.0:
		return
	if not puede_actuar():
		_cancelar_golpes()
		combo.reiniciar()
		return
	_golpe_pendiente -= delta
	if _golpe_pendiente > 0.0:
		return
	_golpe_pendiente = -1.0
	var dir := _direccion_golpe
	var nivel := _nivel_golpe
	# Una botella anterior puede impactar durante la preparación del puñetazo.
	_dano_ataque = roundi([10, 15, 22, 30][nivel] * combo.MULTIPLICADORES[_tipo_golpe])
	if arma_tiempo > 0:
		_dano_ataque = roundi(_dano_ataque * 1.5)
	var objetivo_combo: Node2D = null
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		if combo.enemigo_valido(cosa) and _alcanza(cosa.global_position, dir, cosa.ancho) and _mas_cerca(cosa, objetivo_combo):
			objetivo_combo = cosa
	var critico: bool = combo.contacto(_tipo_golpe, objetivo_combo)
	# Fuego amigo: el golpe le pega a cualquier otro jugador que esté enfrente,
	# más o menos en la misma línea del suelo y a la misma altura.
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and _alcanza(otro.position, dir) and absf(otro.altura - altura) <= ALTURA_GOLPE:
			var vida_anterior: int = otro.vida
			print("%s golpea a %s (vida %d)" % [name, otro.name, otro.vida])
			otro.recibir_golpe(dir, _dano_ataque, 1.8 if nivel == 3 else 1.0, name.to_int())
			if otro.vida < vida_anterior:
				combo.mostrar_impacto.rpc(otro.global_position - Vector2(0, otro.altura + 60), _tipo_golpe, false)
	# Enemigos y cosas del escenario (abejas, jefe, olla, oseznos).
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		if cosa.is_in_group("jefe") and cosa.fase == 4 and not cosa.puede_recibir_golpe():
			continue
		if _alcanza(cosa.global_position, dir, cosa.ancho):
			var normal := _dano_ataque
			var final_combo: bool = critico and cosa == objetivo_combo
			if final_combo:
				_dano_ataque = roundi(normal * 2.5)
			elif _tipo_golpe == 0:
				_dano_ataque += _torre().bono_impacto(self, cosa, dir, normal)
			var visible_impacto: bool = not cosa.is_in_group("jefe") or combo.enemigo_valido(cosa)
			cosa.golpeada(dir, self)
			if visible_impacto:
				combo.mostrar_impacto.rpc(global_position + Vector2(dir * 45, -altura - 65), _tipo_golpe, final_combo)
			if final_combo:
				cosa.tambalear(0.9)
			_dano_ataque = normal


@rpc("any_peer", "call_local", "reliable")
func _mostrar_golpe(dir: int, tipo := 0) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_numero_golpe += 1
	mirando = dir
	_direccion_anim_golpe = dir
	_tipo_anim_golpe = tipo
	_golpe_visible = 0.12
	_anim_golpe = ANIMACIONES[combo.ANIMACIONES[tipo]][0]
	# Reiniciar un ataque repetido sin perder la fase del ciclo de caminar.
	if _animacion.ends_with("golpear") or _animacion in combo.ANIMACIONES:
		sprite.set_frame_and_progress(0, 0.0)


@rpc("any_peer", "call_local", "reliable")
func _mostrar_lanzamiento() -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	Audio.efecto("lanzar")
	_anim_lanzar = ANIMACIONES["lanzar"][0]


## Solo el anfitrión aplica daño. `fuerza` multiplica el empujón.
func recibir_golpe(dir: int, dano: int, fuerza: float, atacante := 0) -> void:
	if not multiplayer.is_server() or caido or es_invulnerable() or _partida().finalizada:
		return
	if atacante != 0:
		_partida().sumar(name.to_int(), "fuego_amigo", mini(vida, dano))
	combate.cancelar()
	combo.reiniciar()
	_cancelar_golpes()
	_torre().romper_desde(self)
	_interrumpir_bebida()
	aturdimiento = maxf(aturdimiento, 0.5 * fuerza)
	# El anfitrión cancela el agarre antes de esperar el movimiento del dueño.
	var jefe := get_tree().get_first_node_in_group("jefe")
	if jefe:
		jefe.liberar_jugador(self)
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
	_anim_golpe = 0.0
	if is_multiplayer_authority():
		_sujeto = 0.0
		velocity = Vector2(EMPUJON * dir * fuerza, 0.0)
		_vel_altura = EMPUJON_ARRIBA * fuerza
		_volando = true
		_aturdido = 0.25


## La llama el anfitrión: Mamá Osa lo agarra y lo sostiene en el aire. Un golpe
## (de ella al aventarlo, o de un compañero) lo suelta.
func sujetar(segundos: float, donde: Vector2) -> bool:
	if not multiplayer.is_server() or caido or es_invulnerable() or _partida().finalizada:
		return false
	combate.cancelar()
	_torre().romper_desde(self)
	_interrumpir_bebida()
	aturdimiento = maxf(aturdimiento, segundos)
	var pieza := _pieza_cargada()
	if pieza:
		pieza.soltar(position)
	_aplicar_sujecion.rpc(segundos, donde)
	return true


@rpc("any_peer", "call_local", "reliable")
func _aplicar_sujecion(segundos: float, donde: Vector2) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return
	_parpadeo = 0.2
	if is_multiplayer_authority():
		_sujeto = segundos
		position = donde
		velocity = Vector2.ZERO


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
	Audio.efecto("impacto", -2.0)


## El jugador le pide al anfitrión agarrar la pieza más cercana, o soltar /
## entregar la que ya carga.
@rpc("any_peer", "call_remote", "reliable")
func pedir_agarrar() -> void:
	if not multiplayer.is_server() or not _lo_pide_su_dueno():
		return
	if en_tienda():
		_partida().busqueda_olla.interactuar(self)
		return
	var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
	if en_fogata():
		fogata.salir(name.to_int())
		return
	if not puede_actuar():
		return
	if _partida().busqueda_olla.interactuar(self):
		return
	if _partida().rescate.interactuar(self):
		return
	if apoyo_id != 0:
		_torre().bajar(self, false)
		return
	if altura > 12:
		_torre().intentar_subir(self)
		return
	if _torre().encima(self) != null:
		_torre().soltar_encima(self)
		return
	if companero_caido() != null and _pieza_cargada() == null:
		return
	var cargada := _pieza_cargada()
	if cargada:
		var estacion := get_tree().get_first_node_in_group("estacion")
		if not (estacion and estacion.intentar_entregar(cargada, position)):
			cargada.soltar(position)
		return
	if fogata != null and fogata.interactuar(self):
		return
	var cerca: Node2D = null
	for pieza: Node2D in get_tree().get_nodes_in_group("piezas"):
		if pieza.disponible() and pieza.portador == 0 and not pieza.entregada and _mas_cerca(pieza, cerca):
			cerca = pieza
	if cerca and position.distance_to(cerca.position) <= ALCANCE_AGARRAR:
		cerca.agarrar(name.to_int())
		return
	for arma in get_tree().get_nodes_in_group("armas_temporales"):
		if arma.recoger(self):
			return
	for cerveza in get_tree().get_nodes_in_group("cervezas"):
		if cerveza.recoger(self):
			return


func _perder_vida(dano: int) -> void:
	if not multiplayer.is_server() or dano <= 0:
		return
	if en_tienda() and not _partida().busqueda_olla._golpe_interno:
		_partida().busqueda_olla.cancelar("¡Un compa recibió daño! Salgan a ayudarlo y entren de nuevo")
	if en_rescate():
		_partida().rescate.cancelar()
	combo.reiniciar()
	_cancelar_golpes()
	# Argumento de prueba: los jugadores casi no reciben daño, para poder ver
	# una pelea completa jugada por bots.
	if "--aguantan" in OS.get_cmdline_user_args():
		dano = maxi(dano / 8, 1)
	var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
	if fogata != null:
		fogata.salir(name.to_int())
	vida = maxi(vida - dano, 0)
	if vida > 0:
		return
	caido = true
	arma_tiempo = 0.0
	nausea = 0.0
	arcadas = 0
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
	if multiplayer.is_server():
		_torre().romper_desde(self)
	combate._cancelar()
	combo.reiniciar()
	velocity = Vector2.ZERO
	_cancelar_golpes()
	_anim_golpe = 0.0
	_fase_paso = 0.0
	altura = 0.0
	_vel_altura = 0.0
	_volando = false
	_sujeto = 0.0
	_aturdido = 0.0
	manteniendo = false
	position = donde
	_posicion_vista = donde
	_recorrido_visto = Vector2.ZERO
	_tiempo_recorrido = 0.0
	_rapidez_vista = 0.0
	_moviendose = 0.0


func _alcanza(donde: Vector2, dir: int, ancho := 0.0) -> bool:
	var d := donde - position
	var alcance := 90.0 if nivel_borrachera() == 3 else ALCANCE_GOLPE
	return (d.x * dir > -8.0 - ancho and absf(d.x) <= alcance + ancho
			and absf(d.y) <= FONDO_GOLPE + ancho * 0.4)


func _entrada_ataque() -> int:
	for tipo in range(4):
		if Input.is_action_just_pressed(["golpear", "puno_izquierdo", "cabezazo", "patada"][tipo]):
			return tipo
	return -1


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


func _torre() -> Node:
	return _partida().torre


func _controlar_hombros() -> void:
	manteniendo = false
	velocity = Vector2.ZERO
	_vel_altura = 0.0
	if not puede_actuar():
		return
	if not _bot.is_empty() and not _partida().rescate.listo():
		return # Espera la E del humano; el rescate envía el equilibrio del bot.
	if _bot == "mision":
		pedir_bajar_hombros.rpc_id(1, false)
		return
	if _bot == "torre":
		if not _bot_osa_presente():
			# Ya no hay pelea: se baja solo para seguir ayudando con la misión.
			if multiplayer.is_server():
				pedir_bajar_hombros(false)
			else:
				pedir_bajar_hombros.rpc_id(1, false)
			return
		_bot_estaba_montado = true
		_bot_acompanar_golpe()
		return
	var salto := Input.is_action_just_pressed("saltar")
	if Input.is_action_just_pressed("agarrar"):
		if multiplayer.is_server():
			pedir_agarrar()
		else:
			pedir_agarrar.rpc_id(1)
		return
	if salto:
		if multiplayer.is_server():
			pedir_bajar_hombros(salto)
		else:
			pedir_bajar_hombros.rpc_id(1, salto)
		return
	var dir := Input.get_axis("izquierda", "derecha")
	if dir != 0:
		mirando = int(signf(dir))
	var tipo := _entrada_ataque()
	if tipo >= 0:
		_espera = ESPERA_GOLPE
		if multiplayer.is_server():
			golpear(mirando, tipo)
		else:
			golpear.rpc_id(1, mirando, tipo)


@rpc("authority", "call_local", "reliable")
func pedir_bajar_hombros(saltando: bool) -> void:
	if multiplayer.is_server() and apoyo_id != 0 and puede_actuar():
		_torre().bajar(self, saltando)


func nivel_borrachera() -> int:
	return mini(int(borrachera / 25.0), 3)


func dano_actual() -> int:
	return _dano_ataque


## Iconito de la tecla E que se aprieta una y otra vez: "macháchala".
class TeclaE extends Node2D:
	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		# Cuatro apretones por segundo: baja 3 píxeles y se oscurece.
		var apretada := fmod(Time.get_ticks_msec() / 1000.0, 0.25) < 0.11
		var baja := 3.0 if apretada else 0.0
		draw_rect(Rect2(-12, -9, 24, 24), Color(0.08, 0.08, 0.1))
		draw_rect(Rect2(-11, -12 + baja, 22, 22), Color(0.08, 0.08, 0.1))
		draw_rect(Rect2(-9, -10 + baja, 18, 18), Color("b8bcc8") if apretada else Color("f2f4f8"))
		draw_string(ThemeDB.fallback_font, Vector2(-5, 5 + baja), Controles.tecla("agarrar"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(0.1, 0.1, 0.12))


func _crear_chorro() -> CPUParticles2D:
	var chorro := CPUParticles2D.new()
	chorro.emitting = false
	chorro.amount = 48
	chorro.lifetime = 0.55
	chorro.spread = 14.0
	chorro.initial_velocity_min = 180.0
	chorro.initial_velocity_max = 260.0
	chorro.gravity = Vector2(0, 700)
	chorro.scale_amount_min = 4.0
	chorro.scale_amount_max = 7.0
	var colores := Gradient.new()
	colores.set_color(0, Color("c9c44a"))
	colores.set_color(1, Color(0.55, 0.62, 0.15, 0.6))
	chorro.color_ramp = colores
	return chorro


## Está metido en el agua del lago (con los pies en el suelo, no saltando).
# Suena cuando cambia algo sincronizado: así se oye igual en todas las pantallas.
func _sonidos() -> void:
	var ahora := {"cervezas": cervezas, "bebiendo": bebiendo > 0, "caido": caido,
		"nadando": nadando(), "vomitando": vomitando > 0}
	if not _oido.is_empty():
		if ahora.cervezas > _oido.cervezas:
			Audio.efecto("recoger", -4.0)
		if ahora.bebiendo and not _oido.bebiendo:
			Audio.efecto("tomar")
		if ahora.cervezas < _oido.cervezas and randf() < 0.5:
			Audio.efecto("eructo", -4.0, 0.15)
		if ahora.caido and not _oido.caido:
			Audio.efecto("caer")
		if ahora.nadando and not _oido.nadando:
			Audio.efecto("chapuzon", -4.0)
		if ahora.vomitando and not _oido.vomitando:
			Audio.efecto("vomito")
	_oido = ahora


func nadando() -> bool:
	if altura > 0.0 or apoyo_id != 0:
		return false
	var bosque := get_tree().get_first_node_in_group("bosque")
	return bosque != null and bosque.dentro_del_lago(position)


## Mano de enfrente del cuadro que se ve, relativa al jugador (para cargar cosas).
func mano_frente() -> Vector2:
	var anim := String(sprite.animation)
	var carpeta := "golpear_fluido" if anim == "golpear" else anim
	var cuadros: Array = MANOS.get(carpeta, [Vector2(124, 82)])
	var mano: Vector2 = cuadros[mini(sprite.frame, cuadros.size() - 1)]
	var lado := -1.0 if sprite.flip_h else 1.0
	return visual.position + sprite.position + sprite.offset \
		+ Vector2((mano.x - LIENZO_SPRITE * 0.5) * lado, mano.y - LIENZO_SPRITE * 0.5)


## El aguijón sigue a la mano de enfrente del cuadro que se ve; al pegar apunta
## derecho al frente y si no, un poco hacia arriba.
func _poner_aguijon() -> void:
	var anim := String(sprite.animation)
	var carpeta := "golpear_fluido" if anim == "golpear" else anim
	_aguijon.visible = arma_tiempo > 0 and not caido and not en_forcejeo() and not en_fogata() \
			and not nadando() and MANOS.has(carpeta) and bebiendo <= 0
	if not _aguijon.visible:
		return
	var cuadros: Array = MANOS[carpeta]
	var mano: Vector2 = cuadros[mini(sprite.frame + (1 if anim == "forcejeo" else 0), cuadros.size() - 1)]
	var lado := -1.0 if sprite.flip_h else 1.0
	_aguijon.position = Vector2((mano.x - LIENZO_SPRITE * 0.5) * lado, mano.y - LIENZO_SPRITE * 0.5) + sprite.offset
	_aguijon.scale = Vector2(lado, 1)
	_aguijon.rotation = (0.0 if _anim_golpe > 0.0 else -0.35) * lado


# Ondas en el agua alrededor del que nada, a la altura de la cintura.
func _draw() -> void:
	if _apuntando_botella:
		_dibujar_trayectoria()
	if _hundido <= 0.0:
		return
	var y := visual.position.y + (LINEA_AGUA * LIENZO_SPRITE - PIES_SPRITE) * ESCALA_SPRITE
	var abre := sin(Time.get_ticks_msec() * 0.004) * 3.0
	draw_set_transform(Vector2(0, y), 0.0, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 26.0 + abre, 0.0, TAU, 24, Color(0.9, 1.0, 1.0, 0.8 * _hundido), 3.0)
	draw_arc(Vector2.ZERO, 40.0 - abre, 0.0, TAU, 24, Color(0.9, 1.0, 1.0, 0.35 * _hundido), 2.0)


func puede_actuar() -> bool:
	# Nadando solo se puede mover: ni golpear, ni rodar, ni tomar, ni lanzar.
	return not caido and bebiendo <= 0 and dormido <= 0 and vomitando <= 0 \
		and rodando <= 0 and aturdimiento <= 0 and not _partida().finalizada and not nadando() \
		and nausea <= 0 and not combate.volando and not en_forcejeo() and not en_fogata() and not en_rescate() and not en_tienda() and not en_miel()

func en_miel() -> bool:
	return _partida().oleadas_miel != null and _partida().oleadas_miel.pegados.has(name.to_int())

func en_tienda() -> bool:
	var busqueda := get_tree().get_first_node_in_group("busqueda_olla")
	return busqueda != null and busqueda.dentro(name.to_int())


func _atrapando_osezno() -> bool:
	var rescate := get_tree().get_first_node_in_group("rescate_oseznos")
	return rescate != null and rescate.estado in ["preparando", "ritmo"] 		and not rescate.torre_ids.is_empty() and rescate.torre_ids.back() == int(name)


func en_rescate() -> bool:
	var rescate := get_tree().get_first_node_in_group("rescate_oseznos")
	return rescate != null and rescate.contiene(name.to_int())


func en_fogata() -> bool:
	var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
	return fogata != null and fogata.dentro(name.to_int())


func en_forcejeo() -> bool:
	var partida := _partida()
	return partida != null and is_instance_valid(partida.abeja_musculosa) \
		and partida.abeja_musculosa.contendiente == name.to_int()


## La abeja musculosa le ganó el forcejeo: está tirado mientras le sigue pegando.
func noqueado() -> bool:
	var partida := _partida()
	return partida != null and is_instance_valid(partida.abeja_musculosa) \
		and partida.abeja_musculosa.noqueado == name.to_int()


func es_invulnerable() -> bool:
	return en_forcejeo() or proteccion > 0 or rodando > DURACION_RODAR - 0.2


func companero_caido() -> Node2D:
	var mejor: Node2D = null
	for otro in get_tree().get_nodes_in_group("jugadores"):
		if otro == self or not otro.caido:
			continue
		var d: Vector2 = (otro.position - position).abs()
		if d.x <= RADIO_REVIVIR.x and d.y <= RADIO_REVIVIR.y \
				and (mejor == null or position.distance_to(otro.position) < position.distance_to(mejor.position)):
			mejor = otro
	return mejor


func puede_ayudar() -> bool:
	return puede_actuar() and apoyo_id == 0 and _torre().encima(self) == null and altura <= 12 and _pieza_cargada() == null


func texto_estado() -> String:
	if en_forcejeo():
		return "¡FUERZA!"
	if noqueado():
		return "¡K.O.!"
	if caido:
		return "CAÍDO · E/Y: %d%%" % (reanimacion * 100)
	if combate.volando:
		return "¡En vuelo!"
	if combate.parada > 0:
		return "Parando"
	if bebiendo > 0:
		return "Bebiendo… %d%%" % ((1 - bebiendo / TIEMPO_BEBER) * 100)
	if vomitando > 0:
		return "¡BUAAARGH!"
	if nausea > 0:
		return "¡Va a vomitar!"
	if dormido > 0:
		return "Zzz…"
	if rodando > 0:
		return "Rodando"
	if aturdimiento > 0:
		return "Aturdido"
	if apoyo_id != 0:
		return "En hombros · E/Y: bajar · Espacio/A: saltar"
	if _torre().encima(self) != null:
		return "Sosteniendo torre · E/Y: soltar compañeros"
	if nivel_borrachera() == 3 and _golpe_visible > 0:
		return "¡Ven pa'cá!"
	return NIVELES[nivel_borrachera()]


func aviso_bebida() -> String:
	return Controles.indicaciones(_aviso_bebida) if _tiempo_aviso_bebida > 0 else ""


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


## Avienta hacia donde mira una de las botellas vacías que le quedaron.
@rpc("authority", "call_local", "reliable")
func pedir_lanzar(fuerza := 0.0) -> void:
	if not multiplayer.is_server() or not puede_actuar() or _espera_servidor > 0.0 or not is_finite(fuerza):
		return
	if botellas <= 0:
		_avisar_bebida.rpc("Sin botellas vacías · tómate una chela primero")
		return
	if _pieza_cargada() != null:
		_avisar_bebida.rpc("Suelta la pieza con E / Y para lanzar")
		return
	botellas -= 1
	_espera_servidor = 0.4
	# Entre más borracho, peor puntería.
	var desvio: float = randf_range(-1.0, 1.0) * [0.0, 0.08, 0.25, 0.55][nivel_borrachera()]
	_partida().lanzar_botella(self, Vector2(mirando, desvio).normalized(), clampf(fuerza, 0, 1))
	_mostrar_lanzamiento.rpc()


func cancelar_entrada_pausa() -> void:
	var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
	if fogata != null:
		fogata.limpiar_gesto(name.to_int())
		if is_multiplayer_authority():
			fogata.vista.cancelar_arrastre()
	# Soltar R dentro del menú no debe lanzar una botella ni dejar el apuntado atascado.
	manteniendo = false
	_apuntando_botella = false
	_carga_botella = 0.0
	_lanzamiento_compa = false
	queue_redraw()


func _controlar_lanzamiento(delta: float) -> void:
	if Input.is_action_just_pressed("lanzar"):
		# Elegir una sola acción al pulsar; soltar R después del compazo no gasta una botella.
		_lanzamiento_compa = apoyo_id == 0 and _torre().encima(self) != null
		if _lanzamiento_compa:
			_apuntando_botella = false
			_carga_botella = 0
			if multiplayer.is_server():
				combate.pedir_empujon(mirando)
			else:
				combate.pedir_empujon.rpc_id(1, mirando)
	if _lanzamiento_compa:
		if not Input.is_action_pressed("lanzar"):
			_lanzamiento_compa = false
		return
	if not puede_actuar() or _sujeto > 0 or _pieza_cargada() != null or _anim_golpe > 0 or combate.parada > 0:
		_apuntando_botella = false
		_carga_botella = 0
		return
	if Input.is_action_just_pressed("lanzar"):
		if botellas <= 0:
			if multiplayer.is_server():
				pedir_lanzar()
			else:
				pedir_lanzar.rpc_id(1)
			return
		_apuntando_botella = true
		_carga_botella = 0
	if not _apuntando_botella:
		return
	if Input.is_action_just_released("lanzar"):
		_apuntando_botella = false
		if multiplayer.is_server():
			pedir_lanzar(_carga_botella)
		else:
			pedir_lanzar.rpc_id(1, _carga_botella)
		return
	_carga_botella = minf(_carga_botella + delta / TIEMPO_CARGAR_BOTELLA, 1.0)


func _dibujar_trayectoria() -> void:
	var inicio := altura + BOTELLA_ARCO.ALTURA_MANO
	var duracion := BOTELLA_ARCO.tiempo_caida(inicio, _carga_botella)
	var color := Color("ffe575")
	for i in range(1, 25):
		var t := duracion * i / 24.0
		var punto := Vector2(mirando * BOTELLA_ARCO.velocidad(_carga_botella) * t,
			-BOTELLA_ARCO.alto_en(t, inicio, _carga_botella))
		draw_circle(punto, 3.5, Color(0, 0, 0, 0.65))
		draw_circle(punto, 2.0, color)
	var final := Vector2(mirando * BOTELLA_ARCO.velocidad(_carga_botella) * duracion, 0)
	draw_arc(final, 10, 0, TAU, 16, color, 2)
	draw_line(final - Vector2(14, 0), final + Vector2(14, 0), color, 2)
	var texto := "FUERZA %d%%" % roundi(_carga_botella * 100)
	draw_string_outline(ThemeDB.fallback_font, Vector2(24, -inicio - 20), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color.BLACK)
	draw_string(ThemeDB.fallback_font, Vector2(24, -inicio - 20), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)


## La llama el anfitrión cuando una botella de este jugador le pega a un enemigo
## o a algo del escenario.
func botellazo(cosa: Node2D, dir: int) -> void:
	_dano_ataque = DANO_BOTELLA
	cosa.golpeada(dir, self)


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
	# Si no junta las arcadas a tiempo, vomita de todas formas.
	if nausea > 0:
		nausea = maxf(nausea - delta, 0)
		if nausea == 0:
			_vomitar()
	if bebiendo > 0 and nadando():
		_interrumpir_bebida()
	if bebiendo > 0:
		bebiendo = maxf(bebiendo - delta, 0)
		if bebiendo == 0:
			cervezas -= 1
			botellas = mini(botellas + 1, MAX_BOTELLAS)
			vida = mini(vida + CURA_CERVEZA, VIDA_MAX)
			borrachera += BORRACHERA_POR_CERVEZA
			_espera_sobriedad = ESPERA_SOBRIEDAD
			_partida().sumar(name.to_int(), "cervezas")
			_avisar_bebida.rpc("¡Salud! +30 de borrachera")
			if borrachera >= 100:
				_empezar_nausea()
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


# Se pasó de chelas: queda con los cachetes inflados hasta que vomita, sí o sí.
func _empezar_nausea() -> void:
	nausea = TIEMPO_NAUSEA
	arcadas = 0
	borrachera = 70.0
	_avisar_bebida.rpc("¡Te vas a vomitar! Machaca E")


## Cada E con náusea es una arcada; con suficientes, vomita antes de tiempo.
@rpc("authority", "call_local", "reliable")
func pedir_arcada() -> void:
	if not multiplayer.is_server() or nausea <= 0 or caido:
		return
	arcadas += 1
	if arcadas >= ARCADAS:
		_vomitar()


# Vomita hacia donde mira: el chorro le pega a lo que tenga enfrente (amigos
# incluidos) y deja un charco que hace daño y resbalar a quien lo pise.
func _vomitar() -> void:
	nausea = 0.0
	arcadas = 0
	vomitando = DURACION_VOMITO
	_partida().vomitar(self)
	for otro: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if otro != self and not otro.caido and _alcanza(otro.position, mirando, ALCANCE_VOMITO):
			otro.recibir_golpe(mirando, DANO_VOMITO_AMIGO, 0.8, name.to_int())
	for cosa: Node2D in get_tree().get_nodes_in_group("golpeables"):
		if _alcanza(cosa.global_position, mirando, cosa.ancho + ALCANCE_VOMITO):
			_dano_ataque = DANO_VOMITO
			cosa.golpeada(mirando, self)


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


# --- Bots de prueba (argumentos --bot, --bot-mision y --bot-torre) ---

func _bot_osa_presente() -> bool:
	var jefe: Node2D = get_tree().get_first_node_in_group("jefe")
	return jefe != null and jefe.activa and jefe.estado != "derrotada"


func _bot_acompanar_golpe() -> void:
	var anfitrion := get_node_or_null("../1")
	if anfitrion == null or _torre()._base(self) != anfitrion:
		return
	mirando = anfitrion.mirando
	if _bot_ultimo_golpe == anfitrion._numero_golpe:
		return
	_bot_ultimo_golpe = anfitrion._numero_golpe
	# Reaccionar una vez al inicio confirmado por el servidor, nunca al sostener J.
	if anfitrion._anim_golpe > 0.12 and _espera <= 0:
		_espera = ESPERA_GOLPE
		golpear.rpc_id(1, anfitrion._direccion_anim_golpe)


func _bot_torre(delta: float) -> Dictionary:
	var orden := {"dir": Vector2.ZERO, "pega": false, "agarra": false, "mantiene": false, "salta": false}
	_bot_espera = maxf(_bot_espera - delta, 0)
	var anfitrion := get_node_or_null("../1")
	if anfitrion == null or anfitrion == self:
		return orden
	_bot_ultimo_golpe = anfitrion._numero_golpe
	if _bot_estaba_montado:
		_bot_estaba_montado = false
		_bot_espera = 2.0 # E permite soltarlos y recoger una pieza antes de que vuelvan.
	# Dejar terminar un combo individual antes de intentar subir otra vez.
	if anfitrion.combo.paso > 0:
		_bot_espera = maxf(_bot_espera, 0.8)
	if not puede_actuar() or not anfitrion.puede_actuar() or anfitrion._pieza_cargada() != null \
			or anfitrion.apoyo_id != 0 or _bot_espera > 0:
		return orden
	# Con una pieza en las manos no puede montarse: la suelta primero.
	if _pieza_cargada() != null:
		orden.agarra = true
		_bot_espera = 0.5
		return orden
	var compas: Array = _torre()._cadena(anfitrion)
	if compas.size() >= _torre().MAX_COMPAS or _bot_turno > 2:
		return orden
	# El segundo espera a que el primero se siente: así no se eligen entre sí
	# como base mientras los dos siguen en el suelo.
	if _bot_turno == 2 and compas.size() == 1:
		var espera: Vector2 = anfitrion.position + Vector2(65, 35) - position
		if espera.length() > 10:
			orden.dir = _bot_rumbo(anfitrion.position + Vector2(65, 35))
		return orden
	var d: Vector2 = anfitrion.position - position
	if absf(d.x) > 9 or absf(d.y) > 6:
		orden.dir = Vector2(signf(d.x) if absf(d.x) > 9 else 0, signf(d.y) if absf(d.y) > 6 else 0)
		return orden
	if altura <= 0 and anfitrion.altura <= 0:
		orden.salta = true
	elif altura - anfitrion.altura >= 40 and altura - anfitrion.altura <= 85:
		orden.agarra = true
		_bot_espera = 0.3 # No repetir E mientras llega la confirmación de montarse.
	return orden

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


## Rumbo de un bot hacia `destino` sin meterse al lago: si el agua queda en
## medio la rodea por sus esquinas, y si ya está nadando sale a la orilla. Usa el
## contorno real del agua, así las playitas y lo que está en la orilla sí se alcanza.
func _bot_rumbo(destino: Vector2) -> Vector2:
	var bosque := get_tree().get_first_node_in_group("bosque")
	if bosque == null or bosque._radio_lago == Vector2.ZERO:
		return (destino - position).normalized()
	var c: Vector2 = bosque._centro_lago
	var r: Vector2 = bosque._radio_lago
	destino = bosque.fuera_del_lago(destino)
	if bosque.dentro_del_lago(position):
		# Sale por la orilla más cercana, un poco hacia afuera.
		var orilla: Vector2 = bosque.fuera_del_lago(position)
		return (orilla + (orilla - c).normalized() * 30.0 - position).normalized()
	if not _cruza_lago(bosque, position, destino):
		return (destino - position).normalized()
	var esquinas: Array[Vector2] = []
	for lado in [-1.0, 1.0]:
		for alto in [-1.0, 1.0]:
			esquinas.append(c + Vector2(lado * (r.x + 90.0), alto * (r.y + 45.0)))
	var mejor := Vector2.INF
	var costo := INF
	for e in esquinas:
		if _cruza_lago(bosque, position, e):
			continue
		if not _cruza_lago(bosque, e, destino):
			var total := position.distance_to(e) + e.distance_to(destino)
			if total < costo:
				costo = total
				mejor = e
			continue
		for e2 in esquinas:
			if e2 != e and not _cruza_lago(bosque, e, e2) and not _cruza_lago(bosque, e2, destino):
				var total := position.distance_to(e) + e.distance_to(e2) + e2.distance_to(destino)
				if total < costo:
					costo = total
					mejor = e
	if mejor == Vector2.INF or position.distance_to(mejor) < 12.0:
		return (destino - position).normalized()
	return (mejor - position).normalized()


## Si el camino recto de `a` a `b` pasa por el agua.
func _cruza_lago(bosque: Node, a: Vector2, b: Vector2) -> bool:
	var pasos := maxi(int(a.distance_to(b) / 20.0), 2)
	for i in range(1, pasos):
		if bosque.dentro_del_lago(a.lerp(b, float(i) / pasos)):
			return true
	return false


func _bot_mision(delta: float) -> Dictionary:
	_bot_espera -= delta
	_bot_desvio -= delta
	var orden := {"dir": Vector2.ZERO, "pega": false, "agarra": false, "mantiene": false}
	var estacion: Node2D = get_tree().get_first_node_in_group("estacion")
	if estacion == null or "--bot-flojo" in OS.get_cmdline_user_args() and estacion.terminada:
		return orden
	if not _partida().rescate.listo():
		return _bot_rescate(delta)
	if not estacion.fogata.encendida and _pieza_cargada() == null:
		return _bot_palos(estacion)
	var busqueda: Node = _partida().busqueda_olla
	if busqueda.habilitada() and not busqueda.conseguida:
		if _pieza_cargada() != null or position.distance_to(busqueda.lugar()) < 70:
			if _bot_espera <= 0:
				orden.agarra = true
				_bot_espera = 0.7 # Evitar una segunda E antes de recibir la entrada replicada.
		else:
			orden.dir = _bot_rumbo(busqueda.lugar())
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
				orden.dir = _bot_rumbo(jefe.position - Vector2(mirando * 60.0, 0.0))
		return orden

	var evento: Node = _partida().oleadas_miel
	if evento.habilitada():
		# Primero dejar la olla; después reunirse y pelear sin tocar los ingredientes.
		if _pieza_cargada() != null:
			orden.dir = _bot_rumbo(estacion.position)
			if position.distance_to(estacion.position) < 60 and _bot_espera <= 0:
				orden.agarra = true
				_bot_espera = 0.7
			return orden
		for compa in get_tree().get_nodes_in_group("jugadores"):
			if compa != self and compa.caido:
				if companero_caido() == compa:
					orden.mantiene = true
				else:
					orden.dir = _bot_rumbo(compa.position)
				return orden
		var enemigo: Node2D = null
		for e in evento.enemigos:
			if e.vivo() and (enemigo == null or position.distance_to(e.position) < position.distance_to(enemigo.position)):
				enemigo = e
		if enemigo != null:
			mirando = 1 if enemigo.position.x >= position.x else -1
			if enemigo.estado == "boxeo" and enemigo.tiempo > 0.32 and enemigo.tiempo < 0.48 and combate.espera_parada <= 0:
				if multiplayer.is_server():
					combate.pedir_parada(mirando)
				else:
					combate.pedir_parada.rpc_id(1, mirando)
			if enemigo.estado == "vuelo" and enemigo.tiempo < 2:
				orden.dir = Vector2(-1 if position.x < enemigo.destino.x else 1, 0)
			elif _alcanza(enemigo.position, mirando, enemigo.ancho):
				orden.pega = enemigo.puede_recibir_golpe()
				orden.tipo = combo.paso
				# Los bots no pegan atravesando a un compa: buscan un costado libre.
				for compa in get_tree().get_nodes_in_group("jugadores"):
					if compa != self and not compa.caido and _alcanza(compa.position, mirando) and absf(compa.altura - altura) < ALTURA_GOLPE:
						orden.pega = false
						orden.dir = _bot_rumbo(enemigo.position + Vector2(mirando * 65, 20 if _bot_turno % 2 == 0 else -20))
						break
			else:
				orden.dir = _bot_rumbo(enemigo.position - Vector2(mirando * 50, 0))
		else:
			orden.dir = _bot_rumbo(evento.CENTRO) if position.distance_to(evento.CENTRO) > 65 else Vector2.ZERO
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
				if pieza.disponible() and pieza.portador == 0 and not pieza.entregada and _mas_cerca(pieza, libre):
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
	orden.dir = _bot_lado if _bot_desvio > 0.3 else _bot_rumbo(destino)
	return orden


func _bot_rescate(delta: float) -> Dictionary:
	var r: Node = _partida().rescate
	var orden := {"dir": Vector2.ZERO, "pega": false, "agarra": false, "mantiene": false, "salta": false}
	if r.cebo:
		var humano := get_node_or_null("../1")
		if humano != null and humano.position.distance_to(r.lugar()) < r.RADIO:
			return _bot_torre(delta)
		return orden
	var miel: Node2D = null
	for pieza in get_tree().get_nodes_in_group("piezas"):
		if pieza.tipo == "miel":
			miel = pieza
	if miel == null or (miel.portador != 0 and miel.portador != name.to_int()):
		return orden
	var destino: Vector2 = r.lugar() if miel.portador == name.to_int() else miel.position
	var diferencia := destino - position
	if diferencia.length() <= 28:
		if _bot_espera <= 0:
			orden.agarra = true
			_bot_espera = 0.6
	else:
		if _bot_desvio <= 0 and get_real_velocity().length() < 20:
			_bot_desvio = 0.7
			_bot_lado = Vector2(0, -1 if _bot_turno % 2 == 0 else 1)
		orden.dir = _bot_lado if _bot_desvio > 0.3 else _bot_rumbo(destino)
	return orden


func _bot_palos(estacion: Node2D) -> Dictionary:
	var orden := {"dir": Vector2.ZERO, "pega": false, "agarra": false, "mantiene": false}
	var f: Node2D = estacion.fogata
	var destino: Vector2 = estacion.position + Vector2(-45, 15)
	var arbol: Node2D = null
	if f.cantidad(name.to_int()) < 2 and f.colocados < 2 and (not f.suelo.is_empty() or f.faltan_palos()):
		var mejor := INF
		for punto in f.suelo.values():
			var d := position.distance_to(punto)
			if d < mejor:
				mejor = d
				destino = punto
		if mejor == INF and f.faltan_palos():
			for candidato in get_tree().get_nodes_in_group("arboles_con_palos"):
				# Sin panal: las abejas no lo dejarían juntar palos.
				if str(candidato.name).contains("Panal") or candidato.name == "ArbolRescate":
					continue
				var d := position.distance_to(candidato.position)
				if d < mejor:
					mejor = d
					arbol = candidato
			if arbol != null:
				destino = arbol.position + Vector2(-48, 10)
	elif f.colocados == 2 and _bot_turno > 1:
		# Un solo bot toma un papel; el otro queda libre para que pruebe el humano.
		return orden
	var d := destino - position
	# Para golpear el árbol hay que quedar a su misma profundidad (el golpe no
	# alcanza a más de ~28 px arriba o abajo).
	var llego := absf(d.x) < 30 and absf(d.y) < 10 if arbol != null else d.length() < 35
	if llego:
		if arbol != null:
			mirando = 1
			orden.pega = true
		elif _bot_espera <= 0:
			_bot_espera = 0.5
			orden.agarra = true
	else:
		if _bot_desvio <= 0 and get_real_velocity().length() < 20:
			_bot_desvio = 0.7
			_bot_lado = Vector2(0, -1 if _bot_turno % 2 == 0 else 1)
		orden.dir = _bot_lado if _bot_desvio > 0.3 else _bot_rumbo(destino)
	return orden


func _bot_fogata(delta: float) -> void:
	_bot_espera -= delta
	if _bot_espera > 0:
		return
	_bot_espera = 0.06
	var f := get_tree().get_first_node_in_group("fogata_cooperativa")
	var rol: int = f.participantes.find(name.to_int())
	if rol < 0:
		return
	var signo := 1 if int((f.TIEMPO - f.tiempo) / f.COMPAS) % 2 == 0 else -1
	# Los dos frotan en horizontal; el segundo, en sentido contrario.
	# También acomoda los brazos sobre el palo si se le tambalean.
	var acomodo := clampf(-float(f.derivas[rol]) * 60.0, -15.0, 15.0)
	var movimiento := Vector2(signo * 30 * (1 if rol == 0 else -1), acomodo)
	if multiplayer.is_server():
		f.mover(f.encuentro, movimiento, true)
	else:
		f.mover.rpc_id(1, f.encuentro, movimiento, true)
