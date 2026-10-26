extends Node
## Una ranura local del anfitrión. Guarda estado estable, no ataques en vuelo.
const RUTA := "user://partida.cfg"
const VERSION := 1
const ESTACION := ["progreso", "terminada", "alimento", "tiempo", "alimentados", "vida_olla"]
const JUGADOR := ["vida", "caido", "cervezas", "botellas", "borrachera", "arma_tiempo"]
const JEFE := ["activa", "vida", "vida_max", "fase", "enojo", "position"]
var ultimo_error := ""
var pendiente := {}

func existe() -> bool:
	return FileAccess.file_exists(RUTA)

func propiedades(nodo: Node, nombres: Array) -> Dictionary:
	var datos := {}
	for clave in nombres:
		datos[clave] = nodo.get(clave)
	return datos

func aplicar(nodo: Node, datos: Dictionary, nombres: Array) -> void:
	for clave in nombres:
		if datos.has(clave):
			nodo.set(clave, datos[clave])

func guardar(main: Node, ruta := RUTA) -> String:
	if not multiplayer.is_server() or not main.juego.visible or not get_tree().paused or main.juego.get_node("Partida").finalizada:
		return "Solo el anfitrión puede guardar una partida en pausa."
	var f: Node = main.estacion.fogata
	var partida: Node = main.juego.get_node("Partida")
	if main.jugadores.get_children().all(func(j): return j.caido):
		return "Revivan a un compañero antes de guardar."
	var datos := {"version": VERSION, "fecha": Time.get_datetime_string_from_system(),
		"rescate": propiedades(partida.rescate, ["rescatados", "cebo"]),
		"olla_encontrada": partida.busqueda_olla.conseguida,
		"miel_conseguida": partida.oleadas_miel.completada,
		"estacion": propiedades(main.estacion, ESTACION), "jefe": propiedades(main.jefe, JEFE),
		"jugadores": [], "piezas": {}, "cervezas": {}, "enjambres": {}, "arboles": {}, "armas": [],
		"fogata": {"colocados": f.colocados, "encendida": f.encendida, "suelo": f.suelo.duplicate()},
		"abeja": propiedades(partida.abeja_musculosa, ["bajas", "encuentro", "vida", "position", "ganados", "perdidos", "_reposo", "_grupos_sin_fusion"]),
		"abeja_activa": partida.abeja_musculosa.estado in partida.abeja_musculosa.ACTIVOS}
	for j in main.jugadores.get_children():
		var d := propiedades(j, JUGADOR)
		d.merge({"nombre": j.nombre, "color": j.color_indice, "anfitrion": j.name == "1", "position": j.position,
			"palos": f.cantidad(j.name.to_int()), "estadisticas": partida.estadisticas.get(j.name.to_int(), {}).duplicate()})
		datos.jugadores.append(d)
	for p in get_tree().get_nodes_in_group("piezas"):
		datos.piezas[str(p.name)] = {"position": p.position, "entregada": p.entregada}
	for c in get_tree().get_nodes_in_group("cervezas"):
		datos.cervezas[str(c.name)] = propiedades(c, ["disponible", "_tiempo"])
	for e in get_tree().get_nodes_in_group("enjambres"):
		datos.enjambres[str(e.name)] = propiedades(e, ["vivas", "_reapariciones", "_furiosas", "position"])
	for a in get_tree().get_nodes_in_group("arboles_con_palos"):
		datos.arboles[str(a.name)] = a.golpes
	for arma in get_tree().get_nodes_in_group("armas_temporales"):
		if arma.disponible:
			datos.armas.append(propiedades(arma, ["position", "restante"]))
	var archivo := ConfigFile.new()
	archivo.set_value("partida", "datos", datos)
	var error := archivo.save(ruta + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(ruta + ".tmp", ruta)
	return "Partida guardada. Continúa desde el menú; cada compa debe elegir su mismo color." if error == OK else "No se pudo guardar (error %d)." % error

func cargar(ruta := RUTA) -> Dictionary:
	ultimo_error = ""
	var archivo := ConfigFile.new()
	if archivo.load(ruta) != OK:
		ultimo_error = "No se pudo leer la partida guardada."
		return {}
	var datos = archivo.get_value("partida", "datos", {})
	if not datos is Dictionary or datos.get("version") != VERSION:
		ultimo_error = "Guardado incompatible o dañado."
		return {}
	for clave in ["estacion", "jefe", "fogata", "abeja", "piezas", "cervezas", "enjambres", "arboles"]:
		if not datos.get(clave) is Dictionary:
			ultimo_error = "Guardado incompleto."
			return {}
	if not datos.get("jugadores") is Array or datos.jugadores.is_empty():
		ultimo_error = "El guardado no contiene jugadores."
		return {}
	for j in datos.jugadores:
		if not j is Dictionary or not j.get("position") is Vector2 or not j.get("color") is int or not j.get("vida") is int:
			ultimo_error = "Datos de jugador dañados."
			return {}
	if not _validar(datos):
		ultimo_error = "El guardado contiene valores incompletos o inválidos."
		return {}
	return datos

func _campos(datos: Dictionary, esquema: Dictionary) -> bool:
	for clave in esquema:
		if typeof(datos.get(clave)) != esquema[clave]:
			return false
		if datos[clave] is float and not is_finite(datos[clave]):
			return false
		if datos[clave] is Vector2 and not datos[clave].is_finite():
			return false
	return true

func _validar(d: Dictionary) -> bool:
	if d.has("miel_conseguida") and not d.miel_conseguida is bool:
		return false
	if d.has("olla_encontrada") and not d.olla_encontrada is bool:
		return false
	if d.has("rescate") and (not d.rescate is Dictionary or not _campos(d.rescate, {"rescatados": TYPE_INT, "cebo": TYPE_BOOL}) or d.rescate.rescatados not in [0, 1, 2]):
		return false
	if not _campos(d.estacion, {"progreso": TYPE_FLOAT, "terminada": TYPE_BOOL, "alimento": TYPE_FLOAT,
			"tiempo": TYPE_FLOAT, "alimentados": TYPE_BOOL, "vida_olla": TYPE_INT}):
		return false
	if not _campos(d.jefe, {"activa": TYPE_BOOL, "vida": TYPE_INT, "vida_max": TYPE_INT,
			"fase": TYPE_INT, "enojo": TYPE_INT, "position": TYPE_VECTOR2}) or d.jefe.fase not in [1, 2, 3, 4] or d.jefe.vida_max <= 0:
		return false
	if not _campos(d.fogata, {"colocados": TYPE_INT, "encendida": TYPE_BOOL, "suelo": TYPE_DICTIONARY}) or d.fogata.colocados not in [0, 1, 2]:
		return false
	for valor in d.fogata.suelo.values():
		if not valor is Vector2 or not valor.is_finite():
			return false
	if not _campos(d.abeja, {"bajas": TYPE_INT, "encuentro": TYPE_INT, "vida": TYPE_INT,
			"position": TYPE_VECTOR2, "ganados": TYPE_INT, "perdidos": TYPE_INT, "_reposo": TYPE_FLOAT, "_grupos_sin_fusion": TYPE_INT}) or not d.get("abeja_activa") is bool:
		return false
	for j in d.jugadores:
		if not _campos(j, {"nombre": TYPE_STRING, "color": TYPE_INT, "position": TYPE_VECTOR2, "vida": TYPE_INT,
				"caido": TYPE_BOOL, "cervezas": TYPE_INT, "botellas": TYPE_INT, "borrachera": TYPE_FLOAT,
				"arma_tiempo": TYPE_FLOAT, "palos": TYPE_INT, "estadisticas": TYPE_DICTIONARY}):
			return false
		if j.vida < 0 or j.vida > 100 or j.color < 0 or j.color >= 6 or j.palos < 0 or j.palos > 2:
			return false
	for pieza in d.piezas.values():
		if not pieza is Dictionary or not _campos(pieza, {"position": TYPE_VECTOR2, "entregada": TYPE_BOOL}):
			return false
	for cerveza in d.cervezas.values():
		if not cerveza is Dictionary or not _campos(cerveza, {"disponible": TYPE_BOOL, "_tiempo": TYPE_FLOAT}):
			return false
	for enjambre in d.enjambres.values():
		if not enjambre is Dictionary or not _campos(enjambre, {"position": TYPE_VECTOR2, "vivas": TYPE_INT,
				"_furiosas": TYPE_BOOL, "_reapariciones": TYPE_ARRAY}) or enjambre._reapariciones.size() != 5:
			return false
		for tiempo in enjambre._reapariciones:
			if not (tiempo is float or tiempo is int) or not is_finite(tiempo):
				return false
	if not d.get("armas") is Array:
		return false
	for arma in d.armas:
		if not arma is Dictionary or not _campos(arma, {"position": TYPE_VECTOR2, "restante": TYPE_FLOAT}):
			return false
	return true

func jugador_guardado(color: int) -> Dictionary:
	for j in pendiente.get("jugadores", []):
		if j.color == color:
			return j
	return {}

func restaurar_mundo(main: Node, datos: Dictionary) -> void:
	var miel: Node = main.juego.get_node("Partida").oleadas_miel
	miel.cancelar()
	miel.completada = datos.get("miel_conseguida", datos.piezas.get("Miel", {}).get("entregada", false) or datos.estacion.terminada or datos.estacion.alimentados)
	var busqueda: Node = main.juego.get_node("Partida").busqueda_olla
	busqueda.cancelar()
	busqueda.conseguida = datos.get("olla_encontrada", datos.piezas.get("Olla", {}).get("entregada", false) or datos.estacion.terminada or datos.estacion.alimentados)
	var rescate: Node = main.juego.get_node("Partida").rescate
	# Las partidas anteriores con fuego ya habían pasado esta etapa.
	var avance: Dictionary = datos.get("rescate", {"rescatados": 2 if datos.fogata.encendida else 0, "cebo": false})
	aplicar(rescate, avance, ["rescatados", "cebo"])
	rescate.estado = "esperando"
	rescate.participantes.clear()
	rescate.torre_ids.clear()
	rescate.reto.limpiar()
	rescate.paso = 0
	rescate.avances = []
	rescate.miedo = 0.15
	rescate.equilibrio = 0.0
	rescate.calma = 0.0
	rescate.mensaje = "Miel preparada · reúnan al equipo, formen la torre y pulsen E" if rescate.cebo else "Traigan miel y reúnan a todo el equipo junto al árbol"
	aplicar(main.estacion, datos.estacion, ESTACION)
	aplicar(main.jefe, datos.jefe, JEFE)
	main.jefe._fase_anunciada = main.jefe.fase
	main.jefe.estado = "pausa" if main.jefe.activa else "dormida"
	main.jefe._t = 0
	main.jefe._duracion = 2.0
	if main.jefe.fase == 4:
		main.jefe.estado = "ultra"
		main.jefe.ancho = 90.0
		main.jefe.alto_botella = 120.0
		if multiplayer.is_server():
			main.jefe.ultra.iniciar()
	var mundo: Node = main.juego.get_node("Mundo")
	for nombre in datos.piezas:
		var p := mundo.get_node_or_null(NodePath(nombre))
		if p:
			p.portador = 0
			aplicar(p, datos.piezas[nombre], ["position", "entregada"])
	for nombre in datos.cervezas:
		var c := mundo.get_node_or_null(NodePath(nombre))
		if c:
			aplicar(c, datos.cervezas[nombre], ["disponible", "_tiempo"])
			c.visible = c.disponible
	for nombre in datos.enjambres:
		var e := mundo.get_node_or_null(NodePath(nombre))
		if e:
			aplicar(e, datos.enjambres[nombre], ["vivas", "_reapariciones", "_furiosas", "position"])
	for a in get_tree().get_nodes_in_group("arboles_con_palos"):
		a.golpes = datos.arboles.get(str(a.name), 0)
	var abeja: Node = main.juego.get_node("Partida").abeja_musculosa
	aplicar(abeja, datos.abeja, ["bajas", "encuentro", "vida", "position", "ganados", "perdidos", "_reposo", "_grupos_sin_fusion"])
	abeja.estado = "buscando" if datos.abeja_activa else "inactiva"
	var f: Node = main.estacion.fogata
	f.colocados = datos.fogata.colocados
	f.encendida = datos.fogata.encendida
	f.suelo = datos.fogata.suelo.duplicate()
	for numero in f.suelo:
		f._numero = maxi(f._numero, int(numero))
	if multiplayer.is_server():
		for arma in datos.armas:
			var partida: Node = main.juego.get_node("Partida")
			partida.soltar_arma(arma.position)
			mundo.get_node("Aguijon%d" % partida._numero_arma).restante = arma.restante
		f.inventario.clear()
		for guardado in datos.jugadores:
			var nuevo_id := 0
			for id in Red.jugadores:
				if Red.jugadores[id].color == guardado.color:
					nuevo_id = id
					break
			if nuevo_id != 0:
				f.inventario[nuevo_id] = guardado.palos
				if not guardado.estadisticas.is_empty():
					main.juego.get_node("Partida").estadisticas[nuevo_id] = guardado.estadisticas.duplicate()
			else:
				# Los palos de un compañero ausente quedan recuperables.
				for i in guardado.palos:
					f._numero += 1
					f.suelo[f._numero] = guardado.position + Vector2(i * 20, 0)
		f.mensaje = "Fogata encendida" if f.encendida else "Dos jugadores: pulsen E para encender" if f.colocados == 2 else "Busquen y coloquen dos palos"
		f._publicar()
