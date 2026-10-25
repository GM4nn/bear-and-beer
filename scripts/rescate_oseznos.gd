extends Node2D
## Misión previa a la fogata. El servidor decide salto, equilibrio, miedo y rescate.
const SITIO := Vector2(7020, 650)
## Donde se sientan los oseznos: sobre la rama del árbol alto (arbol_rescate.png).
const RAMA := Vector2(-122, -330)
const ATAJAR := Vector2(-140, 20)
const RADIO := 65.0
const DURACION_SALTO := 1.15
const TIEMPO_CALMA := 8.0
const DANO_RASGUNO := 12
const ARTE := preload("res://scripts/arte_objetos.gd")
var rescatados := 0
var cebo := false
var estado := "esperando"
var participantes: Array = []
var encuentro := 0
var miedo := 0.15
var equilibrio := 0.0
var calma := 0.0
var tiempo := 0.0
var origen_salto := Vector2.ZERO
var destino_salto := Vector2.ZERO
var mensaje := "Traigan miel y formen una torre de 2 o 3 compas"
var _entradas := {}
var _reloj := 0.0
var _envio := 0.0
var _crias: Array[AnimatedSprite2D] = []
var _titulo: Label
var _panel: CanvasLayer
var _caja: VBoxContainer
var _indicacion: Label
var _miedo: ProgressBar
var _calma: ProgressBar
var _balance: ProgressBar

func _ready() -> void:
	position = SITIO
	add_to_group("rescate_oseznos")
	process_physics_priority = 15
	var config := SceneReplicationConfig.new()
	for propiedad in ["rescatados", "cebo", "estado", "participantes", "encuentro", "miedo", "equilibrio", "calma", "tiempo", "origen_salto", "destino_salto", "mensaje"]:
		var ruta := NodePath(".:" + propiedad)
		config.add_property(ruta)
		config.property_set_replication_mode(ruta, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sincronizador"
	sync.replication_config = config
	sync.replication_interval = 0.05
	add_child(sync)
	for i in 2:
		var cria := ARTE.animado({"quieto": "res://arte/zona1/objetos/quieto", "llorar": "res://arte/zona1/objetos/llorar",
			"salto": "res://arte/zona1/objetos/cria_salto", "asustado": "res://arte/zona1/objetos/cria_asustado",
			"rasguno": "res://arte/zona1/objetos/cria_rasguno", "olfatear": "res://arte/zona1/objetos/cria_olfatear"}, 1.5, 9)
		cria.z_index = 12
		cria.modulate = Color.WHITE if i == 0 else Color(0.88, 0.94, 1)
		add_child(cria)
		_crias.append(cria)
	_titulo = Label.new()
	_titulo.position = RAMA + Vector2(-130, -100)
	_titulo.size.x = 320
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 16)
	_titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_titulo.add_theme_constant_override("outline_size", 5)
	_titulo.z_index = 13
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)
	_crear_ui()
	_crear_arbol.call_deferred()

func _crear_arbol() -> void:
	var arbol := preload("res://escenas/arbol.tscn").instantiate()
	arbol.name = "ArbolRescate"
	arbol.position = SITIO
	get_parent().add_child(arbol)
	# Árbol alto propio (más alto que una torre de tres) con la rama de los oseznos.
	get_parent().get_parent()._vestir(arbol, "arbol_rescate", 1.0)
	# La rama y los oseznos quedan por delante del follaje reutilizado.
	z_index = 2

func _crear_ui() -> void:
	_panel = CanvasLayer.new()
	_panel.layer = 6
	add_child(_panel)
	_caja = VBoxContainer.new()
	_caja.position = Vector2(410, 430)
	_caja.custom_minimum_size.x = 320
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_caja)
	_indicacion = Label.new()
	_indicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_indicacion.custom_minimum_size.x = 320
	_indicacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicacion.add_theme_font_size_override("font_size", 17)
	_indicacion.add_theme_color_override("font_outline_color", Color.BLACK)
	_indicacion.add_theme_constant_override("outline_size", 5)
	_caja.add_child(_indicacion)
	_balance = _barra("Equilibrio · mantengan el centro", Color("ffe285"))
	var centro := ColorRect.new()
	centro.color = Color.WHITE
	centro.position = Vector2(159, 0)
	centro.size = Vector2(2, 12)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balance.add_child(centro)
	_miedo = _barra("Miedo del osezno", Color("e35b4a"))
	_calma = _barra("Confianza · rescate", Color("6ad87b"))
	_caja.hide()

func _barra(texto: String, color: Color) -> ProgressBar:
	var titulo := Label.new()
	titulo.text = texto
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 13)
	titulo.add_theme_constant_override("outline_size", 4)
	titulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_caja.add_child(titulo)
	var barra := ProgressBar.new()
	barra.max_value = 1.0
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(320, 12)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("20190e")
	fondo.border_color = Color("ffe3a1")
	fondo.set_border_width_all(1)
	barra.add_theme_stylebox_override("background", fondo)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	barra.add_theme_stylebox_override("fill", relleno)
	_caja.add_child(barra)
	return barra

func _partida() -> Node:
	return get_tree().get_first_node_in_group("partida")

func _jugador(id: int) -> Node2D:
	return get_parent().get_node_or_null("Jugadores/%d" % id)

func activo() -> bool:
	return estado in ["salto", "equilibrio", "bajando"]

func contiene(id: int) -> bool:
	return activo() and id in participantes

func listo() -> bool:
	return rescatados >= 2

func lugar() -> Vector2:
	return global_position + ATAJAR

func rama(indice: int) -> Vector2:
	return global_position + RAMA + Vector2(indice * 65, 0)

func interactuar(j: Node2D) -> bool:
	if not multiplayer.is_server() or get_tree().paused or listo() or _partida().finalizada or j.position.distance_to(lugar()) > RADIO:
		return false
	if estado != "esperando":
		return contiene(j.name.to_int())
	var pieza: Node2D = j._pieza_cargada()
	if pieza != null and pieza.tipo == "miel" and j.apoyo_id == 0:
		cebo = true
		pieza.soltar(lugar() + Vector2(-80, 20))
		mensaje = "Miel preparada · formen una torre y pulsen E para atajar"
		return true
	var torre: Node = _partida().torre
	var base: Node2D = torre._base(j)
	if base == null:
		return false
	var compas: Array = torre._cadena(base)
	if compas.size() < 2:
		return false
	if not cebo:
		j._avisar_bebida.rpc("Primero acerquen miel al árbol y ofrézcanla con E")
		return true
	if compas.size() > 3 or base.altura > 1 or not compas.all(func(c): return torre._equilibrado(c)):
		return true
	participantes = compas.map(func(c): return c.name.to_int())
	encuentro += 1
	tiempo = 0.0
	equilibrio = 0.0
	miedo = 0.15
	calma = 0.0
	_entradas.clear()
	for c in compas:
		c._cancelar_golpes()
		c._anim_golpe = 0.0
		c.manteniendo = false
		_entradas[c.name.to_int()] = {"eje": 0.0, "cuando": -10.0}
	origen_salto = rama(rescatados)
	destino_salto = _manos(compas.back())
	estado = "salto"
	mensaje = "¡Ahí viene! Atájenlo sin asustarlo"
	return true

func _manos(j: Node2D) -> Vector2:
	return j.position - Vector2(0, j.altura + 102)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func equilibrar(numero: int, eje: float) -> void:
	var id := multiplayer.get_remote_sender_id()
	if id == 0:
		id = multiplayer.get_unique_id()
	if not multiplayer.is_server() or get_tree().paused or _partida().finalizada or numero != encuentro or not contiene(id) or not is_finite(eje) or absf(eje) > 1.0:
		return
	_entradas[id] = {"eje": eje, "cuando": _reloj}

func cancelar() -> void:
	if multiplayer.is_server() and activo():
		_fallar(false)

func _fallar(rasguno: bool) -> void:
	var ultimo := _jugador(participantes.back()) if not participantes.is_empty() else null
	origen_salto = posicion_cria()
	destino_salto = rama(rescatados)
	estado = "regreso"
	tiempo = 0.0
	mensaje = "¡Se asustó! Volvió a la rama; pueden intentarlo otra vez" if rasguno else "Se interrumpió el rescate. El osezno vuelve a la rama"
	participantes.clear()
	_entradas.clear()
	if rasguno and ultimo != null:
		ultimo.recibir_golpe(-ultimo.mirando, DANO_RASGUNO, 0.5)

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		return
	_reloj += delta
	if _partida().finalizada:
		cancelar()
	if activo():
		var base: Node2D = _jugador(participantes[0])
		if base == null or base.position.distance_to(lugar()) > RADIO or base.altura > 1:
			_fallar(false)
			return
		var cadena: Array = _partida().torre._cadena(base)
		if cadena.map(func(c): return c.name.to_int()) != participantes or not cadena.all(func(c): return puede_sostener(c)):
			_fallar(false)
			return
	tiempo += delta
	match estado:
		"salto":
			if tiempo >= DURACION_SALTO:
				estado = "equilibrio"
				tiempo = 0.0
		"equilibrio":
			var suma := 0.0
			var responden := 0
			var deseado := -signf(equilibrio) if absf(equilibrio) > 0.1 else 0.0
			for id in participantes:
				var dato: Dictionary = _entradas[id]
				var eje: float = dato.eje if _reloj - dato.cuando < 0.3 else 0.0
				suma += eje
				if _reloj - dato.cuando < 0.3 and (absf(eje) < 0.2 if deseado == 0 else eje * deseado > 0.4):
					responden += 1
			var juntos := responden == participantes.size()
			var deriva := 0.30 * sin(tiempo * 1.45) + 0.18 * cos(tiempo * 2.35) + 0.16
			equilibrio = clampf(equilibrio + delta * (deriva + suma / participantes.size() * (0.9 if juntos else 0.25)), -1, 1)
			if absf(equilibrio) < 0.35 and juntos:
				calma = minf(calma + delta / TIEMPO_CALMA, 1)
				miedo = maxf(miedo - delta * 0.1, 0)
			else:
				miedo = minf(miedo + delta * (0.20 if absf(equilibrio) > 0.65 else 0.08), 1)
			if miedo >= 1 or tiempo >= 25:
				miedo = 1
				_fallar(true)
			elif calma >= 1:
				origen_salto = posicion_cria()
				destino_salto = get_tree().get_first_node_in_group("estacion").global_position + Vector2(98 + rescatados * 50, rescatados * 6)
				estado = "bajando"
				tiempo = 0
				mensaje = "¡Lo tranquilizaron! Bajando al osezno"
		"bajando":
			if tiempo >= 2.0:
				rescatados += 1
				participantes.clear()
				_entradas.clear()
				estado = "esperando"
				mensaje = "¡Los dos están a salvo! Ahora preparen la fogata" if listo() else "Uno a salvo. Atajen al segundo con la torre"
		"regreso":
			if tiempo >= DURACION_SALTO:
				estado = "esperando"

func puede_sostener(j: Node2D) -> bool:
	return j != null and not j.caido and j.vida > 0 and j.bebiendo <= 0 and j.dormido <= 0 and j.vomitando <= 0 and j.nausea <= 0 and j.aturdimiento <= 0 and j.rodando <= 0 and not j.combate.volando and j._sujeto <= 0 and j._pieza_cargada() == null

func posicion_cria() -> Vector2:
	if estado in ["salto", "regreso", "bajando"]:
		var t := clampf(tiempo / (2.0 if estado == "bajando" else DURACION_SALTO), 0, 1)
		return origen_salto.lerp(destino_salto, t) - Vector2(0, sin(t * PI) * 55)
	if estado == "equilibrio" and not participantes.is_empty():
		var j := _jugador(participantes.back())
		if j != null:
			return _manos(j)
	return rama(rescatados)

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_caja.hide()
		return
	var yo := multiplayer.get_unique_id()
	var jugador := _jugador(yo)
	var jugando := contiene(yo)
	_caja.visible = jugando
	_caja.position = get_viewport().get_visible_rect().size - Vector2(340, 210)
	if jugador != null:
		var pantalla := get_viewport().get_canvas_transform() * jugador.global_position
		if pantalla.x > get_viewport().get_visible_rect().size.x * 0.55:
			_caja.position.x = 20 # Al final del mapa la cámara se detiene: no tapar la torre.
	_balance.value = (equilibrio + 1) * 0.5
	_miedo.value = miedo
	_calma.value = calma
	var orden := "SUELTEN LAS TECLAS" if absf(equilibrio) < 0.1 else ("← " + Controles.tecla("izquierda") if equilibrio > 0 else Controles.tecla("derecha") + " →")
	_indicacion.text = "Todos: " + orden if estado == "equilibrio" else mensaje
	_envio += delta
	if jugando and jugador != null and _envio >= 0.06:
		_envio = 0
		var eje := Input.get_axis("izquierda", "derecha")
		if not jugador._bot.is_empty():
			eje = -signf(equilibrio) if absf(equilibrio) > 0.1 else 0
		if multiplayer.is_server():
			equilibrar(encuentro, eje)
		else:
			equilibrar.rpc_id(1, encuentro, eje)
	_titulo.visible = not listo()
	_titulo.text = "OSEZNOS · %d/2 A SALVO" % rescatados
	var vaiven := _tambalear_torre()
	for i in 2:
		_crias[i].visible = i >= rescatados
		_crias[i].global_position = posicion_cria() if i == rescatados else rama(i)
		var anim := "quieto"
		if i == rescatados:
			if estado == "equilibrio":
				_crias[i].global_position += vaiven
				anim = "llorar" if miedo > 0.65 else "asustado"
			elif estado == "regreso" and tiempo < 0.45 and mensaje.begins_with("¡Se asustó"):
				# Antes de saltar de regreso, rasguña al de hasta arriba.
				anim = "rasguno"
				_crias[i].global_position = origen_salto
			elif estado in ["salto", "regreso", "bajando"]:
				anim = "salto"
			elif estado == "esperando" and cebo:
				anim = "olfatear"
		_crias[i].rotation = equilibrio * 0.12 if estado == "equilibrio" and i == rescatados else 0.0
		if _crias[i].animation != anim:
			_crias[i].play(anim)
	queue_redraw()


## La torre se tambalea con el equilibrio: cada nivel se inclina más. Devuelve
## cuánto se corren las manos del de hasta arriba (el osezno va encima).
var _inclinados: Array = []
func _tambalear_torre() -> Vector2:
	for j in _inclinados:
		if is_instance_valid(j):
			j.visual.rotation = 0.0
			j.visual.position.x = 0.0
	_inclinados.clear()
	if estado != "equilibrio" or participantes.is_empty():
		return Vector2.ZERO
	var t := Time.get_ticks_msec() / 1000.0
	var corrimiento := Vector2.ZERO
	for nivel in participantes.size():
		var j := _jugador(participantes[nivel])
		if j == null:
			continue
		var giro := equilibrio * 0.07 * (nivel + 1) + sin(t * 7.0 + nivel) * 0.012 * (nivel + 1)
		j.visual.rotation = giro
		j.visual.position.x = equilibrio * 10.0 * nivel
		_inclinados.append(j)
		if nivel == participantes.size() - 1:
			var alto: float = j.altura + 102.0
			corrimiento = Vector2(equilibrio * 10.0 * nivel + sin(giro) * alto, (1.0 - cos(giro)) * alto)
	return corrimiento

func _draw() -> void:
	# La rama ya viene dibujada en el árbol alto.
	if not listo():
		draw_arc(ATAJAR, RADIO * 0.65, 0, TAU, 30, Color("ffe285"), 2)
		if cebo:
			draw_circle(ATAJAR + Vector2(-35, 0), 6, Color("e8a824"))
