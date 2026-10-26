extends Node2D
## Jefe 1: Mamá Osa (GDD sección 4). Tres fases normales y una ultra final.
## Romper la olla o pegar a un osezno acelera las fases normales.
## La controla el anfitrión; los demás solo reciben su estado.

const VIDA_BASE := 300
var alto_botella := 170.0
const VIDA_POR_JUGADOR := 200
const VIDA_ULTRA := 0.5 # Fracción de la vida máxima anterior; sin ajustes en el lobby.
const VELOCIDADES := [150.0, 175.0, 200.0]
const ESPERA_ESPECIAL := [7.0, 5.0, 3.5]
const ESPECIALES := [["agarre"], ["embestida", "agarre", "rugido"], ["embestida", "piso", "agarre", "lago", "rugido"]]
# Agarre: atrapa a quien tenga enfrente, lo sostiene y lo avienta bien lejos.
const DANO_AGARRE := 20
const FUERZA_LANZAR := 2.6
const TIEMPO_SUJETANDO := 0.9
const MANO := Vector2(80, 2)
const DANO_ZARPAZO := 15
const DANO_EMBESTIDA := 20
const DANO_RUGIDO := 5
const DANO_PISO := 15
const DANO_SALIDA := 15
const DANO_OLLA := 25
const ATURDE_RUGIDO := 1.6
const VELOCIDAD_EMBESTIDA := 520.0
const PASO_EMBESTIDA := 8.0
const ANTICIPACION_ORILLA := 40.0
# Zona de la pelea: no sale de la orilla del lago.
const ZONA := Rect2(5100, 300, 1800, 390)
# Tramo de la orilla donde está el agua del lago (para aventarse y salir de él).
const LAGO_X := Vector2(5550, 6250)
const LAGO_Y := 525.0
# Cada fase tiene su propio oso: arte/mama_osa/fase<N>/<animación>/<cuadro>.png
# Los cuadros miran a la derecha y pasaron por herramientas/normalizar_osa.py,
# que los deja en un lienzo de 256x256 con las patas en la fila PIES_SPRITE.
# Se dibujan a escala 1 (como el jugador).
const CARPETA_ARTE := "res://arte/mama_osa/fase%d/%s/%d.png"
const LIENZO_SPRITE := 256.0
const PIES_SPRITE := 252.0
const DESFASE_SPRITE := Vector2(0, LIENZO_SPRITE * 0.5 - PIES_SPRITE)
# Animación -> [segundos que dura una vuelta, si se repite].
const ANIMACIONES := {
	"agarre": [1.9, false],
	"quieta": [1.8, true],
	"caminar": [0.8, true],
	"embestida": [0.45, true],
	"zarpazo": [0.65, false],
	"rugido": [1.1, false],
	"golpe_piso": [1.25, false],
	"salto": [1.2, false],
	"derrota": [1.6, false],
	"mareada": [1.2, true],
	"forcejeo": [1.1, true],
	"empujar_pie": [0.9, true],
}
# Qué animación se ve en cada estado; en los demás camina o está quieta.
const ANIMACION_POR_ESTADO := {
	"aviso_zarpazo": "zarpazo", "zarpazo": "zarpazo",
	"aviso_embestida": "rugido", "embestida": "embestida",
	"aviso_rugido": "rugido", "rugido": "rugido",
	"aviso_piso": "golpe_piso", "piso": "golpe_piso",
	"llegando": "salto", "al_lago": "salto", "salida": "salto",
	"con_crias": "quieta", "pausa": "quieta", "derrotada": "derrota",
	"cambio_fase": "rugido",
	"tambaleando": "mareada",
	"rivalidad": "zarpazo",
	"aviso_agarre": "agarre", "agarrando": "agarre", "lanzando": "agarre",
}
const DURACION_CAMBIO_FASE := 1.3
const AVISOS := {
	"cambio_fase": "¡SE ENFURECE!",
	"tambaleando": "¡TAMBALEANDO!",
	"aviso_agarre": "¡TE VA A AGARRAR, RUEDA!", "agarrando": "¡LO AGARRÓ!", "lanzando": "¡A VOLAR!",
	"aviso_zarpazo": "¡ZARPAZO!", "aviso_embestida": "¡VA A EMBESTIR!", "embestida": "¡EMBISTE!",
	"aviso_rugido": "¡VA A RUGIR!", "rugido": "¡GRRROOOAR!", "aviso_piso": "¡GOLPE AL PISO, SALTEN!",
	"al_lago": "¡SE AVIENTA AL LAGO!", "salida": "¡SPLASH!", "ir_crias": "revisa a sus crías...",
	"con_crias": "revisa a sus crías...", "derrotada": "x_x",
}

## Medio ancho extra para que los golpes de los jugadores la alcancen.
var ancho := 55.0
var activa := false
var vida := 1
var vida_max := 1
var fase := 1
var ultra: Node2D
## Veces que la hicieron enfurecer (olla rota u osezno golpeado).
var enojo := 0
var estado := "dormida"
var mirando := -1
var altura := 0.0

var _t := 0.0
var _duracion := 1.0
var _especial := 0.0
var _revisar := 0.0
var _espera_enojo := 0.0
## Tras tambalearse no puede volver a tambalearse en un rato; así no se queda trabada.
const INMUNE_TAMBALEO := 3.0
var _sin_tambaleo := 0.0
var _turno := 0
var _fase_anunciada := 1
var _agarrado: Node2D = null
var _dir := Vector2.ZERO
var _lado_desvio := 0
var _destino := Vector2.ZERO
var _golpeados: Array = []
## Quien le pega de frente mientras amaga el zarpazo lo aguanta parado (sin
## salir volando) y sigue pegando; con suficientes golpes ella se desbalancea.
var _contras := {}
const ALCANCE_CONTRA := Vector2(150, 40)
const GOLPES_DESBALANCE := 3
const DANO_CONTRA := 0.6
var _vida_vista := 1
var _estado_oido := ""
var _pisoton := 0.0
var _grunido := 0.0
var _parpadeo := 0.0
var _animacion := ""
var _posicion_vista := Vector2.ZERO
var _moviendose := 0.0
var _estrellas: Node2D
## Dónde dar vueltas las estrellitas de mareo (hacia adelante, sobre la cabeza).
const CABEZA := Vector2(30, -245)

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var aviso: Label = $Aviso
@onready var efecto: ColorRect = $Efecto


func _ready() -> void:
	add_to_group("golpeables")
	add_to_group("jefe")
	_cargar_animaciones()
	_estrellas = Estrellas.new()
	_estrellas.position = CABEZA
	_estrellas.visible = false
	visual.add_child(_estrellas)
	_crear_ultra.call_deferred()


func _crear_ultra() -> void:
	ultra = preload("res://scripts/osa_ultra.gd").new()
	ultra.name = "UltraOsa"
	get_parent().add_child(ultra)


# Arma las animaciones con los cuadros sueltos de arte/mama_osa/<nombre>/0.png, 1.png...
func _cargar_animaciones() -> void:
	var cuadros := SpriteFrames.new()
	cuadros.remove_animation("default")
	for fase_arte in [1, 2, 3]:
		for nombre: String in ANIMACIONES:
			var clave := "%d_%s" % [fase_arte, nombre]
			cuadros.add_animation(clave)
			var n := 0
			while ResourceLoader.exists(CARPETA_ARTE % [fase_arte, nombre, n]):
				cuadros.add_frame(clave, load(CARPETA_ARTE % [fase_arte, nombre, n]))
				n += 1
			cuadros.set_animation_speed(clave, maxi(n, 1) / ANIMACIONES[nombre][0])
			cuadros.set_animation_loop(clave, ANIMACIONES[nombre][1])
	sprite.sprite_frames = cuadros
	sprite.offset = DESFASE_SPRITE


func texto() -> String:
	if estado == "derrotada":
		return "¡Vencieron a Mamá Osa! Recuperaron unas chelas. Fin de la Zona 1 (por ahora)."
	if fase == 4:
		return "¡ULTRA FASE! Esquiven la garra; salten el barrido.\n¡Golpeen la mano cuando queda apoyada!"
	var olla: int = _estacion().vida_olla
	return "¡Peleen contra Mamá Osa!\nProtejan la olla y no les peguen a los oseznos, o se enfurece.\n%s" % (
		"Olla: %d" % olla if olla > 0 else "Olla rota")


func nombre_y_fase() -> String:
	if fase == 4:
		return "Mamá Osa  ·  ULTRA FASE"
	return "Mamá Osa  ·  Fase %d%s" % [fase, "  (furiosa)" if enojo > 0 else ""]


## La llama el anfitrión cuando un jugador le pega.
func golpeada(_dir_golpe: int, quien: Node2D) -> void:
	if not multiplayer.is_server() or not puede_recibir_golpe():
		return
	var dano: int = mini(vida, quien.dano_actual())
	get_tree().get_first_node_in_group("partida").sumar(quien.name.to_int(), "dano_jefe", dano)
	vida = maxi(vida - dano, 0)
	if vida == 0:
		_agotar_vida()
		return
	if estado == "aviso_zarpazo":
		var d := quien.position - position
		if absf(d.x) <= ALCANCE_CONTRA.x and absf(d.y) <= ALCANCE_CONTRA.y:
			_contras[quien] = int(_contras.get(quien, 0)) + 1
			var total := 0
			for golpes: int in _contras.values():
				total += golpes
			if total >= GOLPES_DESBALANCE:
				tambalear(0.7)


func puede_recibir_golpe() -> bool:
	if not activa or estado in ["llegando", "lago", "derrotada"]:
		return false
	return fase != 4 or (is_instance_valid(ultra) and ultra.activa and ultra.vulnerable)


func _agotar_vida() -> void:
	altura = 0.0
	if fase < 4:
		# Antes de los resultados hay una última fase, con su propio tramo de vida.
		get_tree().get_first_node_in_group("partida").abeja_musculosa.cancelar()
		if is_instance_valid(_agarrado):
			_agarrado.aturdimiento = 0
			_agarrado._aplicar_empujon.rpc(mirando, 0.25)
		_agarrado = null
		_golpeados.clear()
		for jugador in get_tree().get_nodes_in_group("jugadores"):
			jugador.combo.reiniciar()
		fase = 4
		vida_max = maxi(1, roundi(vida_max * VIDA_ULTRA))
		vida = vida_max
		ancho = 90.0
		alto_botella = 120.0
		estado = "ultra"
		ultra.iniciar()
		return
	estado = "derrotada"
	ultra.terminar.rpc()
	print("¡Mamá Osa fue derrotada!")


## La llama el anfitrión cuando rompen la olla o le pegan a un osezno.
func enfurecer(motivo: String) -> void:
	if not activa or fase == 4 or estado == "derrotada" or _espera_enojo > 0.0 or enojo >= 2:
		return
	enojo += 1
	# Sube desde la fase actual, incluso si ya avanzó por el daño recibido.
	fase = mini(maxi(fase, _fase_por_vida()) + 1, 3)
	_espera_enojo = 4.0
	print("Mamá Osa se enfurece: %s" % motivo)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or fase == 4 or estado == "derrotada" or get_tree().get_first_node_in_group("partida").finalizada:
		return
	if not activa:
		if _estacion().alimentados:
			_aparecer()
		return

	_t -= delta
	_especial -= delta
	_revisar -= delta
	_espera_enojo -= delta
	_sin_tambaleo -= delta
	fase = maxi(fase, _fase_por_vida())

	match estado:
		"llegando":
			position = position.move_toward(_destino, 200.0 * delta)
			altura = 80.0 * sin(PI * _avance())
		"perseguir":
			_perseguir(delta)
			return
		"ir_crias":
			var sitio: Vector2 = _estacion().lugar_oseznos() + Vector2(70, 0)
			_mover(sitio, delta)
			if position.distance_to(sitio) < 12.0:
				_t = 0.0
		"aviso_piso":
			altura = 90.0 * sin(PI * _avance())
		"aviso_agarre":
			# Se le echa encima al que tenga más cerca.
			var presa := _presa_cercana()
			if presa:
				var lado := signf(presa.position.x - position.x)
				if lado != 0.0:
					mirando = int(lado)
				position = _dentro(position.move_toward(presa.position - Vector2(lado * 70.0, 0.0),
					VELOCIDADES[fase - 1] * 1.5 * delta))
		"embestida":
			_avanzar_embestida(delta)
		"al_lago":
			position = position.move_toward(_destino, 420.0 * delta)
			altura = 60.0 * sin(PI * _avance())
			if position.distance_to(_destino) < 6.0:
				_t = 0.0
	if _t <= 0.0:
		_siguiente()


func _fase_por_vida() -> int:
	return clampi(3 - vida * 3 / (vida_max + 1), 1, 3)


func _process(delta: float) -> void:
	if fase == 4:
		visible = false # La presentación gigante y su mano representan ahora al jefe.
		return
	visible = activa and estado != "lago"
	if vida < _vida_vista:
		_parpadeo = 0.12
	_vida_vista = vida
	_parpadeo -= delta
	visual.position.y = -altura
	visual.scale.x = mirando
	_estrellas.visible = estado == "tambaleando"
	# Al recibir un golpe destella en claro.
	sprite.modulate = Color(4, 4, 4) if _parpadeo > 0.0 else Color.WHITE
	aviso.text = AVISOS.get(estado, "")
	if estado != _estado_oido:
		_sonar(estado)
		_estado_oido = estado
		_pisoton = 0.0
	# Durante la embestida suenan pisotones seguidos.
	if estado == "embestida":
		_pisoton -= delta
		if _pisoton <= 0.0:
			_pisoton = 0.5
			Audio.efecto_seguido("pisoton", -2.0, 0.12)
	# Mientras forcejea con la abeja, gruñe de esfuerzo una y otra vez.
	var rival: Node2D = get_tree().get_first_node_in_group("abeja_musculosa")
	if rival != null and rival.estado == "forcejeo_osa":
		_grunido -= delta
		if _grunido <= 0.0:
			_grunido = 2.2
			Audio.efecto_seguido("osa_forcejeo_grunido", 0.0, 0.05)
	else:
		_grunido = 0.0

	# Camina solo mientras de verdad se está desplazando.
	_moviendose -= delta
	if position.distance_to(_posicion_vista) > 0.2:
		_moviendose = 0.15
	_posicion_vista = position
	var animacion: String = ANIMACION_POR_ESTADO.get(estado, "caminar" if _moviendose > 0.0 else "quieta")
	sprite.position.x = 0.0
	if estado == "rivalidad":
		# Contra la abeja: zarpazos seguidos y, al forcejear, la empuja con la pata.
		var abeja: Node2D = get_tree().get_first_node_in_group("abeja_musculosa")
		if abeja != null and abeja.estado == "forcejeo_osa":
			animacion = "empujar_pie"
			# Avanza hacia la abeja cuando va ganando y retrocede cuando va perdiendo.
			sprite.position.x = (0.5 - abeja.fuerza) * 18 + sin(abeja.tiempo * 22) * 1.5
		elif not sprite.is_playing():
			# El zarpazo no se repite solo: se reinicia en cuanto termina.
			sprite.set_frame_and_progress(0, 0.0)
			sprite.play()
	# Al cambiar de fase cambia de oso, así que la animación vuelve a empezar.
	animacion = "%d_%s" % [fase, animacion]
	if animacion != _animacion:
		_animacion = animacion
		sprite.play(animacion)

	efecto.visible = estado in ["zarpazo", "rugido", "piso", "salida"]
	match estado:
		"zarpazo":
			_efecto(Rect2(45 if mirando > 0 else -135, -85, 90, 60), Color(1, 1, 1, 0.85))
		"rugido":
			_efecto(Rect2(-230, -70, 460, 110), Color(1, 0.9, 0.3, 0.3))
		"piso":
			_efecto(Rect2(-420, -10, 840, 22), Color(0.3, 0.2, 0.1, 0.6))
		"salida":
			_efecto(Rect2(-150, -50, 300, 60), Color(0.4, 0.7, 1, 0.55))


# Corre en todas las pantallas cuando cambia el estado sincronizado.
func _sonar(nuevo: String) -> void:
	match nuevo:
		"llegando":
			Audio.efecto("rugido-oso")
			Audio.musica("jefe")
		"rugido", "cambio_fase":
			Audio.efecto("rugido-oso", 0.0, 0.05)
		"zarpazo":
			Audio.efecto("zarpazo")
		"embestida":
			Audio.efecto("rugido-oso", -6.0, 0.2)
		"piso":
			Audio.efecto("caer", 2.0, 0.0)
		"lago", "salida":
			Audio.efecto("chapuzon")
		"derrotada":
			Audio.efecto("rugido-oso", -2.0, 0.0)
			Audio.musica("bosque")


# --- Lo que sigue solo corre en el anfitrión ---

func _aparecer() -> void:
	var jugadores := get_tree().get_nodes_in_group("jugadores").size()
	vida_max = VIDA_BASE + VIDA_POR_JUGADOR * maxi(jugadores - 1, 0)
	vida = vida_max
	activa = true
	# Sale del lago, a un lado de sus crías.
	_destino = _estacion().position + Vector2(280, 20)
	position = Vector2(_destino.x, 430)
	_especial = ESPERA_ESPECIAL[1]
	_revisar = 9.0
	_cambiar("llegando", 1.2)
	print("¡Llegó Mamá Osa! Vida: %d" % vida_max)


func _perseguir(delta: float) -> void:
	# Al subir de fase se detiene a rugir antes de seguir peleando.
	if fase != _fase_anunciada:
		_fase_anunciada = fase
		_cambiar("cambio_fase", DURACION_CAMBIO_FASE)
		return
	var presa := _presa_cercana()
	if presa == null:
		# Nadie cerca: se queda cuidando a sus crías.
		_mover(_estacion().lugar_oseznos() + Vector2(70, 0), delta)
		return
	var d := presa.position - position
	if d.x != 0.0:
		mirando = int(signf(d.x))
	if fase == 1 and _revisar <= 0.0:
		_revisar = 10.0
		_cambiar("ir_crias", 4.0)
	elif _especial <= 0.0:
		_especial = ESPERA_ESPECIAL[fase - 1]
		var lista: Array = ESPECIALES[fase - 1]
		_turno += 1
		match lista[_turno % lista.size()]:
			"agarre":
				_cambiar("aviso_agarre", 0.6)
			"embestida":
				_dir = d.normalized()
				_cambiar("aviso_embestida", 0.8)
			"rugido":
				_cambiar("aviso_rugido", 0.7)
			"piso":
				_cambiar("aviso_piso", 0.9)
			"lago":
				_destino = Vector2(clampf(position.x, LAGO_X.x, LAGO_X.y), LAGO_Y)
				_cambiar("al_lago", 1.0)
	elif absf(d.x) <= 85.0 and absf(d.y) <= 28.0:
		_contras.clear()
		_cambiar("aviso_zarpazo", 0.45)
	else:
		# Se acomoda a un lado del jugador para alcanzarlo con el zarpazo.
		_mover(presa.position - Vector2(signf(d.x) * 60.0, 0.0), delta)


# Qué pasa cuando se acaba el tiempo del estado actual.
func _siguiente() -> void:
	match estado:
		"aviso_zarpazo":
			_golpeados.clear()
			_pegar(position + Vector2(mirando * 60.0, 0.0), 75.0, 32.0, DANO_ZARPAZO, 1.2)
			if estado == "tambaleando":
				return
			_cambiar("zarpazo", 0.2)
		"zarpazo":
			_cambiar("pausa", 0.45)
		"aviso_embestida":
			_golpeados.clear()
			_cambiar("embestida", 1.1)
		"aviso_rugido":
			for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
				if position.distance_to(j.position) <= 230.0:
					j.recibir_dano(DANO_RUGIDO)
					j.aturdir(ATURDE_RUGIDO)
			_cambiar("rugido", 0.4)
		"aviso_piso":
			altura = 0.0
			_golpeados.clear()
			_pegar(position, 420.0, 200.0, DANO_PISO, 1.4, true)
			_cambiar("piso", 0.35)
		"al_lago":
			altura = 0.0
			_cambiar("lago", 1.6)
		"lago":
			# Sale salpicando cerca de algún jugador.
			var presa := _presa_cercana()
			var x := presa.position.x if presa else position.x
			position = _dentro(Vector2(clampf(x + [-90.0, 90.0].pick_random(), LAGO_X.x - 100.0, LAGO_X.y + 100.0), ZONA.position.y + 30.0))
			_golpeados.clear()
			_pegar(position, 150.0, 70.0, DANO_SALIDA, 1.3)
			_cambiar("salida", 0.35)
		"aviso_agarre":
			_agarrado = _atrapar()
			# Si no alcanzó a nadie se queda un momento descolocada.
			_cambiar("agarrando" if _agarrado else "pausa", TIEMPO_SUJETANDO)
		"agarrando":
			# Un golpe aceptado cancela la referencia aunque siga junto a la mano.
			var sigue_agarrado: bool = is_instance_valid(_agarrado) and not _agarrado.caido \
				and _agarrado.position.distance_to(position + MANO * Vector2(mirando, 1)) < 60.0
			if sigue_agarrado:
				_agarrado.recibir_golpe(mirando, DANO_AGARRE, FUERZA_LANZAR)
			_agarrado = null
			_cambiar("lanzando" if sigue_agarrado else "pausa", 0.4)
		"ir_crias":
			_cambiar("con_crias", 1.8)
		"embestida", "rugido", "piso", "salida", "lanzando":
			_cambiar("pausa", 0.8)
		_:
			altura = 0.0
			_cambiar("perseguir", 0.0)


## El anfitrión la llama cuando un golpe suelta al jugador, incluso si es remoto.
func liberar_jugador(jugador: Node2D) -> void:
	if multiplayer.is_server() and _agarrado == jugador:
		_agarrado = null


## La abeja musculosa la provocó: deja a los jugadores y se pelea con ella.
## La abeja dirige el pleito y la suelta con terminar_rivalidad().
func empezar_rivalidad() -> void:
	if not multiplayer.is_server() or fase == 4:
		return
	if is_instance_valid(_agarrado):
		_agarrado.aturdimiento = 0
		_agarrado._aplicar_empujon.rpc(mirando, 0.25)
		_agarrado = null
	altura = 0.0
	_golpeados.clear()
	_cambiar("rivalidad", 999.0)


func terminar_rivalidad() -> void:
	if multiplayer.is_server() and estado == "rivalidad":
		_cambiar("pausa", 0.6)


## Daño de la abeja musculosa (no cuenta en las estadísticas de los jugadores).
func danar_por_abeja(dano: int) -> void:
	if not multiplayer.is_server() or fase == 4 or not activa or estado == "derrotada":
		return
	vida = maxi(vida - dano, 0)
	if vida == 0:
		var abeja: Node2D = get_tree().get_first_node_in_group("abeja_musculosa")
		if abeja != null and abeja.estado in ["rina_osa", "forcejeo_osa"]:
			abeja._fin_rivalidad(self, "nadie")
		_agotar_vida()


func tambalear(segundos: float) -> void:
	if not multiplayer.is_server() or fase == 4 or not activa or estado in ["derrotada", "lago", "llegando"] \
			or _sin_tambaleo > 0.0:
		return
	# Cuenta desde que se recupera, no desde que empieza a tambalearse.
	_sin_tambaleo = segundos + INMUNE_TAMBALEO
	if is_instance_valid(_agarrado):
		_agarrado.aturdimiento = 0
		_agarrado._aplicar_empujon.rpc(mirando, 0.25)
		_agarrado = null
	_golpeados.clear()
	_cambiar("tambaleando", segundos)


# Atrapa al jugador que tenga enfrente y a su alcance; rodar a tiempo lo evita.
func _atrapar() -> Node2D:
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		var d := j.position - position
		if d.x * mirando > -10.0 and absf(d.x) <= 125.0 and absf(d.y) <= 36.0 and j.altura <= 40.0 \
				and j.sujetar(TIEMPO_SUJETANDO, position + MANO * Vector2(mirando, 1)):
			return j
	return null


func _cambiar(nuevo: String, duracion: float) -> void:
	# En pleito con la abeja, el ataque que lo provocó no debe pisar el estado:
	# solo salen de él al terminar el pleito, al marearse o al ser derrotada.
	if estado == "rivalidad" and nuevo not in ["pausa", "tambaleando", "derrotada", "rivalidad"]:
		return
	estado = nuevo
	if nuevo == "embestida":
		_lado_desvio = 0
	_t = duracion
	_duracion = maxf(duracion, 0.01)


# De 0 a 1: qué tanto lleva del estado actual.
func _avance() -> float:
	return clampf(1.0 - _t / _duracion, 0.0, 1.0)


func _mover(hacia: Vector2, delta: float) -> void:
	position = _dentro(position.move_toward(hacia, VELOCIDADES[fase - 1] * delta))


## Conserva la dirección anunciada; solo rodea el agua, sin perseguir al jugador.
## Pasos cortos evitan atravesar la orilla o saltarse contactos con un tick largo.
func _avanzar_embestida(delta: float) -> void:
	var bosque := get_tree().get_first_node_in_group("bosque")
	var restante := VELOCIDAD_EMBESTIDA * delta
	if _dir.is_zero_approx():
		_cambiar("pausa", 0.8)
		return
	while restante > 0.001 and estado == "embestida":
		var paso := minf(restante, PASO_EMBESTIDA)
		var rumbo := _dir.normalized()
		# Al llegar al borde de la arena termina el ataque; no gira hacia atrás.
		if not ZONA.has_point(position + rumbo * (paso + ANTICIPACION_ORILLA)):
			_cambiar("pausa", 0.8)
			return
		if not _rumbo_seco(bosque, rumbo, paso + ANTICIPACION_ORILLA):
			rumbo = Vector2.ZERO
			# Mantener el lado elegido evita alternar izquierda/derecha en la orilla.
			for giro in range(1, 13):
				for lado in ([-1, 1] if _lado_desvio == 0 else [_lado_desvio]):
					var candidato := _dir.normalized().rotated(lado * giro * PI / 12.0)
					if _rumbo_seco(bosque, candidato, paso + ANTICIPACION_ORILLA):
						rumbo = candidato
						_lado_desvio = lado
						break
				if rumbo != Vector2.ZERO:
					break
		if rumbo == Vector2.ZERO:
			_cambiar("pausa", 0.8)
			return
		position += rumbo * paso
		if absf(rumbo.x) > 0.1:
			mirando = int(signf(rumbo.x))
		_pegar(position, 60.0, 30.0, DANO_EMBESTIDA, 1.6)
		restante -= paso


func _rumbo_seco(bosque: Node, rumbo: Vector2, distancia: float) -> bool:
	var muestras := ceili(distancia / 4.0)
	for i in range(1, muestras + 1):
		var punto := position + rumbo * (distancia * i / muestras)
		if not ZONA.has_point(punto) or (bosque != null and bosque.dentro_del_lago(punto)):
			return false
		# Margen para las pequeñas curvas de la costa y la interpolación de red.
		if bosque != null:
			# Crece desde el inicio: también puede salir si arranca pegada a la orilla.
			var radio := minf(18.0, distancia * i / muestras * 0.5)
			for margen in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				if bosque.dentro_del_lago(punto + margen * radio):
					return false
	return true


func _dentro(punto: Vector2) -> Vector2:
	punto = punto.clamp(ZONA.position, ZONA.end)
	# No camina sobre el agua: si el paso cae en el lago, se queda en la orilla.
	var bosque := get_tree().get_first_node_in_group("bosque")
	return bosque.fuera_del_lago(punto) if bosque else punto


func _presa_cercana() -> Node2D:
	var mejor: Node2D = null
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if not j.caido and ZONA.grow(250.0).has_point(j.position) and (
				mejor == null or position.distance_to(j.position) < position.distance_to(mejor.position)):
			mejor = j
	return mejor


# Golpea a los jugadores dentro de un área (una sola vez por ataque) y, si la
# olla queda dentro, también la daña.
func _pegar(centro: Vector2, radio_x: float, radio_y: float, dano: int, fuerza: float, solo_en_suelo := false) -> void:
	# Si de casualidad alcanza a la abeja musculosa, se arma el pleito entre ellas.
	var abeja: Node2D = get_tree().get_first_node_in_group("abeja_musculosa")
	if abeja != null and abeja not in _golpeados and abeja.estado in ["buscando", "golpeando", "forcejeo", "paliza"]:
		var a := abeja.position - centro
		if absf(a.x) <= radio_x + abeja.ancho and absf(a.y) <= radio_y:
			_golpeados.append(abeja)
			abeja.vida = maxi(abeja.vida - dano, 0)
			if abeja.vida == 0:
				abeja._resolver("noqueada")
			else:
				abeja.provocar_osa()
			if estado == "rivalidad":
				return
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		var d := j.position - centro
		if j in _golpeados or absf(d.x) > radio_x or absf(d.y) > radio_y:
			continue
		if solo_en_suelo and j.altura > 12.0:
			continue
		if estado == "aviso_zarpazo" and _contras.has(j):
			# Le estaba pegando: aguanta el zarpazo sin salir volando.
			_golpeados.append(j)
			j.recibir_dano(ceili(dano * DANO_CONTRA))
			continue
		if estado in ["aviso_zarpazo", "embestida"] and j.combate.intentar_parada(self):
			# Aunque sea inmune al tambaleo, esta carrera ya no puede pegarle otra vez.
			_golpeados.append(j)
			tambalear(0.8)
			return
		_golpeados.append(j)
		j.recibir_golpe(int(signf(d.x)) if d.x != 0.0 else mirando, dano, fuerza)
	var estacion := _estacion()
	if estacion not in _golpeados and absf(estacion.position.x - centro.x) <= minf(radio_x, 160.0) \
			and absf(estacion.position.y - centro.y) <= radio_y:
		_golpeados.append(estacion)
		estacion.danar_olla(DANO_OLLA)


func _estacion() -> Node2D:
	return get_tree().get_first_node_in_group("estacion")


func _efecto(area: Rect2, color: Color) -> void:
	efecto.position = area.position
	efecto.size = area.size
	efecto.color = color


## Tres estrellitas amarillas dando vueltas en óvalo, como en las caricaturas.
class Estrellas extends Node2D:
	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() * 0.006
		for i in 3:
			var a := t + TAU * i / 3.0
			var punto := Vector2(cos(a) * 40.0, sin(a) * 12.0)
			# Las de atrás se ven más chicas, así parece que giran alrededor.
			var tamano := 10.0 + 3.5 * sin(a)
			var puntas := PackedVector2Array()
			for k in 10:
				var r := tamano if k % 2 == 0 else tamano * 0.45
				var ang := -PI / 2 + TAU * k / 10.0 + t * 0.5
				puntas.append(punto + Vector2(cos(ang), sin(ang)) * r)
			draw_colored_polygon(puntas, Color("ffe14d"))
			puntas.append(puntas[0])
			draw_polyline(puntas, Color("3a2410"), 2.0)
