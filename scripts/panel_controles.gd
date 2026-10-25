extends CanvasLayer
## Editor compartido por menú y pausa. Solo modifica el teclado local.
var esperando := ""
var aviso: Label
var botones := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 35
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.03, 0.02, 0.97)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.theme = TemaUI.tema()
	add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 90)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	fondo.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "CONTROLES DE TECLADO"
	titulo.add_theme_font_size_override("font_size", 24)
	columna.add_child(titulo)
	aviso = Label.new()
	aviso.text = "Elige una acción y pulsa su nueva tecla. Esc cancela. Se guarda automáticamente."
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(aviso)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lista)
	for accion in Controles.NOMBRES:
		var fila := HBoxContainer.new()
		lista.add_child(fila)
		var nombre := Label.new()
		nombre.text = Controles.NOMBRES[accion]
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(220, 36)
		boton.pressed.connect(func():
			esperando = accion
			aviso.text = "Pulsa la tecla para: " + Controles.NOMBRES[accion])
		fila.add_child(boton)
		botones[accion] = boton
	var nota := Label.new()
	nota.text = "Combo: puño derecho → izquierdo → cabezazo → patada.\nInteractuar: mantener para revivir; saltar + interactuar para hombros.\nFogata: clic sostenido y arrastrar. El mando conserva sus controles."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(nota)
	var restaurar := Button.new()
	restaurar.text = "Restaurar controles originales"
	restaurar.pressed.connect(func():
		esperando = ""
		Controles.restaurar()
		aviso.text = "Controles originales restaurados.")
	columna.add_child(restaurar)
	var volver := Button.new()
	volver.text = "Volver"
	volver.pressed.connect(queue_free)
	columna.add_child(volver)
	Controles.cambiaron.connect(_actualizar)
	_actualizar()
	botones.values()[0].grab_focus()

func _actualizar() -> void:
	for accion in botones:
		botones[accion].text = Controles.tecla(accion)

func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if evento.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if esperando.is_empty():
			queue_free()
		else:
			esperando = ""
			aviso.text = "Cambio cancelado."
	elif not esperando.is_empty():
		get_viewport().set_input_as_handled()
		var error := Controles.asignar(esperando, evento.physical_keycode if evento.physical_keycode else evento.keycode)
		aviso.text = error if not error.is_empty() else "Tecla guardada."
		if error.is_empty():
			esperando = ""
