extends SceneTree
## Dos procesos --host / --join=127.0.0.1, ambos --auto y mismo --puerto.
const SITIO := Vector2(5300, 350)


func _initialize() -> void:
	var prueba := Prueba.new()
	prueba.name = "PruebaUltra"
	root.add_child.call_deferred(prueba)


class Prueba extends Node:
	var main: Node
	var cliente := 0
	var fallos := 0
	var informe := {}
	var ultra: Node2D


	func _ready() -> void:
		for accion in InputMap.get_actions():
			InputMap.action_erase_events(accion)
			Input.action_release(accion)
		main = load("res://escenas/main.tscn").instantiate()
		main.bot_de_ayuda = false
		get_tree().root.add_child.call_deferred(main)
		for i in range(600):
			await get_tree().process_frame
			if main.is_node_ready() and main.jugadores.get_child_count() == 2 and is_instance_valid(main.jefe.ultra):
				break
		if main.jugadores.get_child_count() != 2:
			get_tree().quit(1)
			return
		ultra = main.jefe.ultra
		if not multiplayer.is_server():
			return
		cliente = multiplayer.get_peers()[0]
		await _esperar(0.3)
		await _probar()
		print("RESULTADO ULTRA: %d fallos" % fallos)
		_finalizar.rpc(fallos)


	func _probar() -> void:
		var osa = main.jefe
		var host = _j(1)
		osa.set_physics_process(false)
		osa.activa = true
		osa.fase = 3
		osa.vida_max = 500
		osa.vida = 10
		osa.estado = "pausa"
		osa.position = SITIO
		host._reaparecer.rpc(SITIO + Vector2(-60, 0))
		_j(cliente)._reaparecer.rpc(SITIO + Vector2(0, 180))
		await _esperar(0.2)
		host.golpear(1)
		await _esperar(0.25)
		_comprobar(osa.fase == 4 and osa.vida == 250 and not main.juego.get_node("Partida").finalizada,
			"Agotar la tercera fase activa la ultra con 50 % de vida adicional, sin victoria prematura")
		await _consultar()
		_comprobar(informe.get("fase") == 4 and informe.get("activa", false), "El cliente entra a la misma ultra fase")
		var vida: int = osa.vida
		osa.golpeada(1, host)
		_comprobar(osa.vida == vida and not host.combo.enemigo_valido(osa), "No se puede dañar el cuerpo invisible durante la preparación")
		osa.enfurecer("prueba")
		osa.tambalear(1)
		osa.empezar_rivalidad()
		_comprobar(osa.fase == 4 and osa.estado == "ultra", "Olla, tambaleo y rivalidad no devuelven la osa a una fase anterior")
		# El controlador real ya inició; congelar solo su selección de próximos ataques.
		ultra._reloj = 100
		for id in [1, cliente]:
			await _colocar(id)
			ultra._atacar.rpc(SITIO, false, 0)
			await _esperar(0.3)
			_comprobar(_j(id).vida == 100, "La preparación vertical todavía no hace daño (%d)" % id)
			await _esperar(0.3)
			_comprobar(_j(id).vida == 75, "La garra vertical aplica 25 al contacto (%d)" % id)
			await _esperar(0.45)
			await _consultar()
			_comprobar(_j(id).vida == 75 and informe.get("vidas", {}).get(id) == 75,
				"Daño único y sincronizado durante toda la mano apoyada (%d)" % id)
			await _esperar(1.5)

		await _colocar(1)
		ultra._atacar.rpc(SITIO, false, 0)
		host._reaparecer.rpc(SITIO + Vector2(0, 180))
		await _esperar(0.6)
		_comprobar(host.vida == 100, "Salir del cuerpo completo antes del contacto evita la garra; no persigue al jugador")
		await _esperar(2.0)
		for lado in [-1, 1]:
			await _colocar(1)
			ultra._atacar.rpc(SITIO, true, lado)
			await _esperar(0.55)
			_comprobar(host.vida == 80, "Barrido desde el lado %d causa 20 de daño" % lado)
			await _esperar(2.0)
		await _colocar(1)
		ultra._atacar.rpc(SITIO, true, -1)
		await _esperar(0.18)
		Input.action_press("saltar")
		await _esperar(0.05)
		Input.action_release("saltar")
		await _esperar(0.3)
		_comprobar(host.vida == 100 and host.altura > 28, "Un salto real esquiva el barrido bajo")
		await _esperar(2.0)
		await _colocar(1)
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.39)
		host.pedir_rodar(Vector2.RIGHT)
		await _esperar(0.18)
		_comprobar(host.vida == 100, "Rodar a tiempo esquiva la garra vertical")
		await _esperar(2.0)
		await _colocar(1)
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.2)
		main._pedir_pausa(true)
		await get_tree().create_timer(0.6, true).timeout
		_comprobar(host.vida == 100, "La pausa congela preparación y daño")
		main._pedir_pausa(false)
		await _esperar(0.4)
		_comprobar(host.vida == 75, "Al reanudar llega un solo contacto")
		await _esperar(2.0)
		# La cámara del cliente puede estar muy lejos sin mover el ataque del mundo.
		await _colocar(cliente)
		_camara_lejos.rpc_id(cliente)
		ultra._atacar.rpc(SITIO, true, 1)
		await _esperar(0.55)
		await _consultar()
		_comprobar(informe.get("contacto", Vector2.ZERO).distance_to(SITIO) < 0.1 and _j(cliente).vida == 80,
			"El barrido conserva coordenadas del mundo con cámaras distintas")
		await _esperar(2.0)
		await _colocar(1)
		_ataque_ajeno.rpc_id(cliente)
		await _esperar(0.6)
		_comprobar(host.vida == 100 and ultra._ataques.is_empty(), "El cliente no puede inventar ataques de la osa")
		ultra._atacar.rpc(SITIO, false, 0)
		ultra._physics_process(0.8)
		_comprobar(host.vida == 75, "Un tick largo que cruza el contacto no pierde el daño")
		ultra._physics_process(0.1)
		_comprobar(host.vida == 75, "El mismo contacto no se repite al avanzar otro tick")
		await _esperar(2.0)
		await _colocar(1)
		# Mano apoyada: daño real de un combo completo, sin saltarse la recuperación.
		host._reaparecer.rpc(SITIO + Vector2(-90, 40))
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.57)
		host._reaparecer.rpc(SITIO + Vector2(-60, 0))
		await _esperar(0.05)
		vida = osa.vida
		for tipo in range(4):
			host.golpear(1, tipo)
			await _esperar(0.2)
		_comprobar(osa.vida == vida - 74 and host.combo.criticos > 0,
			"La mano expuesta recibe los cuatro golpes y la patada crítica")
		await _esperar(1.0)
		_comprobar(not osa.puede_recibir_golpe(), "Recoger la mano cierra la vulnerabilidad")
		await _colocar(1)
		host._reaparecer.rpc(SITIO + Vector2(-150, 0))
		host.mirando = 1
		host.botellas = 2
		vida = osa.vida
		host.pedir_lanzar(0.0)
		await _esperar(0.3)
		_comprobar(osa.vida == vida, "Una botella no daña el antiguo cuerpo cuando la mano está recogida")
		await _esperar(0.7)
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.57)
		host.pedir_lanzar(0.0)
		await _esperar(0.25)
		_comprobar(osa.vida == vida - 12, "La botella real sí impacta en la mano apoyada")
		await _esperar(1.7)
		await _colocar(1)
		host._reaparecer.rpc(SITIO + Vector2(-200, 0))
		_j(cliente)._reaparecer.rpc(SITIO + Vector2(-170, 0))
		await _esperar(0.15)
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.57)
		vida = osa.vida
		host.combate.pedir_empujon(1)
		await _esperar(0.45)
		_comprobar(osa.vida == vida - 40 and _j(cliente).vida == 85, "Un compazo alcanza la mano y conserva el daño a ambos")
		await _esperar(1.5)
		await _colocar(1)
		# Verificar el ciclo automático completo, no solo ataques llamados por la prueba.
		ultra._etapa = "entrada"
		ultra._reloj = 0
		var numero: int = ultra._numero
		host._reaparecer.rpc(SITIO)
		await _esperar(3.8)
		_comprobar(ultra._numero > numero and host.vida < 100, "La IA de ultra prepara y ejecuta ataques por sí sola")
		ultra._reloj = 100
		await _esperar(2.0)
		await _colocar(1)
		host._reaparecer.rpc(SITIO + Vector2(0, 180))
		ultra._atacar.rpc(SITIO, false, 0)
		await _esperar(0.55)
		osa.vida = 10
		host._reaparecer.rpc(SITIO + Vector2(-60, 0))
		await _esperar(0.05)
		host.golpear(1)
		await _esperar(0.3)
		await _consultar()
		_comprobar(osa.estado == "derrotada" and informe.get("victoria", false), "Solo derrotar la ultra termina la partida y replica la victoria")
		_comprobar(ultra._ataques.is_empty() and not ultra.activa, "La victoria limpia ataques pendientes y apaga la ultra")
		main._preparar_sala()
		await _esperar(0.4)
		for datos in get_node("/root/Red").jugadores.values():
			datos.listo = true
		get_node("/root/Red").iniciar_partida()
		await _esperar(0.5)
		ultra = main.jefe.ultra
		_comprobar(main.jefe.fase == 1 and not ultra.activa and ultra._ataques.is_empty(),
			"Otra ronda reconstruye la ultra sin manos ni estado anteriores")
		await _colocar(1)
		main.jefe.activa = true
		main.jefe.vida_max = 500
		main.jefe.fase = 3
		main.jefe.vida = 1
		main.jefe.danar_por_abeja(10)
		_comprobar(main.jefe.fase == 4 and ultra.activa, "El último golpe de la abeja también activa la ultra")
		ultra._reloj = 100
		ultra._atacar.rpc(SITIO, false, 0)
		main.juego.get_node("Partida").terminar(false)
		await _esperar(0.8)
		_comprobar(_j(1).vida == 100 and ultra._ataques.is_empty() and not ultra.activa,
			"Terminar la ronda durante la preparación cancela el daño pendiente")


	func _j(id: int) -> Node2D:
		return main.jugadores.get_node(str(id))

	func _colocar(id: int) -> void:
		for quien in [1, cliente]:
			var j = _j(quien)
			j._reaparecer.rpc(SITIO + Vector2(0, 0 if quien == id else 180))
			j.vida = 100
			j.aturdimiento = 0
			j.proteccion = 0
			j._espera_servidor = 0
			j.espera_rodar = 0
		await _esperar(0.2)

	func _esperar(t: float) -> void:
		await get_tree().create_timer(t, true, true).timeout

	func _comprobar(ok: bool, mensaje: String) -> void:
		print(("OK: " if ok else "FALLO: ") + mensaje)
		if not ok:
			fallos += 1

	func _consultar() -> void:
		informe = {}
		_informar.rpc_id(cliente)
		for i in range(120):
			await get_tree().process_frame
			if not informe.is_empty():
				break

	@rpc("authority", "reliable")
	func _camara_lejos() -> void:
		var camara := get_viewport().get_camera_2d()
		camara.offset = Vector2(2000, -100)

	@rpc("authority", "reliable")
	func _ataque_ajeno() -> void:
		ultra._atacar.rpc_id(1, SITIO, false, 0)

	@rpc("authority", "reliable")
	func _informar() -> void:
		var vidas := {}
		for j in main.jugadores.get_children():
			vidas[j.name.to_int()] = j.vida
		_datos.rpc_id(1, {"fase": main.jefe.fase, "activa": ultra.activa, "vidas": vidas,
			"contacto": ultra._ataques[0].contacto if not ultra._ataques.is_empty() else Vector2.ZERO,
			"victoria": main.juego.get_node("Partida").victoria})

	@rpc("any_peer", "reliable")
	func _datos(datos: Dictionary) -> void:
		if multiplayer.is_server() and multiplayer.get_remote_sender_id() == cliente:
			informe = datos

	@rpc("authority", "call_local", "reliable")
	func _finalizar(errores: int) -> void:
		get_tree().quit(0 if errores == 0 else 1)
