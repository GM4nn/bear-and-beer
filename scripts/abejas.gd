extends Node2D
## Enjambre de un panal. Ataca a quien se le acerque; durante la pelea contra
## el jefe sigue atacando con menos fuerza y solo se calma cuando el jefe cae.
## Un golpe lo aturde un momento.
## Lo mueve el anfitrión; los demás solo reciben su posición.

const VELOCIDAD := 185.0
const ALCANCE := 26.0
const RADIO_DETECCION := 240.0
const RADIO_PERSECUCION := 480.0
const DANO := 3
const ESPERA_PIQUETE := 0.8
const ATURDIDO := 2.5
# Durante la pelea contra el jefe: más lentas, pican menos seguido y más suave.
const FRENO_EN_PELEA := 0.75
const DANO_EN_PELEA := 2
const ESPERA_PIQUETE_EN_PELEA := 1.6
const CUADROS_ABEJA := "res://arte/zona1/abeja/%d.png"
const CANTIDAD_ABEJAS := 5

@export var miel: NodePath
## El enjambre del panal de la miel, además, persigue a quien la carga, esté
## donde esté.
@export var guarda_la_miel := false

## Están persiguiendo a alguien.
var activas := false
## Medio ancho extra para que los golpes las alcancen.
var ancho := 0.0

var _casa := Vector2.ZERO
var _espera := 0.0
var _aturdidas := 0.0
var _furiosas := false
var _presa: Node2D = null
var _abejas: Array[Sprite2D] = []
var _fases: Array[float] = []
var _cuadros_abeja: Array[Texture2D] = []
var _posicion_vista := Vector2.ZERO
var _hacia := 1.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("golpeables")
	_casa = position
	_posicion_vista = position
	# El panal se queda colgado en el árbol aunque el enjambre salga a perseguir.
	var panal := Sprite2D.new()
	panal.texture = load("res://arte/zona1/panal.png")
	panal.scale = Vector2(2, 2)
	panal.position = position + Vector2(0, 12)
	panal.offset = Vector2(9, -44)
	get_parent().add_child.call_deferred(panal)
	# Abejitas animadas en lugar de los cuadritos de prototipo.
	for cuadrito in visual.get_children():
		cuadrito.hide()
	var n := 0
	while ResourceLoader.exists(CUADROS_ABEJA % n):
		_cuadros_abeja.append(load(CUADROS_ABEJA % n))
		n += 1
	for i in CANTIDAD_ABEJAS:
		var abeja := Sprite2D.new()
		abeja.texture = _cuadros_abeja[0] if not _cuadros_abeja.is_empty() else null
		visual.add_child(abeja)
		_abejas.append(abeja)
		_fases.append(randf() * TAU)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or get_tree().get_first_node_in_group("partida").finalizada:
		return
	var pieza: Node2D = get_node(miel)
	var estacion := get_tree().get_first_node_in_group("estacion")
	if guarda_la_miel and not _furiosas and pieza.portador != 0:
		_furiosas = true
		print("¡Las abejas de la miel se enfurecieron!")

	_espera -= delta
	_aturdidas -= delta
	if _aturdidas > 0.0:
		return

	# Durante la pelea contra el jefe siguen molestando, pero con menos ganas;
	# se calman del todo cuando el jefe cae.
	var jefe := get_tree().get_first_node_in_group("jefe")
	var en_pelea: bool = estacion != null and estacion.alimentados
	var calmadas: bool = en_pelea and (jefe == null or jefe.estado == "derrotada")

	var objetivo: Node2D = null
	if not calmadas:
		if _furiosas and not en_pelea:
			objetivo = get_node_or_null("../Jugadores/%d" % pieza.portador)
		if objetivo == null:
			objetivo = _buscar_presa()
	if objetivo != null and objetivo.caido:
		objetivo = null
	if objetivo != null and not activas:
		print("%s ataca a %s" % [name, objetivo.name])
	activas = objetivo != null
	var destino := objetivo.position if objetivo else _casa
	position = position.move_toward(destino, VELOCIDAD * (FRENO_EN_PELEA if en_pelea else 1.0) * delta)
	if objetivo and position.distance_to(destino) <= ALCANCE and _espera <= 0.0:
		_espera = ESPERA_PIQUETE_EN_PELEA if en_pelea else ESPERA_PIQUETE
		objetivo.recibir_dano(DANO_EN_PELEA if en_pelea else DANO)


func _process(_delta: float) -> void:
	# Miran hacia donde se mueve el enjambre (las abejas están dibujadas mirando a la derecha).
	var avance := position.x - _posicion_vista.x
	if absf(avance) > 0.5:
		_hacia = signf(avance)
	_posicion_vista = position
	var t := Time.get_ticks_msec() / 1000.0
	for i in _abejas.size():
		var fase := _fases[i]
		# Cada una revolotea en su propio ocho alrededor del centro del enjambre.
		_abejas[i].position = Vector2(sin(t * 2.3 + fase) * 30.0, sin(t * 4.6 + fase * 1.7) * 18.0 - 6.0)
		_abejas[i].flip_h = _hacia < 0.0
		if not _cuadros_abeja.is_empty():
			_abejas[i].texture = _cuadros_abeja[int(t * 24.0 + i) % _cuadros_abeja.size()]


## La llama el anfitrión cuando un jugador le pega al enjambre.
func golpeada(dir: int, _quien: Node2D) -> void:
	_aturdidas = ATURDIDO
	position.x += dir * 50.0


# Atacan a quien se acerque al panal y lo persiguen hasta que se aleja. El
# enjambre de la miel, una vez furioso, cuida la zona donde ande y no su panal.
func _buscar_presa() -> Node2D:
	var centro := position if _furiosas else _casa
	if is_instance_valid(_presa) and not _presa.caido and centro.distance_to(_presa.position) <= RADIO_PERSECUCION:
		return _presa
	_presa = null
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if j.caido:
			continue
		var lejos := centro.distance_to(j.position)
		if lejos <= RADIO_DETECCION and (_presa == null or lejos < centro.distance_to(_presa.position)):
			_presa = j
	return _presa
