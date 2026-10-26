extends SceneTree
## Dos o seis procesos con --cantidad=N, --host / --join y el mismo puerto.
func _initialize() -> void:
	var prueba := Equipo.new()
	prueba.name = "PruebaEquipo"
	root.add_child.call_deferred(prueba)

class Equipo extends Node:
	var main: Node
	var r: Node
	var cantidad := 6
	var ids: Array = []
	var soltar := false
	var casos := 0
	var fallos := 0

	func esperar(t: float) -> void:
		await get_tree().create_timer(t).timeout

	func comprobar(ok: bool, texto: String) -> void:
		casos += 1
		if not ok:
			fallos += 1
		print(("OK: " if ok else "FALLO: ") + texto)

	func _ready() -> void:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--cantidad="):
				cantidad = arg.get_slice("=", 1).to_int()
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for intento in 400:
			await esperar(0.1)
			if not main.is_node_ready():
				continue
			var red := get_node("/root/Red")
			if multiplayer.is_server() and red.jugadores.size() == cantidad and not main.juego.visible:
				for d in red.jugadores.values():
					d.listo = true
				red.iniciar_partida()
			if main.jugadores.get_child_count() == cantidad:
				break
		if main.jugadores.get_child_count() != cantidad:
			push_error("No se conectó todo el equipo de prueba")
			get_tree().quit(1)
			return
		r = main.juego.get_node("Partida").rescate
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		if not multiplayer.is_server():
			return
		ids = get_node("/root/Red").jugadores.keys()
		ids.sort()
		r.cebo = true
		await preparar()
		var ultimo: Node = r._jugador(ids.back())
		if cantidad > 3:
			ultimo._reaparecer.rpc(r.lugar() + Vector2(250, 0))
			r.interactuar(r._jugador(1))
			comprobar(not r.activo(), "No arranca si un jugador del suelo está lejos")
			ultimo._reaparecer.rpc(r.lugar() + Vector2(75, 0))
			ultimo._perder_vida(100)
			r.interactuar(r._jugador(1))
			comprobar(not r.activo() and r.mensaje.contains("revivan"), "El caído del suelo también es obligatorio")
			await preparar()
		r.interactuar(r._jugador(1))
		comprobar(r.activo() and r.participantes.size() == cantidad and r.torre_ids.size() == mini(cantidad, 3), "Participa todo el equipo sin exceder tres en la torre")
		await esperar(4.5)
		comprobar(r.estado == "ritmo", "Todos los participantes envían mouse válido")
		if cantidad > 3:
			cambiar.rpc_id(ids.back(), true)
			await esperar(0.65)
			comprobar(r.estado == "regreso" and ids.all(func(id): return r._jugador(id).apoyo_id == 0), "Si falla uno del suelo también se derrumba la torre")
			comprobar(r._jugador(ids[2]).vida == 88 and ultimo.vida == 100, "El arañazo corresponde a la cima, no al último participante del suelo")
			cambiar.rpc_id(ids.back(), false)
			await esperar(1.5)
			await preparar()
			r.interactuar(r._jugador(1))
		for intento in 300:
			await esperar(0.1)
			if r.rescatados == 1 or r.estado == "regreso":
				break
		comprobar(r.rescatados == 1, "El equipo completo puede terminar el rescate")
		print("RESULTADO EQUIPO %d: %d comprobaciones, %d fallos" % [cantidad, casos, fallos])
		terminar.rpc(fallos)

	func preparar() -> void:
		var torre: Node = main.juego.get_node("Partida").torre
		torre.romper_desde(r._jugador(1))
		for i in ids.size():
			var j: Node = r._jugador(ids[i])
			j.levantar()
			j.vida = 100
			j._reaparecer.rpc(r.lugar() + (Vector2.ZERO if i < 3 else Vector2(75, (i - 4) * 20)))
			j.aturdimiento = 0
		await esperar(0.4)
		for i in range(1, mini(cantidad, 3)):
			torre._montar.rpc(ids[i], ids[i - 1])
		await esperar(0.4)

	func _process(_delta: float) -> void:
		if r == null or not r.contiene(multiplayer.get_unique_id()) or r.estado not in ["preparando", "ritmo"]:
			return
		var reto: Node = r.reto
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = not soltar
		b.position = reto.objetivo(maxi(reto._paso_mostrado, 0), r.participantes.find(multiplayer.get_unique_id()), reto.progreso_mostrado()) * reto.LIENZO * reto._vista.scale + reto._vista.position
		get_viewport().push_input(b, true)

	@rpc("authority", "call_local", "reliable")
	func cambiar(valor: bool) -> void:
		soltar = valor

	@rpc("authority", "call_local", "reliable")
	func terminar(errores: int) -> void:
		await esperar(0.25)
		get_tree().quit(0 if errores == 0 else 1)
