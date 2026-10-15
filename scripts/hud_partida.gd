extends Control
## Indicadores por jugador y resultados compartidos de la Zona 1.

signal volver_sala
signal salir

var _tarjetas: Dictionary = {}
var _fila: HBoxContainer
var _resultado: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fila = HBoxContainer.new()
	_fila.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_fila.offset_left = 16
	_fila.offset_right = 336
	_fila.offset_top = 132
	_fila.offset_bottom = 232
	_fila.add_theme_constant_override("separation", 8)
	_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fila)


func _process(_delta: float) -> void:
	if not visible:
		return
	var ids := []
	for j in get_tree().get_nodes_in_group("jugadores"):
		ids.append(j.name)
		if not _tarjetas.has(j.name):
			_crear_tarjeta(j)
		var tarjeta: Dictionary = _tarjetas[j.name]
		tarjeta.vida.value = j.vida
		tarjeta.borracho.value = j.borrachera
		tarjeta.detalle.text = "Vida %d/100 · Chelas %d/%d · Botellas vacías %d\nBorrachera %d/100 · %s" % [j.vida, j.cervezas, j.MAX_CERVEZAS, j.botellas, j.borrachera, j.texto_estado()]
		if j.is_multiplayer_authority() and j.botellas > 0 and j.aviso_bebida().is_empty():
			tarjeta.detalle.text += " · F/LB: lanzar botella"
		if j.is_multiplayer_authority() and not j.aviso_bebida().is_empty():
			tarjeta.detalle.text += "\n" + j.aviso_bebida()
		elif j.is_multiplayer_authority() and j.cervezas == 0 and j.apoyo_id == 0 and j._torre().encima(j) == null:
			tarjeta.detalle.text += "\nE/Y: recoger chelas · Q/RB: beber"
		if j.is_multiplayer_authority() and j.puede_actuar():
			if j.apoyo_id == 0 and j.altura > 12:
				tarjeta.detalle.text += " · E/Y sobre un compa: subir a hombros (máx. 3)"
			elif j.companero_caido() and j.apoyo_id == 0:
				tarjeta.detalle.text += " · Mantén E/Y para levantar"
			elif j._pieza_cargada():
				tarjeta.detalle.text += " · E/Y: soltar pieza"
	for id in _tarjetas.keys():
		if id not in ids:
			_tarjetas[id].panel.queue_free()
			_tarjetas.erase(id)
	# Una o dos tarjetas no necesitan tapar todo el paisaje de lado a lado.
	_fila.size = Vector2(minf(get_viewport_rect().size.x - 32,
		ids.size() * 320 + maxi(ids.size() - 1, 0) * 8), 0)
	_fila.position.y = 132 if get_parent().get_node("Jefe").visible else 76


func _crear_tarjeta(j: Node) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.04, 0.07, 0.05, 0.92)
	estilo.border_color = j.COLORES[j.color_indice]
	estilo.set_border_width_all(2)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", estilo)
	_fila.add_child(panel)
	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(columna)
	var titulo := _texto(j.nombre + (" (tú)" if j.is_multiplayer_authority() else ""), 15)
	columna.add_child(titulo)
	var vida := _barra(Color("72c779"))
	var borracho := _barra(Color("e8b743"))
	columna.add_child(vida)
	columna.add_child(borracho)
	var detalle := _texto("", 13)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(detalle)
	_tarjetas[j.name] = {"panel": panel, "vida": vida, "borracho": borracho, "detalle": detalle}


func _barra(color: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.custom_minimum_size.y = 8
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	barra.add_theme_stylebox_override("fill", estilo)
	return barra


func _texto(texto: String, tamano := 16) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta


func limpiar() -> void:
	if is_instance_valid(_resultado):
		remove_child(_resultado)
		_resultado.queue_free()
		_resultado = null
	for tarjeta in _tarjetas.values():
		_fila.remove_child(tarjeta.panel)
		tarjeta.panel.queue_free()
	_tarjetas.clear()


func mostrar_resultados(victoria: bool, filas: Array) -> void:
	_resultado = ColorRect.new()
	_resultado.color = Color(0.025, 0.045, 0.03, 0.97)
	_resultado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_resultado)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 40)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	_resultado.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	margen.add_child(columna)
	columna.add_child(_texto("¡RECUPERARON LAS CHELAS!" if victoria else "SE NOS CAYÓ TODO EL EQUIPO", 30))
	columna.add_child(_texto("Mamá Osa cayó. Ahora sí: a repartir culpas." if victoria else "Nadie quedó de pie para levantar a los demás. Vuelvan a la sala para reintentar.", 16))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(scroll)
	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 18)
	scroll.add_child(contenido)
	var tabla := GridContainer.new()
	tabla.columns = 8
	tabla.add_theme_constant_override("h_separation", 16)
	tabla.add_theme_constant_override("v_separation", 14)
	contenido.add_child(tabla)
	for titulo in ["Compa", "Fuego amigo\nrecibido", "Vuelo\n(píxeles)", "Chelas\nbebidas", "Amigos\nvomitados", "Siestas\nen pelea", "Daño\nal jefe", "Rescates"]:
		var encabezado := _texto(titulo, 14)
		encabezado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabla.add_child(encabezado)
	for fila in filas:
		for valor in [fila.nombre, str(int(fila.fuego_amigo)), str(roundi(fila.vuelo)),
			str(int(fila.cervezas)), str(int(fila.vomitos)), str(int(fila.dormidas)), str(int(fila.dano_jefe)), str(int(fila.rescates))]:
			tabla.add_child(_texto(valor, 16))
	contenido.add_child(_texto("LA PANTALLA DE HUMILLACIÓN", 22))
	var premios := {"fuego_amigo": "Costal de golpes", "vuelo": "El astronauta",
		"cervezas": "La sed peligrosa", "vomitos": "El aspersor", "dormidas": "La bella durmiente", "dano_jefe": "El que sí trabajó"}
	for clave in premios:
		var mejor := 0.0
		var ganadores: Array[String] = []
		for fila in filas:
			var valor: float = fila[clave]
			if valor > mejor:
				mejor = valor
				ganadores = [fila.nombre]
			elif valor == mejor and valor > 0:
				ganadores.append(fila.nombre)
		contenido.add_child(_texto("%s: %s" % [premios[clave], ", ".join(ganadores) if mejor > 0 else "Nadie… por esta vez"], 16))
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 20)
	columna.add_child(botones)
	var volver := Button.new()
	volver.text = "Volver juntos a la sala" if multiplayer.is_server() else "El anfitrión puede volver a la sala"
	volver.disabled = not multiplayer.is_server()
	volver.pressed.connect(func(): volver_sala.emit())
	botones.add_child(volver)
	var salir_boton := Button.new()
	salir_boton.text = "Salir al menú"
	salir_boton.pressed.connect(func(): salir.emit())
	botones.add_child(salir_boton)
	if multiplayer.is_server():
		volver.grab_focus()
	else:
		salir_boton.grab_focus()
