extends Node2D
## Jefe 1: Mamá Osa (GDD sección 4). Llega cuando los oseznos comen. Tiene 3
## fases según su vida y sube de fase de golpe si rompen la olla o le pegan a
## un osezno. La controla el anfitrión; los demás solo reciben su estado.

const VIDA_BASE := 300
const VIDA_POR_JUGADOR := 200
const VELOCIDADES := [150.0, 175.0, 200.0]
const ESPERA_ESPECIAL := [0.0, 5.0, 3.5]
const ESPECIALES := [[], ["embestida", "rugido"], ["embestida", "piso", "lago", "rugido"]]
const DANO_ZARPAZO := 15
const DANO_EMBESTIDA := 20
const DANO_RUGIDO := 5
const DANO_PISO := 15
const DANO_SALIDA := 15
const DANO_OLLA := 25
const ATURDE_RUGIDO := 1.6
const VELOCIDAD_EMBESTIDA := 520.0
# Zona de la pelea: no sale de la orilla del lago.
const ZONA := Rect2(5100, 485, 1800, 205)
const COLORES_FASE := [Color(0.42, 0.26, 0.14), Color(0.62, 0.3, 0.12), Color(0.75, 0.16, 0.1)]
const AVISOS := {
	"aviso_zarpazo": "¡ZARPAZO!", "aviso_embestida": "¡VA A EMBESTIR!", "embestida": "¡EMBISTE!",
	"aviso_rugido": "¡VA A RUGIR!", "rugido": "¡GRRROOOAR!", "aviso_piso": "¡GOLPE AL PISO, SALTEN!",
	"al_lago": "¡SE AVIENTA AL LAGO!", "salida": "¡SPLASH!", "ir_crias": "revisa a sus crías...",
	"con_crias": "revisa a sus crías...", "derrotada": "x_x",
}

## Medio ancho extra para que los golpes de los jugadores la alcancen.
var ancho := 40.0
var activa := false
var vida := 1
var vida_max := 1
var fase := 1
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
var _turno := 0
var _dir := Vector2.ZERO
var _destino := Vector2.ZERO
var _golpeados: Array = []
var _vida_vista := 1
var _parpadeo := 0.0

@onready var visual: Node2D = $Visual
@onready var cuerpo: ColorRect = $Visual/Cuerpo
@onready var aviso: Label = $Aviso
@onready var efecto: ColorRect = $Efecto


func _ready() -> void:
	add_to_group("golpeables")
	add_to_group("jefe")


func texto() -> String:
	if estado == "derrotada":
		return "¡Vencieron a Mamá Osa! Recuperaron unas chelas. Fin de la Zona 1 (por ahora)."
	var olla: int = _estacion().vida_olla
	return "¡Peleen contra Mamá Osa! Protejan la olla y no les peguen a los oseznos, o se enfurece.      %s" % (
		"Olla: %d" % olla if olla > 0 else "Olla rota")


func nombre_y_fase() -> String:
	return "Mamá Osa  ·  Fase %d%s" % [fase, "  (furiosa)" if enojo > 0 else ""]


## La llama el anfitrión cuando un jugador le pega.
func golpeada(_dir_golpe: int, quien: Node2D) -> void:
	if not activa or estado in ["llegando", "lago", "derrotada"]:
		return
	var dano: int = mini(vida, quien.dano_actual())
	get_tree().get_first_node_in_group("partida").sumar(quien.name.to_int(), "dano_jefe", dano)
	vida = maxi(vida - dano, 0)
	if vida == 0:
		_cambiar("derrotada", 0.0)
		altura = 0.0
		print("¡Mamá Osa fue derrotada!")


## La llama el anfitrión cuando rompen la olla o le pegan a un osezno.
func enfurecer(motivo: String) -> void:
	if not activa or estado == "derrotada" or _espera_enojo > 0.0 or enojo >= 2:
		return
	enojo += 1
	# Sube desde la fase actual, incluso si ya avanzó por el daño recibido.
	fase = mini(maxi(fase, _fase_por_vida()) + 1, 3)
	_espera_enojo = 4.0
	print("Mamá Osa se enfurece: %s" % motivo)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or estado == "derrotada" or get_tree().get_first_node_in_group("partida").finalizada:
		return
	if not activa:
		if _estacion().alimentados:
			_aparecer()
		return

	_t -= delta
	_especial -= delta
	_revisar -= delta
	_espera_enojo -= delta
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
		"embestida":
			position = _dentro(position + _dir * VELOCIDAD_EMBESTIDA * delta)
			_pegar(position, 60.0, 30.0, DANO_EMBESTIDA, 1.6)
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
	visible = activa and estado != "lago"
	if vida < _vida_vista:
		_parpadeo = 0.12
	_vida_vista = vida
	_parpadeo -= delta
	visual.position.y = -altura
	visual.scale = Vector2(mirando, 0.4 if estado == "derrotada" else 1.0)
	cuerpo.color = Color.WHITE if _parpadeo > 0.0 else COLORES_FASE[fase - 1]
	aviso.text = AVISOS.get(estado, "")

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
	elif fase >= 2 and _especial <= 0.0:
		_especial = ESPERA_ESPECIAL[fase - 1]
		var lista: Array = ESPECIALES[fase - 1]
		_turno += 1
		match lista[_turno % lista.size()]:
			"embestida":
				_dir = d.normalized()
				_cambiar("aviso_embestida", 0.8)
			"rugido":
				_cambiar("aviso_rugido", 0.7)
			"piso":
				_cambiar("aviso_piso", 0.9)
			"lago":
				_destino = Vector2(position.x, ZONA.position.y - 40.0)
				_cambiar("al_lago", 1.0)
	elif absf(d.x) <= 85.0 and absf(d.y) <= 28.0:
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
			position = _dentro(Vector2(x + [-90.0, 90.0].pick_random(), ZONA.position.y + 30.0))
			_golpeados.clear()
			_pegar(position, 150.0, 70.0, DANO_SALIDA, 1.3)
			_cambiar("salida", 0.35)
		"ir_crias":
			_cambiar("con_crias", 1.8)
		"embestida", "rugido", "piso", "salida":
			_cambiar("pausa", 0.8)
		_:
			altura = 0.0
			_cambiar("perseguir", 0.0)


func _cambiar(nuevo: String, duracion: float) -> void:
	estado = nuevo
	_t = duracion
	_duracion = maxf(duracion, 0.01)


# De 0 a 1: qué tanto lleva del estado actual.
func _avance() -> float:
	return clampf(1.0 - _t / _duracion, 0.0, 1.0)


func _mover(hacia: Vector2, delta: float) -> void:
	position = _dentro(position.move_toward(hacia, VELOCIDADES[fase - 1] * delta))


func _dentro(punto: Vector2) -> Vector2:
	return punto.clamp(ZONA.position, ZONA.end)


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
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		var d := j.position - centro
		if j in _golpeados or absf(d.x) > radio_x or absf(d.y) > radio_y:
			continue
		if solo_en_suelo and j.altura > 12.0:
			continue
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
