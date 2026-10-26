extends Node
## Escena principal: cambia entre menú, sala de espera y el bosque.

const JUGADOR := preload("res://escenas/jugador.tscn")
const BOSQUE := preload("res://escenas/bosque.tscn")

var juego: Node2D
var jugadores: Node2D
var inicio: Marker2D
var aparecedor: MultiplayerSpawner
var estacion: Node2D
var jefe: Node2D
var _auto := false
var _regresando_sala := false
var _pids_bots: Array[int] = []
var _fondo_menu: TextureRect
var _panel_mision: PanelContainer
var _dato_mision: Label
var _flecha: Control
## Texto de la misión sin números: si cambia, la misión se anuncia otra vez.
var _clave_mision := ""
var _anuncio: Tween
var _sin_numeros := RegEx.create_from_string("[0-9]+")
const DURACION_ANUNCIO := 5.0
## Letrero de madera -> pantalla que enmarca.
var _letreros: Dictionary = {}
const MARGEN_LETRERO := Vector2(70, 80)
var _pausado_por := 0
var pausa: CanvasLayer
var editor_controles: CanvasLayer
var _version: Label
var _continuar: Button
var _cargar_guardado := false
var _salidas_listas := {}
var _ronda_salida := 0
var _intervalos_replica := {}

## Para probar solo: al crear partida se unen bots. El modo de torre acompaña
## al anfitrión; al desactivar probar_torre_con_bots vuelven a hacer la misión.
@export var bot_de_ayuda := true
## Cuántos bots de ayuda se unen (contigo, 2 bots = partida de 3).
@export_range(1, 5) var cantidad_bots := 2
## Modo de prueba: se montan sobre el anfitrión y acompañan sus puñetazos.
@export var probar_torre_con_bots := true

@onready var ayuda: Label = $UI/Ayuda
@onready var mision: Label = $UI/Mision
@onready var barra_jefe: Control = $UI/Jefe
@onready var aviso: Label = $UI/Aviso
@onready var campo_nombre: LineEdit = $UI/Menu/Nombre
@onready var campo_ip: LineEdit = $UI/Unirse/IP
@onready var hud: Control = $UI/HUD
@onready var pantallas := {
	"menu": $UI/Menu, "unirse": $UI/Unirse, "opciones": $UI/Opciones, "sala": $UI/Sala,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_decorar_ui()
	_usar_bosque($Juego)
	pausa = preload("res://scripts/menu_pausa.gd").new()
	pausa.name = "Pausa"
	add_child(pausa)
	pausa.controles.connect(abrir_controles)
	pausa.guardar.connect(_guardar_partida)
	pausa.resumir.connect(_pedir_pausa.bind(false))
	pausa.terminar.connect(_volver_al_menu.bind(""))
	pausa.volver_lobby.connect(_preparar_sala.bind(true))
	pausa.volumen_cambiado.connect(_volumen)
	pausa.pantalla_cambiada.connect(_pantalla_completa)
	hud.volver_sala.connect(_preparar_sala)
	hud.salir.connect(_volver_al_menu.bind(""))

	$UI/Menu/Crear.pressed.connect(_crear_partida)
	$UI/Menu/Unirse.pressed.connect(_mostrar.bind("unirse"))
	$UI/Menu/Opciones.pressed.connect(_mostrar.bind("opciones"))
	$UI/Menu/Salir.pressed.connect(get_tree().quit)
	$UI/Unirse/Conectar.pressed.connect(_unirse)
	$UI/Unirse/Volver.pressed.connect(_volver_al_menu.bind(""))
	$UI/Opciones/PantallaCompleta.toggled.connect(_pantalla_completa)
	$UI/Opciones/Volumen.value_changed.connect(_volumen)
	$UI/Opciones/Volver.pressed.connect(_mostrar.bind("menu"))
	$UI/Sala/Salir.pressed.connect(_volver_al_menu.bind(""))

	multiplayer.connected_to_server.connect(_mostrar.bind("sala"))
	multiplayer.connection_failed.connect(_volver_al_menu.bind("No se pudo conectar."))
	multiplayer.server_disconnected.connect(_volver_al_menu.bind("El anfitrión salió al menú. Pídele que cree otra partida."))
	multiplayer.peer_disconnected.connect(_salio_jugador)
	Red.partida_iniciada.connect(_empezar_juego)
	Red.jugadores_cambiaron.connect(_auto_listo)

	_mostrar("menu")

	# Atajos para probar: -- --host  /  -- --join=127.0.0.1
	# --auto marca "listo" solo (y el anfitrión empieza al haber 2); --bot juega solo.
	var args := OS.get_cmdline_user_args()
	_auto = "--auto" in args
	for arg in args:
		if arg.begins_with("--nombre="):
			campo_nombre.text = arg.get_slice("=", 1)
	for arg in args:
		if arg == "--host":
			_crear_partida()
		elif arg.begins_with("--join"):
			if "=" in arg:
				campo_ip.text = arg.get_slice("=", 1)
			_unirse()


func _input(event: InputEvent) -> void:
	if is_instance_valid(editor_controles):
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if juego.visible and not juego.get_node("Partida").finalizada:
		get_viewport().set_input_as_handled()
		if pausa.visible and pausa.opciones.visible:
			pausa.volver()
		else:
			_pedir_pausa(not get_tree().paused)
	elif $UI/Opciones.visible:
		get_viewport().set_input_as_handled()
		_mostrar("menu")


func _pedir_pausa(activa: bool) -> void:
	if multiplayer.is_server():
		_cambiar_pausa(activa, multiplayer.get_unique_id())
	else:
		_solicitar_pausa.rpc_id(1, activa)


@rpc("any_peer", "call_remote", "reliable")
func _solicitar_pausa(activa: bool) -> void:
	if multiplayer.is_server():
		_cambiar_pausa(activa, multiplayer.get_remote_sender_id())


func _cambiar_pausa(activa: bool, id: int) -> void:
	if not Red.jugadores.has(id) or not juego.visible or _regresando_sala \
			or juego.get_node("Partida").finalizada or activa == get_tree().paused:
		return
	_aplicar_pausa.rpc(id if activa else 0)


@rpc("authority", "call_local", "reliable")
func _aplicar_pausa(id: int) -> void:
	_pausado_por = id
	get_tree().paused = id != 0
	# No guardar pulsaciones de combate realizadas dentro del menú.
	for accion in InputMap.get_actions():
		if not accion.begins_with("ui_"):
			Input.action_release(accion)
	if id != 0:
		for jugador in jugadores.get_children():
			jugador.cancelar_entrada_pausa()
		pausa.mision.text = mision.text
		pausa.abrir(multiplayer.is_server(), str(Red.jugadores.get(id, {}).get("nombre", "un compa")))
	else:
		pausa.cerrar()


func _process(_delta: float) -> void:
	_acomodar_letreros()
	barra_jefe.visible = juego.visible and jefe.activa
	if barra_jefe.visible:
		$UI/Jefe/Texto.text = jefe.nombre_y_fase()
		$UI/Jefe/Barra.size.x = $UI/Jefe/Fondo.size.x * jefe.vida / jefe.vida_max
	_dato_mision.visible = juego.visible
	_flecha.activa = false
	if juego.visible:
		mision.text = Controles.indicaciones(jefe.texto() if jefe.activa else estacion.texto_mision())
		var clave := _sin_numeros.sub(mision.text, "", true)
		if clave != _clave_mision:
			_clave_mision = clave
			_anunciar_mision()
		# Durante el reto del rescate o en la tienda el reto ya trae su recuadro.
		var yo: Node = jugadores.get_node_or_null(str(multiplayer.get_unique_id()))
		if _panel_mision.visible and yo != null and (yo.en_rescate() or yo.en_tienda() or juego.get_node("Partida").oleadas_miel.activa()):
			if _anuncio:
				_anuncio.kill()
			_panel_mision.hide()
		_dato_mision.text = Controles.indicaciones(_dato_urgente())
		var destino: Variant = _objetivo()
		if destino != null:
			_flecha.objetivo = destino
			_flecha.activa = true


## La misión aparece al centro unos segundos y se desvanece.
func _anunciar_mision() -> void:
	if _anuncio:
		_anuncio.kill()
	var local: Node = jugadores.get_node_or_null(str(multiplayer.get_unique_id()))
	if local != null and (local.en_rescate() or local.en_tienda()):
		_panel_mision.hide() # El reto ya da instrucciones; no superponer los textos.
		return
	_panel_mision.visible = true
	_panel_mision.modulate.a = 0.0
	_panel_mision.offset_top = 108
	_anuncio = create_tween()
	_anuncio.tween_property(_panel_mision, "modulate:a", 1.0, 0.3)
	_anuncio.parallel().tween_property(_panel_mision, "offset_top", 124.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anuncio.tween_interval(DURACION_ANUNCIO)
	_anuncio.tween_property(_panel_mision, "modulate:a", 0.0, 0.6)
	_anuncio.tween_callback(_panel_mision.hide)


func _dato_urgente() -> String:
	var rescate: Node = juego.get_node("Partida").rescate
	if not rescate.listo():
		return "Oseznos a salvo: %d/2 · Miel, torre y equilibrio" % rescate.rescatados
	if jefe.activa:
		var olla: int = estacion.vida_olla
		return "" if jefe.estado == "derrotada" else ("Olla: %d" % olla if olla > 0 else "Olla rota")
	if not estacion.fogata.encendida:
		return "Fogata: %d/2 palos · E para colocar o participar" % estacion.fogata.colocados
	if estacion.terminada and not estacion.alimentados:
		return "Mamá Osa llega en %d s" % ceili(estacion.tiempo)
	return ""


## A dónde tiene que ir este jugador ahora (o null si no hace falta flecha).
func _objetivo() -> Variant:
	if juego.get_node("Partida").finalizada or estacion.alimentados and not jefe.activa:
		return null
	if jefe.activa:
		return null if jefe.estado == "derrotada" else jefe.global_position
	if estacion.terminada:
		return estacion.lugar_oseznos()
	if estacion.completa():
		return estacion.global_position
	var yo := multiplayer.get_unique_id()
	var mio: Node2D = jugadores.get_node_or_null(str(yo))
	if mio == null:
		return null
	var rescate: Node = juego.get_node("Partida").rescate
	if not rescate.listo():
		if rescate.contiene(yo):
			return null
		if not rescate.cebo and mio._pieza_cargada() == null:
			for pieza in get_tree().get_nodes_in_group("piezas"):
				if pieza.tipo == "miel":
					return pieza.global_position
		return rescate.lugar()
	var f: Node2D = estacion.fogata
	if not f.encendida and mio._pieza_cargada() == null:
		if f.colocados == 2 or f.cantidad(yo) > 0:
			return estacion.global_position
		var punto: Variant = null
		var distancia := INF
		for palo in f.suelo.values():
			var d := mio.global_position.distance_to(palo)
			if d < distancia:
				distancia = d
				punto = palo
		if punto != null:
			return punto
		if f.faltan_palos():
			for arbol in get_tree().get_nodes_in_group("arboles_con_palos"):
				var d := mio.global_position.distance_to(arbol.global_position)
				if d < distancia:
					distancia = d
					punto = arbol.global_position
		return punto if punto != null else estacion.global_position
	var cercana: Node2D = null
	var busqueda: Node = juego.get_node("Partida").busqueda_olla
	if busqueda.habilitada() and not busqueda.conseguida:
		return null if busqueda.dentro(yo) else busqueda.lugar()
	var miel: Node = juego.get_node("Partida").oleadas_miel
	if miel.habilitada():
		return null if miel.activa() else miel.CENTRO
	for pieza: Node2D in get_tree().get_nodes_in_group("piezas"):
		if pieza.entregada or not pieza.disponible():
			continue
		# Si ya la carga, toca llevarla a la fogata del lago.
		if pieza.portador == yo:
			return estacion.global_position
		if pieza.portador == 0 and (cercana == null or
				mio.position.distance_to(pieza.global_position) < mio.position.distance_to(cercana.global_position)):
			cercana = pieza
	return cercana.global_position if cercana else null


## Estilo cantina (scripts/tema_ui.gd): fondo del menú, logo, letreros de madera
## detrás de cada pantalla y marco de madera para la barra de Mamá Osa.
func _decorar_ui() -> void:
	# UI es una CanvasLayer: el tema se pone en cada pantalla (los hijos lo heredan).
	var ui: CanvasLayer = $UI
	for hijo in ui.get_children():
		if hijo is Control:
			hijo.theme = TemaUI.tema()
	_fondo_menu = preload("res://scripts/fondo_menu.gd").new()
	_fondo_menu.name = "FondoMenu"
	_fondo_menu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo_menu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fondo_menu)
	ui.move_child(_fondo_menu, 0)
	_version = Label.new()
	_version.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.1.0-alpha"))
	_version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_version.offset_left = -190
	_version.offset_top = -32
	_version.offset_right = -16
	_version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_version.add_theme_font_size_override("font_size", 13)
	_version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_version)
	_continuar = Button.new()
	_continuar.text = "Continuar partida guardada"
	$UI/Menu.add_child(_continuar)
	$UI/Menu.move_child(_continuar, $UI/Menu/Crear.get_index() + 1)
	_continuar.pressed.connect(func():
		_cargar_guardado = true
		_crear_partida())
	# Logo en lugar del título de texto del menú principal.
	var titulo: Label = $UI/Menu/Titulo
	var logo := TextureRect.new()
	logo.texture = preload("res://arte/ui/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(440, 220)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI/Menu.add_child(logo)
	$UI/Menu.move_child(logo, titulo.get_index())
	titulo.visible = false
	for nombre in ["Unirse", "Opciones", "Sala"]:
		var t: Label = get_node("UI/%s/Titulo" % nombre)
		t.add_theme_font_size_override("font_size", 32)
		t.add_theme_font_override("font", TemaUI.fuente("bold"))
		t.add_theme_color_override("font_color", Color("ffd36b"))
	# Letrero detrás de cada pantalla (el menú lleva el logo encima, sin letrero).
	for nombre in ["unirse", "opciones", "sala"]:
		var letrero := Panel.new()
		letrero.add_theme_stylebox_override("panel", TemaUI.panel_letrero())
		letrero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(letrero)
		ui.move_child(letrero, pantallas[nombre].get_index())
		_letreros[letrero] = pantallas[nombre]
	# Los controles van en Opciones, no encima de la partida.
	var controles := Button.new()
	controles.text = "Ver y modificar controles"
	controles.pressed.connect(abrir_controles)
	$UI/Opciones.add_child(controles)
	$UI/Opciones.move_child(controles, $UI/Opciones/Volver.get_index())
	$UI/Opciones/TextoVolumen.text = "Volumen general"
	Audio.agregar_deslizadores($UI/Opciones, $UI/Opciones/Volumen.get_index() + 1)
	# Misión: recuadro chico que aparece un ratito al centro cuando cambia
	# (ver _anunciar_mision); el resto del tiempo se consulta en la pausa (Esc).
	_panel_mision = PanelContainer.new()
	var caja := StyleBoxFlat.new()
	caja.bg_color = Color(0.14, 0.08, 0.04, 0.88)
	caja.border_color = Color("f2a93b")
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(8)
	caja.content_margin_left = 18
	caja.content_margin_right = 18
	caja.content_margin_top = 8
	caja.content_margin_bottom = 10
	_panel_mision.add_theme_stylebox_override("panel", caja)
	_panel_mision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_mision.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel_mision.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel_mision.offset_top = 124
	_panel_mision.theme = TemaUI.tema()
	_panel_mision.visible = false
	ui.add_child(_panel_mision)
	var columna_mision := VBoxContainer.new()
	columna_mision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_mision.add_child(columna_mision)
	var titulo_mision := Label.new()
	titulo_mision.text = "MISIÓN"
	titulo_mision.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_mision.add_theme_font_override("font", TemaUI.fuente("bold"))
	titulo_mision.add_theme_font_size_override("font_size", 16)
	titulo_mision.add_theme_color_override("font_color", Color("ffd36b"))
	columna_mision.add_child(titulo_mision)
	ui.remove_child(mision)
	columna_mision.add_child(mision)
	mision.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mision.add_theme_color_override("font_color", Color("fff3d6"))
	mision.add_theme_constant_override("outline_size", 0)
	mision.add_theme_font_size_override("font_size", 14)
	# Dato que sí urge tener siempre a la vista (la cuenta atrás, la olla…):
	# chiquito, arriba al centro.
	_dato_mision = Label.new()
	_dato_mision.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_dato_mision.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dato_mision.offset_top = 14
	_dato_mision.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dato_mision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dato_mision.theme = TemaUI.tema()
	_dato_mision.add_theme_font_override("font", TemaUI.fuente("bold"))
	_dato_mision.add_theme_font_size_override("font_size", 18)
	_dato_mision.add_theme_color_override("font_color", Color("ffd36b"))
	ui.add_child(_dato_mision)
	_flecha = preload("res://scripts/flecha_objetivo.gd").new()
	_flecha.theme = TemaUI.tema()
	ui.add_child(_flecha)
	# Marco de madera alrededor de la barra del jefe (la canaleta queda en Fondo).
	var fondo: ColorRect = $UI/Jefe/Fondo
	fondo.color = Color("1d120c")
	# La barra del jefe va abajo al centro: arriba quedan tu tarjeta y la misión.
	var barra: Control = $UI/Jefe
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_top = -112.0
	barra.offset_bottom = -68.0
	# El nombre del jefe sube para no quedar bajo el marco.
	$UI/Jefe/Texto.position.y -= 16
	$UI/Jefe/Texto.add_theme_font_override("font", TemaUI.fuente("bold"))
	$UI/Jefe/Texto.add_theme_font_size_override("font_size", 20)
	# La sala es alta: más compacta para que quepa dentro del letrero.
	$UI/Sala.add_theme_constant_override("separation", 6)
	$UI/Sala/Titulo.add_theme_font_size_override("font_size", 28)
	var marco := Panel.new()
	marco.add_theme_stylebox_override("panel", TemaUI.marco_barra())
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hueco: Array = TemaUI.HUECO_BARRA
	marco.position = fondo.position - Vector2(hueco[0], hueco[1])
	marco.size = fondo.size + Vector2(hueco[0] + hueco[2], hueco[1] + hueco[3])
	$UI/Jefe.add_child(marco)
	# El marco va encima del relleno para tapar sus orillas.
	$UI/Jefe.move_child(marco, $UI/Jefe/Barra.get_index() + 1)


func _acomodar_letreros() -> void:
	for letrero: Panel in _letreros:
		var pantalla: Control = _letreros[letrero]
		letrero.visible = pantalla.visible
		if letrero.visible:
			# Sin salirse de la pantalla (la sala es muy alta): mejor recortar el margen.
			var caja := Rect2(pantalla.position - MARGEN_LETRERO, pantalla.size + MARGEN_LETRERO * 2)
			caja = caja.intersection(get_viewport().get_visible_rect().grow(-6))
			letrero.position = caja.position
			letrero.size = caja.size


func _mostrar(pantalla: String) -> void:
	if pantalla == "opciones":
		$UI/Opciones/Volumen.set_value_no_signal(Audio.volumen("general"))
		$UI/Opciones/PantallaCompleta.set_pressed_no_signal(DisplayServer.window_get_mode() in [
			DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	for nombre in pantallas:
		pantallas[nombre].visible = nombre == pantalla
	_version.visible = pantalla == "menu"
	if pantalla == "menu":
		# Listo para escribir el nombre sin tener que darle clic.
		campo_nombre.grab_focus.call_deferred()
		campo_nombre.caret_column = campo_nombre.text.length()
	_continuar.visible = pantalla == "menu" and Guardado.existe()
	_fondo_menu.visible = pantalla != "juego"
	if pantalla != "juego":
		Audio.musica("menu")
	else:
		Audio.musica("jefe" if jefe.activa and jefe.estado != "derrotada" else "bosque")
	juego.visible = pantalla == "juego"
	# Los controles se consultan en Opciones; en partida no se muestran.
	ayuda.visible = false
	# Al entrar al bosque la misión se anuncia de nuevo.
	_clave_mision = ""
	if pantalla != "juego":
		_panel_mision.hide()
	mision.visible = pantalla == "juego"
	hud.visible = pantalla == "juego"
	if pantalla != "juego":
		hud.limpiar()
	aviso.text = ""


func _usar_bosque(bosque: Node2D) -> void:
	juego = bosque
	juego.process_mode = Node.PROCESS_MODE_PAUSABLE
	jugadores = bosque.get_node("Mundo/Jugadores")
	inicio = bosque.get_node("Inicio")
	aparecedor = bosque.get_node("Aparecedor")
	estacion = bosque.get_node("Mundo/Estacion")
	jefe = bosque.get_node("Mundo/MamaOsa")
	bosque.get_node("Partida").finalizo.connect(_fin_ronda)
	aparecedor.spawn_function = _crear_jugador


# Deja el bosque como nuevo (piezas, fogata, abejas) para la siguiente partida.
func _reiniciar_bosque() -> void:
	remove_child(juego)
	juego.queue_free()
	var nuevo := BOSQUE.instantiate()
	nuevo.name = "Juego"
	add_child(nuevo)
	move_child(nuevo, 0)
	_usar_bosque(nuevo)


func _crear_partida() -> void:
	Guardado.pendiente = Guardado.cargar() if _cargar_guardado else {}
	if _cargar_guardado and Guardado.pendiente.is_empty():
		_cargar_guardado = false
		aviso.text = Guardado.ultimo_error
		return
	_cargar_guardado = false
	Red.mi_nombre = campo_nombre.text
	if Red.crear_partida() != OK:
		aviso.text = "No se pudo crear la partida (¿puerto %d ocupado?)." % Red.puerto
		return
	for guardado in Guardado.pendiente.get("jugadores", []):
		if guardado.get("anfitrion", false):
			Red.pedir_color(guardado.color)
			break
	print("Partida creada en el puerto %d" % Red.puerto)
	_mostrar("sala")
	_lanzar_bot_de_ayuda()


# Abre otra copia del juego, sin ventana, que se une a esta partida y juega sola.
func _lanzar_bot_de_ayuda() -> void:
	# No aplica en pruebas automáticas (--auto) ni en instancias sin ventana.
	if not bot_de_ayuda or _auto or not _pids_bots.is_empty() or DisplayServer.get_name() == "headless":
		return
	# En el juego exportado (para jugar con amigos) no entran bots solos.
	if not OS.has_feature("editor"):
		return
	for numero in range(1, cantidad_bots + 1):
		var args := PackedStringArray(["--headless"])
		if OS.has_feature("editor"):
			args.append_array(["--path", ProjectSettings.globalize_path("res://")])
		args.append_array(["--", "--join=127.0.0.1", "--auto",
			"--bot-torre" if probar_torre_con_bots else "--bot-mision", "--bot-ayuda", "--bot-turno=%d" % numero,
			"--nombre=Bot %d" % numero, "--puerto=%d" % Red.puerto])
		var pid := OS.create_process(OS.get_executable_path(), args)
		_pids_bots.append(pid)
		print("Bot de ayuda %d lanzado (proceso %d)" % [numero, pid])


func _quitar_bot_de_ayuda() -> void:
	for pid in _pids_bots:
		OS.kill(pid)
	_pids_bots.clear()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST or que == NOTIFICATION_PREDELETE:
		_quitar_bot_de_ayuda()


func _fin_ronda(victoria: bool, filas: Array) -> void:
	Audio.musica("victoria" if victoria else "derrota")
	_aplicar_pausa(0)
	hud.mostrar_resultados(victoria, filas)


func _preparar_sala(desde_pausa: bool = false) -> void:
	if not multiplayer.is_server() or _regresando_sala:
		return
	if not juego.get_node("Partida").finalizada and not (desde_pausa and get_tree().paused):
		return
	_regresando_sala = true
	var bosque_saliendo := juego
	_ronda_salida += 1
	_salidas_listas.clear()
	_detener_replicas.rpc(_ronda_salida)
	# Los dueños dejan de publicar antes de que el servidor borre sus nodos.
	# Así no llegan posiciones atrasadas a un Sincronizador que ya no existe.
	var limite := Time.get_ticks_msec() + 5000
	while not Array(multiplayer.get_peers()).all(func(id): return _salidas_listas.has(id)):
		if Time.get_ticks_msec() >= limite:
			_reanudar_replicas.rpc()
			_regresando_sala = false
			pausa.detalle.text = "Un compañero no respondió. Intenten volver al lobby de nuevo."
			return
		await get_tree().create_timer(0.05, true).timeout
		if not is_instance_valid(bosque_saliendo) or juego != bosque_saliendo:
			return
	var drenaje := 0.2
	for ms in Red.latencias.values():
		drenaje = maxf(drenaje, clampf(float(ms) / 500.0, 0.2, 1.0))
	await get_tree().create_timer(drenaje, true).timeout
	if not is_instance_valid(bosque_saliendo) or juego != bosque_saliendo:
		return
	# Desaparecer primero los nodos replicados. Así los clientes procesan sus
	# despawns antes de que la RPC siguiente sustituya el bosque completo.
	for j in jugadores.get_children():
		j.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_volver_sala.rpc()


@rpc("authority", "call_local", "reliable")
func _detener_replicas(numero: int) -> void:
	_intervalos_replica.clear()
	for sincronizador in juego.find_children("*", "MultiplayerSynchronizer", true, false):
		_intervalos_replica[sincronizador] = [sincronizador.replication_interval, sincronizador.delta_interval]
		sincronizador.replication_interval = 3600.0
		sincronizador.delta_interval = 3600.0
	if not multiplayer.is_server():
		_salida_lista.rpc_id(1, numero)


@rpc("any_peer", "call_remote", "reliable")
func _salida_lista(numero: int) -> void:
	if multiplayer.is_server() and _regresando_sala and numero == _ronda_salida:
		_salidas_listas[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_local", "reliable")
func _reanudar_replicas() -> void:
	for sincronizador in _intervalos_replica:
		if is_instance_valid(sincronizador):
			sincronizador.replication_interval = _intervalos_replica[sincronizador][0]
			sincronizador.delta_interval = _intervalos_replica[sincronizador][1]
	_intervalos_replica.clear()


@rpc("authority", "call_local", "reliable")
func _volver_sala() -> void:
	_intervalos_replica.clear()
	_aplicar_pausa(0)
	# El bot de ayuda sigue marcándose listo solo en la siguiente ronda.
	_auto = "--bot-ayuda" in OS.get_cmdline_user_args()
	_regresando_sala = false
	_reiniciar_bosque()
	for datos in Red.jugadores.values():
		datos.listo = false
	_mostrar("sala")
	Red.jugadores_cambiaron.emit()
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = false
		Red._sincronizar.rpc(Red.jugadores)


func _unirse() -> void:
	Red.mi_nombre = campo_nombre.text
	var ip := campo_ip.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	if Red.unirse(ip) != OK:
		aviso.text = "Dirección inválida."
		return
	aviso.text = "Conectando a %s..." % ip


func _volver_al_menu(mensaje: String) -> void:
	_regresando_sala = false
	_ronda_salida += 1
	_intervalos_replica.clear()
	_aplicar_pausa(0)
	# El bot de ayuda no se queda huérfano: si pierde la partida, se cierra.
	if "--bot-ayuda" in OS.get_cmdline_user_args():
		# La desconexión se notifica antes de terminar el cuadro: no seguir
		# consultando autoridad en nodos de juego con el peer ya cerrado.
		process_mode = Node.PROCESS_MODE_DISABLED
		get_tree().quit()
		return
	_quitar_bot_de_ayuda()
	Red.salir()
	_reiniciar_bosque()
	_mostrar("menu")
	aviso.text = mensaje
	if mensaje:
		print(mensaje)


func _empezar_juego() -> void:
	_aplicar_pausa(0)
	_mostrar("juego")
	print("Empieza la partida: %s" % [Red.jugadores])
	if multiplayer.is_server():
		for id in Red.jugadores:
			aparecedor.spawn([id, Red.jugadores[id].color, Red.jugadores[id].nombre, Guardado.jugador_guardado(Red.jugadores[id].color)])
		if not Guardado.pendiente.is_empty():
			_restaurar_guardado.rpc(Guardado.pendiente)
			Guardado.pendiente = {}


func _salio_jugador(id: int) -> void:
	if multiplayer.is_server() and _pausado_por == id:
		_aplicar_pausa.rpc(0)
	if multiplayer.is_server() and jugadores.has_node(str(id)):
		juego.get_node("Partida").torre.romper_desde(jugadores.get_node(str(id)))
		for pieza in get_tree().get_nodes_in_group("piezas"):
			if pieza.portador == id:
				pieza.soltar(pieza.position)
		jugadores.get_node(str(id)).queue_free()


# Corre en todas las pantallas cada vez que el anfitrión aparece un jugador.
func _crear_jugador(datos: Array) -> Node:
	var j := JUGADOR.instantiate()
	j.name = str(datos[0])
	j.color_indice = datos[1]
	j.nombre = datos[2]
	# Cada color tiene su lugar junto a la fogata para que no aparezcan encimados.
	j.position = inicio.position + Vector2(datos[1] % 3 * 60, datos[1] / 3 * 50)
	if datos.size() > 3 and not datos[3].is_empty():
		Guardado.aplicar(j, datos[3], Guardado.JUGADOR)
		j.position = datos[3].position
		j.proteccion = 3.0
	return j


func _auto_listo() -> void:
	if not _auto or juego.visible:
		return
	var yo: Dictionary = Red.jugadores.get(multiplayer.get_unique_id(), {})
	if not yo.is_empty() and not yo.listo:
		Red.pedir_listo(true)
	elif multiplayer.is_server() and Red.jugadores.size() >= 2:
		Red.iniciar_partida()


func _pantalla_completa(activa: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if activa else DisplayServer.WINDOW_MODE_WINDOWED)


func _volumen(valor: float) -> void:
	Audio.cambiar_volumen("general", valor)


func abrir_controles() -> void:
	if is_instance_valid(editor_controles):
		return
	editor_controles = preload("res://scripts/panel_controles.gd").new()
	add_child(editor_controles)


func _guardar_partida() -> void:
	pausa.detalle.text = Guardado.guardar(self)


@rpc("authority", "call_local", "reliable")
func _restaurar_guardado(datos: Dictionary) -> void:
	Guardado.restaurar_mundo(self, datos)
