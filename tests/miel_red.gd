extends SceneTree
## ENet real, tres peers. Sin --auto para mantener la escena bajo control del test.
func _initialize() -> void:
	var p := Prueba.new()
	p.name = "PruebaMiel"
	root.add_child.call_deferred(p)

class Prueba extends Node:
	var main: Node
	var b: Node
	var ids: Array = []
	var preparados := {}
	var informes := {}
	var casos := 0
	var fallos := 0
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
			push_error("No se conectaron los tres peers de miel")
			get_tree().quit(1)
			return
		b = main.juego.get_node("Partida").oleadas_miel
		main.jefe.set_physics_process(false)
		for e in get_tree().get_nodes_in_group("enjambres"):
			e.set_physics_process(false)
		if not multiplayer.is_server():
			preparado.rpc_id(1)
			return
		for i in 100:
			if preparados.size() == cantidad - 1:
				break
			await esperar(0.1)
		ids = get_node("/root/Red").jugadores.keys()
		ids.sort()
		await probar()
		print("RESULTADO MIEL: %d comprobaciones, %d fallos" % [casos, fallos])
		terminar.rpc(fallos)

	func probar() -> void:
		var p: Node = b.partida()
		var j: Node2D = b.jugador(1)
		var miel: Node2D = main.juego.get_node("Mundo/Miel")
		comprobar(miel.disponible(), "Existe miel de señuelo antes del rescate")
		p.rescate.cebo = true
		comprobar(not miel.disponible(), "El señuelo consumido no permite saltarse las oleadas")
		p.rescate.rescatados = 2
		main.estacion.fogata.encendida = true
		main.estacion.fogata._publicar()
		await acercar()
		await esperar(2.2)
		comprobar(not b.activa(), "La reunión no inicia antes de conseguir la olla")
		p.busqueda_olla.conseguida = true
		b.jugador(ids[2])._reaparecer.rpc(Vector2(5000, 665))
		await esperar(2.4)
		comprobar(not b.activa(), "Falta un compa: no empieza")
		await acercar()
		b.jugador(ids[2])._perder_vida(100)
		await esperar(2.4)
		comprobar(not b.activa(), "Un compa caído bloquea el inicio")
		b.jugador(ids[2]).levantar()
		await esperar(2.4)
		comprobar(b.estado == "aviso", "Todos vivos y reunidos inician con aviso")
		b.set_physics_process(false)
		b.iniciar_ola(1)
		for e in b.enemigos:
			e.set_physics_process(false)
		comprobar(b.restantes() == 4 + ceili(cantidad / 2.0) and b.enemigos.filter(func(e): return e.fusionable).is_empty(), "Ola 1: enjambres escalados al equipo sin fusión")
		var e: Node2D = b.enemigos[0]
		e.position = j.position + Vector2(40, 0)
		await esperar(0.2)
		j.golpear(1, 0)
		await esperar(0.4)
		comprobar(e.vida == 4, "El puño H real mata una abeja del enjambre")
		var bajas: int = p.abeja_musculosa.bajas
		matar_ola(j)
		comprobar(b.restantes() == 0 and p.abeja_musculosa.bajas == bajas, "Sin reaparición ni fusión ambiental al eliminar enjambres")
		b._physics_process(0.1)
		comprobar(b.estado == "descanso", "Descanso entre oleadas")
		b._physics_process(3.1)
		comprobar(b.ola == 2 and b.enemigos.filter(func(a): return a.fusionable).size() == 2, "Ola 2 contiene exactamente dos grupos que se fusionan")
		e = b.enemigos[0]
		for i in 3:
			e.golpeada(1, j)
		comprobar(e.estado == "fusion", "Tres bajas muestran la fusión")
		e._physics_process(1.9)
		comprobar(e.tipo == "musculosa" and e.vida > 140, "La fusión produce una musculosa con vida completa")
		b.enemigos[1]._edad = 5.1
		b.enemigos[1]._physics_process(0.1)
		comprobar(b.enemigos[1].estado == "fusion", "La segunda fusión aparece aunque aún no la golpeen")
		b.enemigos[1]._physics_process(1.9)
		matar_ola(j)
		b._physics_process(0.1)
		b._physics_process(3.1)
		comprobar(b.ola == 3 and b.enemigos.filter(func(a): return a.vivo() and a.tipo != "musculosa").is_empty(), "Ola 3 solo contiene musculosas")
		matar_ola(j)
		b._physics_process(0.1)
		b._physics_process(3.1)
		var vivos: Array = b.enemigos.filter(func(a): return a.vivo())
		comprobar(b.ola == 4 and vivos.any(func(a): return a.tipo == "musculosa") and vivos.any(func(a): return a.tipo == "enjambre"), "Ola 4 es una emboscada mixta")
		matar_ola(j)
		b._physics_process(0.1)
		b._physics_process(3.1)
		vivos = b.enemigos.filter(func(a): return a.vivo())
		comprobar(b.ola == 5 and vivos.all(func(a): return a.tipo == "musculosa" and a.escupe_miel), "Ola 5: musculosas que escupen miel")
		matar_ola(j)
		b._physics_process(0.1)
		b._physics_process(3.1)
		e = b.enemigos[0]
		comprobar(b.ola == b.OLA_REINA and b.restantes() == 1 and e.tipo == "reina", "La reina llega después de completar la quinta ola")
		comprobar(e.vida_max == 350 + cantidad * 110 and j.combo.enemigo_valido(e), "Vida escalada y combos habilitados para la reina")
		await acercar()
		e.position = j.position + Vector2(55, 0)
		await esperar(0.2)
		var antes_combo: int = e.vida
		for tipo in 4:
			j.golpear(1, tipo)
			await esperar(0.24)
		await esperar(0.5)
		comprobar(j.combo.criticos > 0 and e.vida <= antes_combo - 74, "H J K L confirma el crítico sobre la reina")
		var antes_botella: int = e.vida
		j.botellazo(e, 1)
		comprobar(e.vida == antes_botella - j.DANO_BOTELLA, "La botella daña a la reina")
		e.position = j.position
		j.altura = 35
		j.combate.volando = true
		j.combate.tiempo_vuelo = 0.1
		j.combate.direccion_vuelo = 1
		var antes_compazo: int = e.vida
		j.combate._physics_process(0.01)
		comprobar(e.vida < antes_compazo and not j.combate.volando, "Lanzar un compa también impacta en la reina")
		await acercar()
		e.position = j.position - Vector2(80, 0)
		e.mirando = 1
		e._iniciar("boxeo", j.position)
		var vida: int = j.vida
		e._physics_process(0.51)
		comprobar(j.vida == vida - 15, "Primer puño causa daño real")
		await acercar()
		e.position = j.position - Vector2(80, 0)
		vida = j.vida
		e._physics_process(0.36)
		comprobar(j.vida == vida - 15, "Segundo puño tiene su propio contacto")
		await acercar()
		e.position = j.position - Vector2(80, 0)
		j.combate.parada = 0.2
		j.combate.direccion_parada = -1
		vida = j.vida
		e._punos()
		comprobar(j.vida == vida and j.combate.paradas_logradas > 0, "La parada a tiempo bloquea el puño")
		e._iniciar("vuelo", j.position)
		e.position = j.position
		e._physics_process(0.8)
		comprobar(e.vuelo == 180 and not e.puede_recibir_golpe(), "La reina sobrevuela y no recibe golpes a ras del suelo")
		vida = j.vida
		e._physics_process(1.21)
		comprobar(j.vida == vida - 22, "El impacto contra el suelo hace daño")
		await acercar()
		j.altura = 70
		e.position = j.position
		e._iniciar("vuelo", j.position)
		e._physics_process(2.01)
		comprobar(j.vida == 100, "Saltar evita el golpe de suelo")
		j.altura = 0
		e._descansar(0)
		e.position = j.position - Vector2(140, 0)
		e.mirando = 1
		e._iniciar("miel", j.position)
		e._physics_process(0.76)
		comprobar(e.proyectil and not j.en_miel(), "Escupitajo visible: no inmoviliza instantáneamente")
		e._actualizar_miel(0.35)
		comprobar(j.en_miel() and not j.puede_actuar(), "Contacto de miel inmoviliza y bloquea ataques")
		b._reloj += 0.1
		b.sacudir(b.encuentro - 1, -1)
		b.sacudir(b.encuentro, 0)
		comprobar(b.pegados[1].pasos == 0, "Rechaza ronda antigua y dirección inválida")
		get_tree().paused = true
		b.sacudir(b.encuentro, -1)
		get_tree().paused = false
		comprobar(b.pegados[1].pasos == 0, "La pausa bloquea las sacudidas")
		b.sacudir(b.encuentro, -1)
		b._reloj += 0.1
		b.sacudir(b.encuentro, -1)
		comprobar(b.pegados[1].pasos == 1, "Repetir una misma tecla no progresa")
		b.sacudir(b.encuentro, 1)
		b.sacudir(b.encuentro, -1)
		comprobar(b.pegados[1].pasos == 2, "Bloquea pulsaciones imposibles en el mismo instante")
		for i in 8:
			b._reloj += 0.11
			b.sacudir(b.encuentro, -1 if i % 2 == 0 else 1)
		comprobar(not j.en_miel(), "Diez pulsaciones alternadas liberan al jugador")
		b.empapar(j)
		comprobar(not j.en_miel(), "Protección breve impide encadenar inmovilizaciones")
		b.empapar(b.jugador(ids[1]))
		await esperar(0.25)
		pulsaciones.rpc_id(ids[1], b.encuentro)
		b.set_physics_process(true)
		await esperar(2.1)
		b.set_physics_process(false)
		comprobar(not b.pegados.has(ids[1]), "Cliente remoto se libera por RPC propio con diez entradas reales")
		b.empapar(b.jugador(ids[2]))
		b.jugador(ids[2])._perder_vida(100)
		b._physics_process(0.1)
		comprobar(not b.pegados.has(ids[2]), "Caer limpia el estado de miel")
		b.jugador(ids[2]).levantar()
		await esperar(0.2)
		get_tree().paused = true
		var mensaje: String = get_node("/root/Guardado").guardar(main, "user://miel_prueba.cfg")
		var datos: Dictionary = get_node("/root/Guardado").cargar("user://miel_prueba.cfg")
		get_tree().paused = false
		comprobar(not datos.is_empty() and not datos.miel_conseguida and mensaje.begins_with("Partida guardada"), "Guardar durante combate no concede miel")
		e._descansar(0)
		j._dano_ataque = 1
		e.vida = int(e.vida_max * 0.66) + 1
		e.golpeada(1, j)
		comprobar(e.fase == 2 and e.estado == "rugido" and not e.puede_recibir_golpe() and b.restantes() > 1, "Bajo 66% la reina ruge y llama refuerzos")
		e._physics_process(e.DURACION_RUGIDO + 0.1)
		e._descansar(0)
		e.vida = int(e.vida_max * 0.33) + 1
		e.golpeada(1, j)
		comprobar(e.fase == 3 and b.enemigos.any(func(a): return a != e and a.vivo() and a.tipo == "musculosa"), "Bajo 33% entra en furia con una musculosa de escolta")
		e._descansar(0)
		e.mirando = 1
		e._iniciar("miel", j.position + Vector2(300, 0))
		e._physics_process(0.76)
		comprobar(e.bolas.size() == 3, "En furia escupe tres bolas de miel en abanico")
		e.bolas.clear()
		e._descansar(0)
		matar_ola(j)
		b._physics_process(0.1)
		comprobar(b.completada and miel.disponible() and miel.position == b.CENTRO + Vector2(90, 0), "Derrotar a la reina suelta la miel junto al lago")
		comprobar(main.estacion.intentar_entregar(miel, main.estacion.position), "La miel ganada puede entregarse a la olla")
		await esperar(0.3)
		consultar.rpc()
		await esperar(0.4)
		comprobar(informes.size() == cantidad - 1 and informes.values().all(func(d): return d[0] and d[1] == b.OLA_REINA and d[2] == 0), "Todos los peers reciben victoria, ola y ausencia de atrapados")
		get_tree().paused = true
		get_node("/root/Guardado").guardar(main, "user://miel_prueba.cfg")
		datos = get_node("/root/Guardado").cargar("user://miel_prueba.cfg")
		get_tree().paused = false
		b.completada = false
		get_node("/root/Guardado").restaurar_mundo(main, datos)
		comprobar(b.completada, "Guardar y cargar conserva la miel ganada")
		DirAccess.remove_absolute("user://miel_prueba.cfg")
		b.completada = false
		b._equipo = ids.duplicate()
		b.iniciar_ola(1)
		b.empapar(j)
		abandonar.rpc_id(ids[2])
		await esperar(0.6)
		b._physics_process(0.1)
		comprobar(not b.activa() and b.restantes() == 0 and b.pegados.is_empty(), "Desconexión cancela oleadas y libera a todos sin premio")

	func matar_ola(j: Node2D) -> void:
		j._dano_ataque = 10000
		for e in b.enemigos:
			for i in 8:
				if e.estado == "fusion":
					e._physics_process(1.9)
				if e.vivo():
					e.golpeada(1, j)

	func acercar() -> void:
		for i in ids.size():
			var j: Node2D = b.jugador(ids[i])
			j.vida = 100
			j.caido = false
			j.aturdimiento = 0
			j._reaparecer.rpc(b.CENTRO + Vector2((i - (ids.size() - 1) / 2.0) * 70, -35 * (i % 2)))
		await esperar(0.2)

	@rpc("any_peer", "call_remote", "reliable")
	func preparado() -> void:
		preparados[multiplayer.get_remote_sender_id()] = true

	@rpc("authority", "call_remote", "reliable")
	func pulsaciones(ronda: int) -> void:
		for i in 10:
			var accion := "izquierda" if i % 2 == 0 else "derecha"
			Input.action_press(accion)
			await get_tree().physics_frame
			await get_tree().physics_frame
			Input.action_release(accion)
			await esperar(0.12)

	@rpc("authority", "call_remote", "reliable")
	func consultar() -> void:
		informar.rpc_id(1, [b.completada, b.ola, b.pegados.size()])

	@rpc("any_peer", "call_remote", "reliable")
	func informar(datos: Array) -> void:
		informes[multiplayer.get_remote_sender_id()] = datos

	@rpc("authority", "call_remote", "reliable")
	func abandonar() -> void:
		multiplayer.multiplayer_peer.close()
		get_tree().quit(0)

	@rpc("authority", "call_local", "reliable")
	func terminar(errores: int) -> void:
		await esperar(0.2)
		get_tree().quit(1 if errores > 0 else 0)
