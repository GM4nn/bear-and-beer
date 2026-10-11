extends Node2D
## Estación de construcción de la Zona 1: la fogata del lago. Se le entregan
## las piezas, se cocina la papilla manteniendo el botón de agarrar y luego hay
## que dársela a los oseznos antes de que llegue Mamá Osa (GDD sección 5).
## Entre más jugadores ayuden, más rápido se llenan las barras.

const RADIO := 80.0
const RADIO_OSEZNOS := 60.0
const LUGAR_OSEZNOS := Vector2(123, 0)
const TIEMPO := 8.0
const TIEMPO_VACIAR := 6.0
const TIEMPO_ALIMENTAR := 10.0
const TIEMPO_LIMITE := 30.0
const NECESARIAS := {"miel": "Miel", "olla": "Olla", "lena": "Leña"}

## Avance de cocinar la papilla (0 a 1).
var progreso := 0.0
## La papilla ya está lista y corre el tiempo para dársela a los oseznos.
var terminada := false
## Avance de alimentar a los oseznos (0 a 1).
var alimento := 0.0
## Segundos que faltan para que llegue Mamá Osa.
var tiempo := TIEMPO_LIMITE
## Los oseznos ya comieron: misión cumplida.
var alimentados := false
## Vida de la olla durante la pelea; si se rompe, Mamá Osa se enfurece.
var vida_olla := 100

var _susto := 0.0

@onready var barra_fondo: ColorRect = $BarraFondo
@onready var barra: ColorRect = $Barra
@onready var barra_oseznos_fondo: ColorRect = $BarraOseznosFondo
@onready var barra_oseznos: ColorRect = $BarraOseznos
@onready var papilla: ColorRect = $Papilla
@onready var llanto: Label = $Llanto
@onready var mama_osa: Node2D = $MamaOsa


func _ready() -> void:
	add_to_group("estacion")
	$GolpeOlla.golpeado.connect(danar_olla.bind(10))
	$GolpeOseznos.golpeado.connect(_pegaron_a_osezno)


## La llama el anfitrión: daño a la olla por golpes de jugadores o del jefe.
func danar_olla(dano: int) -> void:
	if not alimentados or vida_olla <= 0:
		return
	vida_olla = maxi(vida_olla - dano, 0)
	if vida_olla == 0:
		_jefe().enfurecer("rompieron la olla")


func _pegaron_a_osezno() -> void:
	if alimentados:
		_jefe().enfurecer("le pegaron a un osezno")


func _jefe() -> Node2D:
	return get_tree().get_first_node_in_group("jefe")


func entregadas() -> Array:
	var tipos := []
	for pieza in get_tree().get_nodes_in_group("piezas"):
		if pieza.entregada:
			tipos.append(pieza.tipo)
	return tipos


func completa() -> bool:
	return entregadas().size() >= NECESARIAS.size()


func lugar_oseznos() -> Vector2:
	return position + LUGAR_OSEZNOS


## Solo la llama el anfitrión, cuando alguien suelta una pieza.
func intentar_entregar(pieza: Node2D, desde: Vector2) -> bool:
	if desde.distance_to(position) > RADIO or not NECESARIAS.has(pieza.tipo):
		return false
	pieza.entregar(position + Vector2(-56 + 56 * entregadas().size(), 22))
	print("Entregaron: %s" % pieza.tipo)
	return true


func texto_mision() -> String:
	if alimentados:
		return "¡Los oseznos comieron y ya lloran por su mamá! Mamá Osa viene en camino."
	if _susto > 0.0:
		return "¡Mamá Osa llegó y sus oseznos seguían con hambre! El equipo cayó."
	if terminada:
		return "¡Denles la papilla a los oseznos! Mantengan E junto a ellos: %d%%      Mamá Osa llega en %d s" % [alimento * 100.0, ceili(tiempo)]
	if completa():
		return "Mantengan E junto a la fogata para cocinar la papilla; si la sueltan, se baja: %d%%" % (progreso * 100.0)
	var ya := entregadas()
	var partes := []
	for tipo in NECESARIAS:
		partes.append(("[x] " if tipo in ya else "[  ] ") + NECESARIAS[tipo])
	return "Misión: lleven las piezas a la fogata del lago      " + "      ".join(partes)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or alimentados or not completa() or get_tree().get_first_node_in_group("partida").finalizada:
		return
	if not terminada:
		progreso = _llenar(progreso, _ayudando(position, RADIO), TIEMPO, delta)
		if progreso >= 1.0:
			terminada = true
			print("¡Papilla lista!")
		return

	alimento = _llenar(alimento, _ayudando(lugar_oseznos(), RADIO_OSEZNOS), TIEMPO_ALIMENTAR, delta)
	tiempo -= delta
	if alimento >= 1.0:
		alimentados = true
		print("¡Los oseznos comieron!")
	elif tiempo <= 0.0:
		print("No alimentaron a los oseznos a tiempo: Mamá Osa acaba con todos")
		for j in get_tree().get_nodes_in_group("jugadores"):
			j._perder_vida(9999)
		# Se echa a perder la papilla: hay que volver a cocinarla.
		progreso = 0.0
		terminada = false
		alimento = 0.0
		tiempo = TIEMPO_LIMITE
		_llego_furiosa.rpc()


func _process(delta: float) -> void:
	_susto -= delta
	barra_fondo.visible = completa() and not terminada
	barra.visible = barra_fondo.visible
	barra.size.x = barra_fondo.size.x * progreso
	barra_oseznos_fondo.visible = terminada and not alimentados
	barra_oseznos.visible = barra_oseznos_fondo.visible
	barra_oseznos.size.x = barra_oseznos_fondo.size.x * alimento
	papilla.visible = terminada and vida_olla > 0
	llanto.visible = terminada
	llanto.text = "¡BUAAAA! ¡MAMÁ!" if alimentados else "¡HAMBRE!"
	mama_osa.visible = _susto > 0.0


# Cuántos jugadores mantienen el botón de agarrar cerca de un punto.
func _ayudando(donde: Vector2, radio: float) -> int:
	var cuantos := 0
	for j: Node2D in get_tree().get_nodes_in_group("jugadores"):
		if j.manteniendo and j.puede_ayudar() and j.companero_caido() == null and j.position.distance_to(donde) <= radio:
			cuantos += 1
	return cuantos


# Sube una barra según cuántos ayudan; si nadie ayuda, se baja poco a poco.
func _llenar(valor: float, ayudando: int, segundos: float, delta: float) -> float:
	if ayudando == 0:
		return maxf(valor - delta / TIEMPO_VACIAR, 0.0)
	return minf(valor + ayudando * delta / segundos, 1.0)


@rpc("authority", "call_local", "reliable")
func _llego_furiosa() -> void:
	_susto = 5.0
