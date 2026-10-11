extends Node
## Escena principal: cambia entre menú, sala de espera y el bosque.

const JUGADOR := preload("res://escenas/jugador.tscn")
const BOSQUE := preload("res://escenas/bosque.tscn")

var juego: Node2D
var jugadores: Node2D
var inicio: Marker2D
var aparecedor: MultiplayerSpawner
var estacion: Node2D
var _auto := false

@onready var ayuda: Label = $UI/Ayuda
@onready var mision: Label = $UI/Mision
@onready var aviso: Label = $UI/Aviso
@onready var campo_nombre: LineEdit = $UI/Menu/Nombre
@onready var campo_ip: LineEdit = $UI/Unirse/IP
@onready var pantallas := {
	"menu": $UI/Menu, "unirse": $UI/Unirse, "opciones": $UI/Opciones, "sala": $UI/Sala,
}


func _ready() -> void:
	_usar_bosque($Juego)

	$UI/Menu/Crear.pressed.connect(_crear_partida)
	$UI/Menu/Unirse.pressed.connect(_mostrar.bind("unirse"))
	$UI/Menu/Opciones.pressed.connect(_mostrar.bind("opciones"))
	$UI/Menu/Salir.pressed.connect(get_tree().quit)
	$UI/Unirse/Conectar.pressed.connect(_unirse)
	$UI/Unirse/Volver.pressed.connect(_volver_al_menu.bind(""))
	$UI/Opciones/PantallaCompleta.toggled.connect(_pantalla_completa)
	$UI/Opciones/Volumen.value_changed.connect(_volumen)
	$UI/Opciones/Volver.pressed.connect(_mostrar.bind("menu"))
	$UI/Sala/Salir.pressed.connect(_volver_al_menu.bind(""))

	multiplayer.connected_to_server.connect(_mostrar.bind("sala"))
	multiplayer.connection_failed.connect(_volver_al_menu.bind("No se pudo conectar."))
	multiplayer.server_disconnected.connect(_volver_al_menu.bind("El anfitrión cerró la partida."))
	multiplayer.peer_disconnected.connect(_salio_jugador)
	Red.partida_iniciada.connect(_empezar_juego)
	Red.jugadores_cambiaron.connect(_auto_listo)

	_mostrar("menu")

	# Atajos para probar: -- --host  /  -- --join=127.0.0.1
	# --auto marca "listo" solo (y el anfitrión empieza al haber 2); --bot juega solo.
	var args := OS.get_cmdline_user_args()
	_auto = "--auto" in args
	for arg in args:
		if arg == "--host":
			_crear_partida()
		elif arg.begins_with("--join"):
			if "=" in arg:
				campo_ip.text = arg.get_slice("=", 1)
			_unirse()


func _unhandled_input(event: InputEvent) -> void:
	if juego.visible and event.is_action_pressed("ui_cancel"):
		_volver_al_menu("")


func _process(_delta: float) -> void:
	if juego.visible:
		mision.text = estacion.texto_mision()


func _mostrar(pantalla: String) -> void:
	for nombre in pantallas:
		pantallas[nombre].visible = nombre == pantalla
	juego.visible = pantalla == "juego"
	ayuda.visible = pantalla == "juego"
	mision.visible = pantalla == "juego"
	aviso.text = ""


func _usar_bosque(bosque: Node2D) -> void:
	juego = bosque
	jugadores = bosque.get_node("Mundo/Jugadores")
	inicio = bosque.get_node("Inicio")
	aparecedor = bosque.get_node("Aparecedor")
	estacion = bosque.get_node("Mundo/Estacion")
	aparecedor.spawn_function = _crear_jugador


# Deja el bosque como nuevo (piezas, fogata, abejas) para la siguiente partida.
func _reiniciar_bosque() -> void:
	remove_child(juego)
	juego.queue_free()
	var nuevo := BOSQUE.instantiate()
	nuevo.name = "Juego"
	add_child(nuevo)
	move_child(nuevo, 0)
	_usar_bosque(nuevo)


func _crear_partida() -> void:
	Red.mi_nombre = campo_nombre.text
	if Red.crear_partida() != OK:
		aviso.text = "No se pudo crear la partida (¿puerto %d ocupado?)." % Red.puerto
		return
	print("Partida creada en el puerto %d" % Red.puerto)
	_mostrar("sala")


func _unirse() -> void:
	Red.mi_nombre = campo_nombre.text
	var ip := campo_ip.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	if Red.unirse(ip) != OK:
		aviso.text = "Dirección inválida."
		return
	aviso.text = "Conectando a %s..." % ip


func _volver_al_menu(mensaje: String) -> void:
	Red.salir()
	_reiniciar_bosque()
	_mostrar("menu")
	aviso.text = mensaje
	if mensaje:
		print(mensaje)


func _empezar_juego() -> void:
	_mostrar("juego")
	print("Empieza la partida: %s" % [Red.jugadores])
	if multiplayer.is_server():
		for id in Red.jugadores:
			aparecedor.spawn([id, Red.jugadores[id].color, Red.jugadores[id].nombre])


func _salio_jugador(id: int) -> void:
	if multiplayer.is_server() and jugadores.has_node(str(id)):
		for pieza in get_tree().get_nodes_in_group("piezas"):
			if pieza.portador == id:
				pieza.soltar(pieza.position)
		jugadores.get_node(str(id)).queue_free()


# Corre en todas las pantallas cada vez que el anfitrión aparece un jugador.
func _crear_jugador(datos: Array) -> Node:
	var j := JUGADOR.instantiate()
	j.name = str(datos[0])
	j.color_indice = datos[1]
	j.nombre = datos[2]
	# Cada color tiene su lugar junto a la fogata para que no aparezcan encimados.
	j.position = inicio.position + Vector2(datos[1] % 3 * 60, datos[1] / 3 * 50)
	return j


func _auto_listo() -> void:
	if not _auto or juego.visible:
		return
	var yo: Dictionary = Red.jugadores.get(multiplayer.get_unique_id(), {})
	if not yo.is_empty() and not yo.listo:
		Red.pedir_listo(true)
	elif multiplayer.is_server() and Red.jugadores.size() >= 2:
		Red.iniciar_partida()


func _pantalla_completa(activa: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if activa else DisplayServer.WINDOW_MODE_WINDOWED)


func _volumen(valor: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(valor))
