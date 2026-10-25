extends Node
## Conexión en línea y sala de espera. Por ahora usa ENet (IP directa); al
## integrar GodotSteam solo cambia el peer que se crea aquí.
## El anfitrión es quien decide la lista de jugadores y se la manda a todos.

const PUERTO := 7777
const MAX_JUGADORES := 6

signal jugadores_cambiaron
signal partida_iniciada

## Se puede cambiar con el argumento --puerto=7778 para probar sin estorbar a otra partida.
var puerto := PUERTO
var mi_nombre := "Jugador"
## id -> { "nombre": String, "color": int, "listo": bool }
var jugadores: Dictionary = {}
var latencias := {}
var _sondeos := {}
var _siguiente_sondeo := 0.0
signal conexion_cambio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--puerto="):
			puerto = arg.get_slice("=", 1).to_int()
	multiplayer.connected_to_server.connect(func(): _registrar.rpc_id(1, mi_nombre))
	multiplayer.peer_disconnected.connect(_salio_jugador)


func crear_partida() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_JUGADORES - 1)
	if err == OK:
		multiplayer.multiplayer_peer = peer
		jugadores.clear()
		_agregar(1, mi_nombre)
	return err


func unirse(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, puerto)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err


func salir() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	jugadores.clear()
	latencias.clear()
	_sondeos.clear()
	jugadores_cambiaron.emit()


func pedir_color(color: int) -> void:
	if multiplayer.is_server():
		_pedir_color(color)
	else:
		_pedir_color.rpc_id(1, color)


func pedir_listo(listo: bool) -> void:
	if multiplayer.is_server():
		_pedir_listo(listo)
	else:
		_pedir_listo.rpc_id(1, listo)


func todos_listos() -> bool:
	return not jugadores.is_empty() and jugadores.values().all(func(j): return j.listo)


func iniciar_partida() -> void:
	if multiplayer.is_server() and todos_listos():
		# Por ahora no se puede entrar a una partida ya empezada.
		multiplayer.multiplayer_peer.refuse_new_connections = true
		_iniciar.rpc()


func ip_local() -> String:
	var ips := IP.get_local_addresses()
	# Con una red virtual los amigos se conectan a esa IP, así que va primero:
	# Radmin VPN (26.x.x.x) y Hamachi (25.x.x.x).
	for prefijo in ["26.", "25."]:
		for ip in ips:
			if ip.begins_with(prefijo):
				return ip
	# Luego la red de casa, sin los adaptadores de máquinas virtuales
	# (VirtualBox usa 192.168.56.x).
	for ip in ips:
		if ip.begins_with("192.168.56."):
			continue
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"


func _agregar(id: int, nombre: String) -> void:
	nombre = nombre.strip_edges().left(12)
	var usados := jugadores.values().map(func(j): return j.color)
	var color := 0
	while color in usados:
		color += 1
	jugadores[id] = {"nombre": nombre if nombre else "Jugador", "color": color, "listo": false}
	_sincronizar.rpc(jugadores)


func _salio_jugador(id: int) -> void:
	if multiplayer.is_server() and jugadores.erase(id):
		_sincronizar.rpc(jugadores)


# Quién mandó la petición (0 significa que la llamó el propio anfitrión).
func _quien() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else 1


@rpc("any_peer", "reliable")
func _registrar(nombre: String) -> void:
	if multiplayer.is_server() and jugadores.size() < MAX_JUGADORES:
		_agregar(multiplayer.get_remote_sender_id(), nombre)


@rpc("any_peer", "reliable")
func _pedir_color(color: int) -> void:
	var id := _quien()
	if not multiplayer.is_server() or not jugadores.has(id) or color < 0 or color >= MAX_JUGADORES:
		return
	for otro in jugadores:
		if otro != id and jugadores[otro].color == color:
			return
	jugadores[id].color = color
	_sincronizar.rpc(jugadores)


@rpc("any_peer", "reliable")
func _pedir_listo(listo: bool) -> void:
	var id := _quien()
	if multiplayer.is_server() and jugadores.has(id):
		jugadores[id].listo = listo
		_sincronizar.rpc(jugadores)


@rpc("authority", "call_local", "reliable")
func _sincronizar(datos: Dictionary) -> void:
	jugadores = datos
	jugadores_cambiaron.emit()


@rpc("authority", "call_local", "reliable")
func _iniciar() -> void:
	partida_iniciada.emit()


func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server() or jugadores.is_empty():
		return
	_siguiente_sondeo -= delta
	if _siguiente_sondeo > 0:
		return
	_siguiente_sondeo = 2.0
	for id in multiplayer.get_peers():
		if _sondeos.has(id):
			latencias[id] = -1
		var marca := Time.get_ticks_msec()
		_sondeos[id] = marca
		_ping.rpc_id(id, marca)
	for id in latencias.keys():
		if not jugadores.has(id):
			latencias.erase(id)
			_sondeos.erase(id)
	_red_estado.rpc(latencias)


@rpc("authority", "call_remote", "unreliable")
func _ping(marca: int) -> void:
	_pong.rpc_id(1, marca)


@rpc("any_peer", "call_remote", "unreliable")
func _pong(marca: int) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not _sondeos.has(id) or _sondeos[id] != marca:
		return
	latencias[id] = maxi(Time.get_ticks_msec() - marca, 0)
	_sondeos.erase(id)
	_red_estado.rpc(latencias)


@rpc("authority", "call_local", "unreliable")
func _red_estado(datos: Dictionary) -> void:
	latencias = datos.duplicate()
	conexion_cambio.emit()


func texto_conexion(id: int) -> String:
	if id == 1:
		return "Anfitrión"
	var ms := int(latencias.get(id, -1))
	if ms < 0:
		return "Sin respuesta / midiendo"
	return "%d ms · %s" % [ms, "Buena" if ms < 90 else "Regular" if ms < 180 else "Alta latencia"]
