extends Node2D
## Pieza de un artilugio. Se carga con las manos; el anfitrión decide quién la
## trae y les avisa a todos cada vez que cambia.

@export var tipo := "miel"
@export var texto := "MIEL"
@export var color := Color(0.95, 0.75, 0.15)
const ARTE := preload("res://scripts/arte_objetos.gd")
var _sprite: Sprite2D
var _tiempo_visual := 0.0

## Id del jugador que la carga (0 = está en el suelo).
var portador := 0
## Ya está puesta en la estación y no se puede volver a agarrar.
var entregada := false

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("piezas")
	$Visual/Color.hide()
	_sprite = ARTE.estatico(tipo, 1.5)
	visual.add_child(_sprite)
	$Visual/Texto.text = texto


func _process(delta: float) -> void:
	_tiempo_visual += delta
	var estacion := get_tree().get_first_node_in_group("estacion")
	visible = not (entregada and estacion != null and estacion.completa())
	var quien: Node2D = get_node_or_null("../Jugadores/%d" % portador) if portador else null
	if quien:
		# La lleva en las manos, por delante del cuerpo.
		position = quien.position + Vector2(0, 1)
		visual.position = Vector2(quien.mirando * 34.0, -46.0 - quien.altura)
	else:
		visual.position = Vector2.ZERO
	_sprite.position.y = 0 if quien or entregada else sin(_tiempo_visual * 2.5) * 1.5
	$Visual/Texto.visible = quien == null


# Las tres siguientes solo las llama el anfitrión.

func agarrar(id: int) -> void:
	_estado.rpc(id, position, false)


func soltar(donde: Vector2) -> void:
	_estado.rpc(0, donde, false)


func entregar(donde: Vector2) -> void:
	_estado.rpc(0, donde, true)


@rpc("authority", "call_local", "reliable")
func _estado(nuevo_portador: int, donde: Vector2, ya_entregada: bool) -> void:
	portador = nuevo_portador
	entregada = ya_entregada
	if portador == 0:
		position = donde
