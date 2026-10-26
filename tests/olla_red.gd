extends SceneTree
## Tres peers ENet: --host / --join, sin --auto; --captura opcional en el host.
func _initialize() -> void:
	var p := Prueba.new()
	p.name = "PruebaOlla"
	root.add_child.call_deferred(p)

class Prueba extends Node:
	var main: Node
	var b: Node
	var ids: Array = []
	var casos := 0
	var fallos := 0
	var automatico := false
	var secuencia := 0
	var _pulsa := false
	var _cambio := 0.0
	var informes := {}
	var preparados := {}
	var cantidad := 3

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
		for i in 300:
			await esperar(0.1)
			if not main.is_node_ready():
				continue
			var red := get_node("/root/Red")
			if multiplayer.is_server() and red.jugadores.size() == cantidad and not main.juego.visible:
				for dato in red.jugadores.values():
					dato.listo = true
				red.iniciar_partida()
			if main.jugadores.get_child_count() == cantidad:
				break
		if main.jugadores.get_child_count() != cantidad:
			get_tree().quit(1)
			return
		b = main.juego.get_node("Partida").busqueda_olla
		b.vista.set_process(false)
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		if not multiplayer.is_server():
			preparado.rpc_id(1)
			return
		for intento in 100:
			if preparados.size() == cantidad - 1:
				break
			await esperar(0.1)
		ids = get_node("/root/Red").jugadores.keys()
		ids.sort()
		await probar()
		print("RESULTADO OLLA (%d jugadores): %d comprobaciones, %d fallos" % [cantidad, casos, fallos])
		terminar.rpc(fallos)

	func probar() -> void:
		var olla: Node = main.juego.get_node("Mundo/Olla")
		await acercar()
		olla.agarrar(1)
		comprobar(not olla.disponible() and olla.portador == 0, "La olla oculta no puede recogerse directamente")
		b.jugador(1).pedir_agarrar()
		comprobar(b.participantes.is_empty(), "No entra antes del rescate y del fuego")
		main.juego.get_node("Partida").rescate.rescatados = 2
		main.estacion.fogata.encendida = true
		main.estacion.fogata._publicar()
		b.jugador(1).pedir_agarrar()
		entrar.rpc_id(ids[1])
		await esperar(0.3)
		comprobar(b.participantes.size() == 2 and b.estado == "esperando", "Dos entradas no bastan si la partida tiene tres compas")
		b.jugador(ids[2])._perder_vida(100)
		entrar.rpc_id(ids[2])
		await esperar(0.2)
		comprobar(b.estado == "esperando", "Un compa caído no puede confirmar entrada")
		b.jugador(ids[2]).levantar()
		await esperar(0.3)
		entrar.rpc_id(ids[2])
		await esperar(0.3)
		for i in range(3, cantidad):
			entrar.rpc_id(ids[i])
		await esperar(0.3)
		comprobar(b.estado == "buscando" and b.manos.size() == cantidad, "La última E inicia la búsqueda y todos tienen manos")
		if b.estado != "buscando":
			return
		comprobar(not b.libre() and b.seleccionar(b.objetos[0].pos) != 0, "No puede agarrarse la olla a través del montón")
		var antes: Vector2 = b.manos[1].pos
		b.mover(b.encuentro - 1, 1000, Vector2(600, 400), true)
		b.mover(b.encuentro, 1000, Vector2(NAN, 1), true)
		b.mover(b.encuentro, 1000, Vector2(2000, 1), true)
		comprobar(b.manos[1].pos == antes and b._entradas[1].seq == -1, "Rechaza intentos viejos y cursores inválidos")
		# Agarrar y mover un objeto mediante el mismo RPC que usa la interfaz.
		var indice: int = b.objetos.size() - 1
		await llevar(b.objetos[indice].pos, false)
		secuencia += 1
		b.mover(b.encuentro, secuencia, b.objetos[indice].pos, true)
		comprobar(b.objetos[indice].dueno == 1, "Clic sostenido toma el objeto superior")
		comprobar(b.seleccionar(b.objetos[indice].pos) == -1, "Un segundo compa no puede robar el objeto agarrado")
		await llevar(Vector2(240, 400), true)
		await esperar(0.1)
		secuencia += 1
		b.mover(b.encuentro, secuencia, Vector2(240, 400), false)
		await esperar(0.5)
		comprobar(b.pilas[0] == 1 and b.aportes[1], "Arrastrar y soltar crea una pila y registra la ayuda")
		# No puede completar la misión mientras haya compas que no han ayudado.
		b.objetos[0].pos = b.SALIDA.get_center()
		b.objetos[0].dueno = 1
		b.manos[1].objeto = 0
		b._soltar(1, true)
		comprobar(not b.conseguida, "No se obtiene la olla si algún compa aún no apartó nada")
		b._desordenar()
		main._pedir_pausa(true)
		var tiempo: float = b.tiempo
		await esperar(0.3)
		comprobar(b.tiempo == tiempo, "Esc congela la búsqueda y sus derrumbes")
		var guardado := get_node("/root/Guardado")
		guardado.guardar(main, "user://olla_prueba.cfg")
		var datos: Dictionary = guardado.cargar("user://olla_prueba.cfg")
		guardado.restaurar_mundo(main, datos)
		comprobar(b.participantes.is_empty() and not b.conseguida, "Cargar una búsqueda pendiente libera controles y vuelve a ocultar la olla")
		main._pedir_pausa(false)
		await entrar_todos()
		# Preparar una pila alta; la física real debe avisar y luego derrumbarla.
		for i in range(1, b.LIMITE_PILA + 1):
			b.objetos[i].pos = Vector2(200, 400)
		for id in ids:
			b.jugador(id).vida = 100
			b.manos[id].pos = Vector2(640, 250)
		b.manos[1].pos = Vector2(200, 400)
		await esperar(0.2)
		comprobar(b.estado == "buscando" and b.riesgo[0] > 0, "Una pila alta avisa antes de caer")
		if "--captura" in OS.get_cmdline_user_args():
			b.vista._process(0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://olla_interior.png")
		await esperar(b.AVISO_CAIDA)
		comprobar(b.estado == "derrumbe", "La pila inestable se derrumba sin un temporizador global arbitrario")
		comprobar(b.jugador(1).vida == 88 and b.jugador(ids[2]).vida == 100, "La caída daña manos/brazos expuestos y respeta los retirados")
		await esperar(1.3)
		comprobar(b.estado == "buscando" and not b.libre() and b.pilas == [0, 0], "El derrumbe vuelve a tapar la olla y permite reintentar")
		# Una salida E libera a todo el equipo, no deja a los demás atrapados.
		entrar.rpc_id(ids[1])
		await esperar(0.3)
		comprobar(b.participantes.is_empty() and not b.jugador(1).en_tienda(), "Salir con E cancela para todos")
		await entrar_todos()
		control.rpc(true)
		for i in 900:
			await esperar(0.1)
			if b.conseguida:
				break
		control.rpc(false)
		comprobar(b.conseguida, "Todos los cursores reales cooperan hasta sacar la olla")
		if not b.conseguida:
			print("DIAGNOSTICO ", b.estado, " manos=", b.manos, " aportes=", b.aportes, " pilas=", b.pilas, " libre=", b.libre())
		await esperar(2.5)
		comprobar(olla.disponible() and olla.position.distance_to(b.lugar()) < 100 and b.participantes.is_empty(), "La olla aparece fuera de la tienda y todos recuperan el control")
		informar.rpc()
		await esperar(0.4)
		comprobar(informes.size() == cantidad and informes.values().all(func(v): return v), "Todos los peers reciben el desbloqueo de la olla")
		olla.agarrar(1)
		comprobar(olla.portador == 1, "La olla recuperada ya puede transportarse")
		main._pedir_pausa(true)
		guardado.guardar(main, "user://olla_prueba.cfg")
		datos = guardado.cargar("user://olla_prueba.cfg")
		comprobar(datos.get("olla_encontrada", false), "El guardado conserva la olla encontrada")
		guardado.restaurar_mundo(main, datos)
		comprobar(b.conseguida, "Cargar no obliga a repetir una búsqueda completada")
		DirAccess.remove_absolute("user://olla_prueba.cfg")
		main._pedir_pausa(false)
		olla.soltar(b.lugar() + Vector2(75, 15))
		b.conseguida = false
		await entrar_todos()
		desconectar.rpc_id(ids.back())
		await esperar(0.5)
		comprobar(b.participantes.is_empty() and not b.jugador(1).en_tienda(), "Una desconexión interrumpe y libera a todo el equipo")

	func acercar() -> void:
		for i in ids.size():
			var j: Node = b.jugador(ids[i])
			j._reaparecer.rpc(b.lugar() + Vector2((i - (cantidad - 1) * 0.5) * 25, 20))
			j.aturdimiento = 0
		await esperar(0.4)

	func entrar_todos() -> void:
		await acercar()
		b.jugador(1).pedir_agarrar()
		for id in ids:
			if id != 1:
				entrar.rpc_id(id)
		await esperar(0.4)
		secuencia = 0

	func llevar(punto: Vector2, pulsa: bool) -> void:
		for i in 25:
			secuencia += 1
			b.mover(b.encuentro, secuencia, punto, pulsa)
			await esperar(0.05)
			if Vector2(b.manos[1].pos).distance_to(punto) < 2:
				return

	func _process(delta: float) -> void:
		if not automatico or b == null or b.estado != "buscando" or not b.dentro(multiplayer.get_unique_id()):
			return
		var id := multiplayer.get_unique_id()
		var plan: Dictionary = b.plan_bot(id)
		_cambio += delta
		var pulsa: bool = plan.pulsa
		if b.manos[id].objeto < 0 and _pulsa and _cambio > 0.25:
			pulsa = false
		if pulsa != _pulsa:
			_cambio = 0.0
		_pulsa = pulsa
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		evento.pressed = pulsa
		evento.position = Vector2(plan.pos) * b.vista.lienzo.scale + b.vista.lienzo.position
		get_viewport().push_input(evento, true)

	@rpc("authority", "call_local", "reliable")
	func control(valor: bool) -> void:
		automatico = valor
		b.vista.set_process(valor)

	@rpc("authority", "call_remote", "reliable")
	func entrar() -> void:
		b.jugador(multiplayer.get_unique_id()).pedir_agarrar.rpc_id(1)

	@rpc("any_peer", "call_remote", "reliable")
	func preparado() -> void:
		preparados[multiplayer.get_remote_sender_id()] = true

	@rpc("authority", "call_remote", "reliable")
	func desconectar() -> void:
		get_node("/root/Red").salir()
		get_tree().quit(0)

	@rpc("authority", "call_local", "reliable")
	func informar() -> void:
		if multiplayer.is_server():
			informes[1] = b.conseguida
		else:
			informe.rpc_id(1, b.conseguida)

	@rpc("any_peer", "call_remote", "reliable")
	func informe(valor: bool) -> void:
		informes[multiplayer.get_remote_sender_id()] = valor

	@rpc("authority", "call_local", "reliable")
	func terminar(errores: int) -> void:
		await esperar(0.3)
		get_tree().quit(0 if errores == 0 else 1)
