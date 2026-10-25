extends SceneTree
## Host --host; dos clientes normales --bot-torre --bot-turno=1/2 --auto.
func _initialize() -> void:
	var prueba := Prueba.new()
	root.add_child.call_deferred(prueba)

class Prueba extends Node:
	var main: Node
	var r: Node
	var fallos := 0
	var activo := false

	func esperar(t: float) -> void:
		await get_tree().create_timer(t).timeout

	func comprobar(ok: bool, texto: String) -> void:
		print(("OK: " if ok else "FALLO: ") + texto)
		if not ok:
			fallos += 1

	func _ready() -> void:
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in 1200:
			await get_tree().process_frame
			if main.is_node_ready() and not main.juego.visible and get_node("/root/Red").jugadores.size() == 3:
				for d in get_node("/root/Red").jugadores.values():
					d.listo = true
				get_node("/root/Red").iniciar_partida()
			if main.is_node_ready() and main.jugadores.get_child_count() == 3:
				break
		if main.jugadores.get_child_count() != 3:
			get_tree().quit(1)
			return
		r = main.juego.get_node("Partida").rescate
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		var j: Node2D = main.jugadores.get_node("1")
		j._reaparecer.rpc(r.lugar())
		main.juego.get_node("Mundo/Miel").soltar(r.lugar() + Vector2(75, 0))
		var i := 0
		for id in multiplayer.get_peers():
			main.jugadores.get_node(str(id))._reaparecer.rpc(r.lugar() + Vector2(120 + i * 30, 0))
			i += 1
		for n in 140:
			await esperar(0.1)
			if r.cebo:
				break
		comprobar(r.cebo, "Los bots recogen miel y la ofrecen en el árbol")
		if not r.cebo:
			for compa in main.jugadores.get_children():
				print("BOT ", compa.name, " posicion=", compa.position, " altura=", compa.altura, " apoyo=", compa.apoyo_id, " pieza=", compa._pieza_cargada())
			print("MIEL ", main.juego.get_node("Mundo/Miel").position, " portador=", main.juego.get_node("Mundo/Miel").portador)
			get_tree().quit(1)
			return
		for n in 160:
			await esperar(0.1)
			if j._torre()._cadena(j).size() == 3:
				break
		comprobar(j._torre()._cadena(j).size() == 3, "Los dos bots se acercan, saltan y forman la torre con el humano")
		activo = true
		for numero in 2:
			j.pedir_agarrar()
			for n in 300:
				await esperar(0.1)
				if r.rescatados > numero or r.estado == "regreso":
					break
			comprobar(r.rescatados > numero, "Los bots coordinan el equilibrio para rescatar al osezno %d" % (numero + 1))
			await esperar(0.3)
		print("RESULTADO BOTS RESCATE: 4 comprobaciones, %d fallos" % fallos)
		get_tree().quit(0 if fallos == 0 else 1)

	func _process(_delta: float) -> void:
		if not activo:
			return
		Input.action_release("izquierda")
		Input.action_release("derecha")
		if r.contiene(1) and absf(r.equilibrio) > 0.1:
			Input.action_press("izquierda" if r.equilibrio > 0 else "derecha")
