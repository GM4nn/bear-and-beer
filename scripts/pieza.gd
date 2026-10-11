extends Node2D
## Pieza de un artilugio. Se carga con las manos; el anfitrión decide quién la
## trae y les avisa a todos cada vez que cambia.

@export var tipo := "miel"
@export var texto := "MIEL"
@export var color := Color(0.95, 0.75, 0.15)

## Id del jugador que la carga (0 = está en el suelo).
var portador := 0
## Ya está puesta en la estación y no se puede volver a agarrar.
var entregada := false

@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group("piezas")
	$Visual/Color.color = color
	$Visual/Texto.text = texto


func _process(_delta: float) -> void:
	var quien: Node2D = get_node_or_null("../Jugadores/%d" % portador) if portador else null
	if quien:
		# La lleva en las manos, por delante del cuerpo.
		position = quien.position + Vector2(0, 1)
		visual.position = Vector2(quien.mirando * 14.0, -4.0 - quien.altura)
	else:
		visual.position = Vector2.ZERO
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
