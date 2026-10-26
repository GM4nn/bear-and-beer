extends CanvasLayer
## Vista local de la misma pila replicada. Reutiliza objetos y manos del juego.
var lienzo: Control
var fondo: ColorRect
var titulo: Label
var aviso: Label
var ayuda: Label
var estado: Label
var _cursor := Vector2(640, 590)
var _pulsado := false
var _envio := 0.0
var _secuencia := 0
var _encuentro := -1
var _bot_agarre := 0.0
var _texturas: Array = []
var _fondo: Texture2D
var _bultos: Array = []
## Brazo con mano de abierta (0) a puño (3); la manga va en gris para teñirla.
var _brazos: Array = []
var _mangas: Array = []
## Qué tan cerrada va cada mano (0 abierta, 1 puño), para animar el agarre.
var _cierre := {}
const AGARRE := Vector2(44, 92)
const LARGO_BRAZO := 100.0

func _ready() -> void:
	layer = 11
	fondo = ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color("17130f")
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)
	lienzo = Control.new()
	lienzo.size = Vector2(1280, 720)
	lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(lienzo)
	lienzo.draw.connect(_dibujar)
	titulo = etiqueta(Vector2(40, 18), Vector2(1200, 48), 29)
	titulo.text = "¡Los compas dejaron esto hecho un desmadre!"
	ayuda = etiqueta(Vector2(80, 73), Vector2(1120, 65), 18)
	aviso = etiqueta(Vector2(70, 245), Vector2(1140, 44), 23)
	estado = etiqueta(Vector2(40, 646), Vector2(1200, 65), 18)
	for ruta in ["objetos/hd/olla", "hd/hielera", "hd/sillas", "objetos/hd/lena", "objetos/hd/chela", "objetos/hd/cartel", "hd/asador", "objetos/hd/olla_rota"]:
		var textura: Texture2D = load("res://arte/zona1/%s.png" % ruta)
		var recorte := AtlasTexture.new()
		recorte.atlas = textura
		recorte.region = textura.get_image().get_used_rect()
		_texturas.append(recorte)
	var carpeta := "res://arte/zona1/carpa_dentro/"
	_fondo = load(carpeta + "fondo.png")
	for i in 4:
		var textura: Texture2D = load(carpeta + "bulto%d.png" % i)
		var recorte := AtlasTexture.new()
		recorte.atlas = textura
		recorte.region = textura.get_image().get_used_rect()
		_bultos.append(recorte)
		_brazos.append(load(carpeta + "mano/brazo%d.png" % i))
		_mangas.append(load(carpeta + "mano/manga%d.png" % i))
	get_window().focus_exited.connect(_soltar)
	hide()

func etiqueta(pos: Vector2, tam: Vector2, letra: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = tam
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", letra)
	l.add_theme_color_override("font_outline_color", Color("17120d"))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lienzo.add_child(l)
	return l

func _soltar() -> void:
	_pulsado = false
	_envio = 1.0

func _notification(que: int) -> void:
	if que == NOTIFICATION_PAUSED or que == NOTIFICATION_UNPAUSED:
		_soltar()

func _input(evento: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if evento is InputEventMouse:
		_cursor = ((evento.position - lienzo.position) / lienzo.scale).clamp(Vector2.ZERO, Vector2(1279, 719))
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
			_pulsado = evento.pressed
		elif evento is InputEventMouseMotion:
			_pulsado = (evento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var b := get_parent()
	var yo := multiplayer.get_unique_id()
	visible = b.dentro(yo)
	if not visible:
		_pulsado = false
		return
	var tam := get_viewport().get_visible_rect().size
	lienzo.scale = Vector2.ONE * minf(tam.x / 1280.0, tam.y / 720.0)
	lienzo.position = (tam - Vector2(1280, 720) * lienzo.scale) * 0.5
	if _encuentro != b.encuentro:
		_encuentro = b.encuentro
		_secuencia = 0
		_pulsado = false
	ayuda.text = "Mantén clic para agarrar. Arrastra y suelta para aventar. Repartan las cosas entre ambos lados.\nCuando aparezca la olla, llévenla a SALIDA y suéltenla. Cada compa debe apartar algo."
	aviso.text = b.mensaje if b.estado != "buscando" else "¡PILA INESTABLE! Retiren las manos o quiten objetos" if b.riesgo[0] > 0 or b.riesgo[1] > 0 else "Busquen debajo del montón"
	aviso.modulate = Color("ffbb76") if b.lado_caida >= 0 or b.riesgo[0] > 0 or b.riesgo[1] > 0 else Color.WHITE
	var filas := PackedStringArray()
	for id in b.participantes:
		var j: Node = b.jugador(id)
		filas.append("%s%s" % [j.nombre if j else "Compa", " ✓" if b.aportes.get(id, false) else ""])
	estado.text = " · ".join(filas) + "\n" + Controles.indicaciones("E: salir de la tienda · Esc: pausa")
	lienzo.queue_redraw()
	_envio += delta
	_bot_agarre += delta
	if b.estado != "buscando" or _envio < 0.05:
		return
	_envio = 0.0
	var j: Node = b.jugador(yo)
	if j != null and not j._bot.is_empty():
		var plan: Dictionary = b.plan_bot(yo)
		_cursor = plan.pos
		var pulsa: bool = plan.pulsa
		if b.manos[yo].objeto < 0 and _pulsado and _bot_agarre > 0.2:
			pulsa = false
		if pulsa != _pulsado:
			_bot_agarre = 0.0
		_pulsado = pulsa
	_secuencia += 1
	if multiplayer.is_server():
		b.mover(b.encuentro, _secuencia, _cursor, _pulsado)
	else:
		b.mover.rpc_id(1, b.encuentro, _secuencia, _cursor, _pulsado)

func _dibujar() -> void:
	var b := get_parent()
	# Interior de la tienda (pixel art) y una franja oscura para leer el texto.
	lienzo.draw_texture_rect(_fondo, Rect2(0, 0, 1280, 720), false)
	lienzo.draw_rect(Rect2(0, 0, 1280, 140), Color(0.06, 0.03, 0.01, 0.55))
	lienzo.draw_rect(Rect2(0, 640, 1280, 80), Color(0.06, 0.03, 0.01, 0.6))
	lienzo.draw_rect(b.SALIDA, Color(0.12, 0.24, 0.18, 0.75))
	lienzo.draw_rect(b.SALIDA, Color("a9d986"), false, 3)
	texto("SALIDA · OLLA", Vector2(555, 210), Color("ddf2bc"), 22)
	for lado in 2:
		var zona: Rect2 = b.zona_caida(lado)
		lienzo.draw_rect(zona, Color(0.2, 0.12, 0.06, 0.22))
		texto("PILA %d / %d" % [b.pilas[lado], b.LIMITE_PILA], Vector2(zona.position.x + 60, 235), Color("fff1c2"), 20)
		if b.riesgo[lado] > 0:
			lienzo.draw_rect(zona, Color(1, 0.25, 0.1, 0.15 + sin(b.tiempo * 15) * 0.05))
			lienzo.draw_rect(Rect2(zona.position + Vector2(0, 370), Vector2(zona.size.x * b.riesgo[lado] / b.AVISO_CAIDA, 8)), Color("ff784c"))
	for agarrados in [false, true]:
		for i in b.objetos.size():
			var o: Dictionary = b.objetos[i]
			if (o.dueno != 0) != agarrados:
				continue
			var rect: Rect2 = b.rect_objeto(i)
			var temblor := Vector2(sin(b.tiempo * 28 + i) * 4, 0) if o.lado >= 0 and b.riesgo[o.lado] > 0 else Vector2.ZERO
			rect.position += temblor
			lienzo.draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0.08, 0.05, 0.02, 0.35))
			if i > 0:
				# Trastos sobre bultos opacos: el área que tapa coincide con la selección.
				var bulto: Texture2D = _bultos[i % _bultos.size()]
				lienzo.draw_texture_rect(bulto, rect.grow(6), false)
			var tex: Texture2D = _texturas[o.tipo]
			var escala := minf((rect.size.x - 12) / tex.get_width(), (rect.size.y - 10) / tex.get_height())
			var tam: Vector2 = tex.get_size() * escala
			lienzo.draw_texture_rect(tex, Rect2(rect.get_center() - tam * 0.5, tam), false)
	for id in b.participantes:
		if not b.manos.has(id):
			continue
		var j: Node = b.jugador(id)
		var color: Color = j.COLORES[j.color_indice % j.COLORES.size()] if j else Color("a24e32")
		var pos: Vector2 = b.manos[id].pos
		var origen: Vector2 = b.origen_brazo(id)
		var dolor: bool = b.manos[id].dolor > 0
		if dolor:
			pos += Vector2(sin(b.tiempo * 30) * 7, 12)
		# La mano se va cerrando al agarrar algo (o al picar el clic la propia).
		var cerrar: bool = b.manos[id].objeto >= 0 or (id == multiplayer.get_unique_id() and _pulsado)
		_cierre[id] = move_toward(_cierre.get(id, 0.0), 1.0 if cerrar else 0.0, get_process_delta_time() * 7.0)
		var cuadro := clampi(roundi(_cierre[id] * 3.0), 0, 3)
		var manga := (color if j else Color("c0392b")).darkened(0.1)
		for lado in [-1, 1]:
			var palma := pos + Vector2(lado * 28, 4)
			var codo := origen + Vector2(lado * 40, 0)
			var rumbo := (palma - codo).normalized()
			# Lo que falta entre el borde de la pantalla y el antebrazo es pura manga.
			var puno := palma - rumbo * LARGO_BRAZO
			if codo.distance_to(palma) > LARGO_BRAZO:
				lienzo.draw_line(codo, puno, Color("1d1410"), 56)
				lienzo.draw_line(codo, puno, manga, 48)
			lienzo.draw_set_transform(palma, rumbo.angle() + PI * 0.5, Vector2(-lado, 1))
			var tinte := Color("ff7766") if dolor else Color.WHITE
			lienzo.draw_texture(_brazos[cuadro], -AGARRE, tinte)
			lienzo.draw_texture(_mangas[cuadro], -AGARRE, manga * tinte)
			lienzo.draw_set_transform(Vector2.ZERO)
		texto((j.nombre if j else "Compa") + (" ¡AY! -12" if dolor else ""), pos + Vector2(-35, -38), Color("ff9982") if dolor else Color.WHITE, 17)
		if id == multiplayer.get_unique_id():
			lienzo.draw_arc(pos, 18, 0, TAU, 24, Color("fff2a2"), 2, true)

func texto(valor: String, donde: Vector2, color: Color, letra: int) -> void:
	lienzo.draw_string_outline(ThemeDB.fallback_font, donde, valor, HORIZONTAL_ALIGNMENT_LEFT, -1, letra, 4, Color("17120d"))
	lienzo.draw_string(ThemeDB.fallback_font, donde, valor, HORIZONTAL_ALIGNMENT_LEFT, -1, letra, color)
