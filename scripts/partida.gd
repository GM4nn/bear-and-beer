extends Node
## Estado de la ronda y estadísticas. Solo el anfitrión registra los sucesos.

signal finalizo(victoria: bool, filas: Array)

const CERVEZA := preload("res://scripts/cerveza.gd")
const CHARCO := preload("res://scripts/charco.gd")
const SUMINISTROS := [Vector2(440, 550), Vector2(475, 555), Vector2(510, 550),
	Vector2(440, 605), Vector2(475, 610), Vector2(510, 605),
	Vector2(900, 530), Vector2(1850, 520),
	Vector2(3400, 550), Vector2(3900, 580), Vector2(4750, 570), Vector2(5250, 650),
	Vector2(5550, 505), Vector2(5900, 675), Vector2(6250, 500), Vector2(6650, 665), Vector2(7000, 520)]

var finalizada := false
var victoria := false
var resultados: Array = []
var estadisticas: Dictionary = {}
var _todos_caidos := 0.0
var _numero_charco := 0


func _ready() -> void:
	add_to_group("partida")
	for i in SUMINISTROS.size():
		var cerveza := CERVEZA.new()
		cerveza.name = "Cerveza%d" % i
		cerveza.position = SUMINISTROS[i]
		get_parent().get_node("Mundo").add_child(cerveza)


func registrar(jugador: Node) -> void:
	if not multiplayer.is_server():
		return
	var id := jugador.name.to_int()
	estadisticas[id] = {"nombre": jugador.nombre, "color": jugador.color_indice,
		"fuego_amigo": 0, "vuelo": 0.0, "cervezas": 0, "vomitos": 0,
		"dormidas": 0, "dano_jefe": 0, "rescates": 0}


func sumar(id: int, clave: String, cantidad: float = 1.0) -> void:
	if multiplayer.is_server() and not finalizada and estadisticas.has(id):
		estadisticas[id][clave] += cantidad


func registrar_vuelo(id: int, distancia: float) -> void:
	if multiplayer.is_server() and not finalizada and estadisticas.has(id):
		estadisticas[id].vuelo = maxf(estadisticas[id].vuelo, distancia)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or finalizada:
		return
	var jugadores := get_tree().get_nodes_in_group("jugadores")
	if jugadores.is_empty():
		return
	var jefe := get_tree().get_first_node_in_group("jefe")
	if jefe and jefe.estado == "derrotada":
		terminar(true)
		return
	var todos: bool = jugadores.all(func(j): return j.caido)
	_todos_caidos = _todos_caidos + delta if todos else 0.0
	if _todos_caidos >= 2.0:
		terminar(false)


func terminar(gano: bool) -> void:
	if multiplayer.is_server() and not finalizada:
		_cerrar.rpc(gano, estadisticas.values())


@rpc("authority", "call_local", "reliable")
func _cerrar(gano: bool, filas: Array) -> void:
	finalizada = true
	victoria = gano
	resultados = filas.duplicate(true)
	finalizo.emit(gano, resultados)


func vomitar(jugador: Node2D) -> void:
	if not multiplayer.is_server() or finalizada:
		return
	var sitio := jugador.position + Vector2(jugador.mirando * 35, 0)
	for otro in get_tree().get_nodes_in_group("jugadores"):
		if otro != jugador and not otro.caido and otro.position.distance_to(sitio) < 45:
			sumar(jugador.name.to_int(), "vomitos")
	_numero_charco += 1
	_crear_charco.rpc(_numero_charco, sitio)


@rpc("authority", "call_local", "reliable")
func _crear_charco(numero: int, sitio: Vector2) -> void:
	var charco := CHARCO.new()
	charco.name = "Charco%d" % numero
	charco.position = sitio
	get_parent().get_node("Mundo").add_child(charco)


@rpc("authority", "call_local", "reliable")
func quitar_charco(nombre_charco: String) -> void:
	var charco := get_parent().get_node("Mundo").get_node_or_null(nombre_charco)
	if charco:
		charco.queue_free()
