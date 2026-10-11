extends Node2D
## Enjambre de un panal. Ataca a quien se le acerque y no se calma hasta que
## los oseznos comen. Un golpe lo aturde un momento.
## Lo mueve el anfitrión; los demás solo reciben su posición.

const VELOCIDAD := 185.0
const ALCANCE := 26.0
const RADIO_DETECCION := 240.0
const RADIO_PERSECUCION := 480.0
const DANO := 3
const ESPERA_PIQUETE := 0.8
const ATURDIDO := 2.5

@export var miel: NodePath
## El enjambre del panal de la miel, además, persigue a quien la carga, esté
## donde esté.
@export var guarda_la_miel := false

## Están persiguiendo a alguien.
var activas := false

var _casa := Vector2.ZERO
var _espera := 0.0
var _aturdidas := 0.0
var _furiosas := false
var _presa: Node2D = null

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("golpeables")
	_casa = position
	# El panal se queda colgado en el árbol aunque el enjambre salga a perseguir.
	var panal := Node2D.new()
	panal.position = position + Vector2(0, 12)
	var caja := ColorRect.new()
	caja.color = Color(0.85, 0.6, 0.1)
	caja.position = Vector2(-10, -104)
	caja.size = Vector2(20, 26)
	panal.add_child(caja)
	get_parent().add_child.call_deferred(panal)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
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

	var objetivo: Node2D = null
	if not (estacion and estacion.alimentados):
		if _furiosas:
			objetivo = get_node_or_null("../Jugadores/%d" % pieza.portador)
		if objetivo == null:
			objetivo = _buscar_presa()
	if objetivo != null and not activas:
		print("%s ataca a %s" % [name, objetivo.name])
	activas = objetivo != null
	var destino := objetivo.position if objetivo else _casa
	position = position.move_toward(destino, VELOCIDAD * delta)
	if objetivo and position.distance_to(destino) <= ALCANCE and _espera <= 0.0:
		_espera = ESPERA_PIQUETE
		objetivo.recibir_dano.rpc(DANO)


func _process(_delta: float) -> void:
	for abeja: Control in visual.get_children():
		abeja.position = Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))


## La llama el anfitrión cuando un jugador le pega al enjambre.
func golpeada(dir: int) -> void:
	_aturdidas = ATURDIDO
	position.x += dir * 50.0


# Atacan a quien se acerque al panal y lo persiguen hasta que se aleja. El
# enjambre de la miel, una vez furioso, cuida la zona donde ande y no su panal.
func _buscar_presa() -> Node2D:
	var centro := position if _furiosas else _casa
	if is_instance_valid(_presa) and centro.distance_to(_presa.position) <= RADIO_PERSECUCION:
		return _presa
	_presa = null
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		var lejos := centro.distance_to(j.position)
		if lejos <= RADIO_DETECCION and (_presa == null or lejos < centro.distance_to(_presa.position)):
			_presa = j
	return _presa
