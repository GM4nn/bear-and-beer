extends CanvasLayer
## Interfaz que sigue respondiendo mientras el mundo está detenido.

signal resumir
signal terminar
signal volver_lobby
signal volumen_cambiado(valor: float)
signal pantalla_cambiada(activa: bool)

var menu: VBoxContainer
var opciones: VBoxContainer
var boton_resumir: Button
var boton_lobby: Button
var pantalla: CheckButton
var volumen: HSlider
var detalle: Label
var subtitulo: Label
var mision: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var fondo := ColorRect.new()
	fondo.color = Color(0.015, 0.035, 0.03, 0.78)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.theme = TemaUI.tema()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	# Letrero de madera del tema (scripts/tema_ui.gd).
	panel.add_theme_stylebox_override("panel", TemaUI.panel_letrero())
	centro.add_child(panel)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 14)
	panel.add_child(contenido)
	var titulo := _texto(contenido, "PAUSA", 32)
	titulo.add_theme_color_override("font_color", Color("ffe3a1"))
	titulo.add_theme_font_override("font", TemaUI.fuente("bold"))
	subtitulo = _texto(contenido, "", 16)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	contenido.add_child(menu)
	# La misión actual: en partida solo se anuncia un ratito, aquí se puede releer.
	var titulo_mision := _texto(menu, "MISIÓN", 18)
	titulo_mision.add_theme_font_override("font", TemaUI.fuente("bold"))
	titulo_mision.add_theme_color_override("font_color", Color("ffd36b"))
	mision = _texto(menu, "", 14)
	mision.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mision.custom_minimum_size.x = 380
	boton_resumir = _boton(menu, "Resumir", func(): resumir.emit())
	_boton(menu, "Opciones", abrir_opciones)
	_boton(menu, "Terminar partida", func(): terminar.emit())
	boton_lobby = _boton(menu, "Volver al lobby", func(): volver_lobby.emit())
	detalle = _texto(menu, "", 14)
	opciones = VBoxContainer.new()
	opciones.add_theme_constant_override("separation", 14)
	contenido.add_child(opciones)
	_texto(opciones, "Opciones", 22)
	pantalla = CheckButton.new()
	pantalla.text = "Pantalla completa"
	opciones.add_child(pantalla)
	pantalla.toggled.connect(func(activa): pantalla_cambiada.emit(activa))
	_texto(opciones, "Volumen general", 16)
	volumen = HSlider.new()
	volumen.max_value = 1.0
	volumen.step = 0.05
	volumen.custom_minimum_size.y = 32
	opciones.add_child(volumen)
	volumen.value_changed.connect(func(valor): volumen_cambiado.emit(valor))
	Audio.agregar_deslizadores(opciones, volumen.get_index() + 1)
	var titulo_controles := _texto(opciones, "Controles", 18)
	titulo_controles.add_theme_font_override("font", TemaUI.fuente("bold"))
	titulo_controles.add_theme_color_override("font_color", Color("ffd36b"))
	_texto(opciones, TemaUI.CONTROLES, 13)
	_boton(opciones, "Volver", volver)
	_texto(contenido, "↑ ↓ Elegir   ·   Enter Aceptar   ·   Esc Volver", 14)
	opciones.hide()
	hide()


func _texto(padre: Node, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 44
	boton.add_theme_font_size_override("font_size", 20)
	padre.add_child(boton)
	boton.pressed.connect(accion)
	return boton


func abrir(anfitrion: bool, nombre: String) -> void:
	subtitulo.text = "Partida pausada por %s" % nombre
	boton_lobby.disabled = not anfitrion
	detalle.text = ("Terminar cierra la sesión para todos.\nVolver al lobby conserva el grupo." if anfitrion
		else "Terminar te lleva al menú principal.\nEl anfitrión puede volver al lobby con el grupo.")
	show()
	volver()


func abrir_opciones() -> void:
	menu.hide()
	opciones.show()
	pantalla.set_pressed_no_signal(DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	volumen.set_value_no_signal(Audio.volumen("general"))
	pantalla.grab_focus()


func volver() -> void:
	opciones.hide()
	menu.show()
	boton_resumir.grab_focus()


func cerrar() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	if foco != null and is_ancestor_of(foco):
		foco.release_focus()
	hide()
