extends Node
## Estado de la ronda y estadísticas. Solo el anfitrión registra los sucesos.

signal finalizo(victoria: bool, filas: Array)

const CERVEZA := preload("res://scripts/cerveza.gd")
const CHARCO := preload("res://scripts/charco.gd")
const BOTELLA := preload("res://scripts/botella.gd")
const TORRE := preload("res://scripts/torre.gd")
const SUMINISTROS := [Vector2(440, 550), Vector2(475, 555), Vector2(510, 550),
	Vector2(440, 605), Vector2(475, 610), Vector2(510, 605),
	Vector2(900, 530), Vector2(1850, 520),
	Vector2(3400, 550), Vector2(3900, 580), Vector2(4750, 570), Vector2(5250, 650),
	Vector2(5380, 650), Vector2(5720, 690), Vector2(6450, 660), Vector2(6650, 665), Vector2(7000, 520)]

var finalizada := false
var victoria := false
var resultados: Array = []
var estadisticas: Dictionary = {}
var _todos_caidos := 0.0
var _numero_charco := 0
var _numero_botella := 0
var torre: Node


func _ready() -> void:
	add_to_group("partida")
	torre = TORRE.new()
	torre.name = "Torre"
	add_child(torre)
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
	var sitio := jugador.position + Vector2(jugador.mirando * 60, 4)
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


## La llama el anfitrión cuando un jugador avienta una botella vacía.
func lanzar_botella(jugador: Node2D, direccion: Vector2) -> void:
	if not multiplayer.is_server() or finalizada:
		return
	_numero_botella += 1
	_crear_botella.rpc(_numero_botella, jugador.position, direccion, jugador.name.to_int(), jugador.altura)


@rpc("authority", "call_local", "reliable")
func _crear_botella(numero: int, origen: Vector2, direccion: Vector2, lanzador: int, altura_origen: float = 0.0) -> void:
	var botella := BOTELLA.new()
	botella.name = "Botella%d" % numero
	botella.position = origen
	botella.direccion = direccion
	botella.lanzador = lanzador
	botella.altura += altura_origen
	get_parent().get_node("Mundo").add_child(botella)


@rpc("authority", "call_local", "reliable")
func quitar_botella(nombre_botella: String) -> void:
	var botella := get_parent().get_node("Mundo").get_node_or_null(nombre_botella)
	if botella:
		botella.estallar()
		botella.queue_free()


@rpc("authority", "call_local", "reliable")
func quitar_charco(nombre_charco: String) -> void:
	var charco := get_parent().get_node("Mundo").get_node_or_null(nombre_charco)
	if charco:
		charco.queue_free()
