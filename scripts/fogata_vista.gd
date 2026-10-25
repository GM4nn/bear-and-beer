extends CanvasLayer
## Acercamiento local; los dos brazos y el avance se leen del estado compartido.
var panel: Control
var escena: PrimerPlano
var titulo: Label
var instrucciones: Label
var horizontal: Label
var vertical: Label
var estado: Label
var guia: Label
var barra: ProgressBar
var salir: Label
var _pulsado := false
var _movimiento := Vector2.ZERO
var _envio := 0.0
var _estaba := false


func _ready() -> void:
	layer = 10
	get_window().focus_exited.connect(cancelar_arrastre)
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var fondo := ColorRect.new()
	fondo.color = Color("151e16")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(fondo)
	escena = PrimerPlano.new()
	escena.size = Vector2(1280, 720)
	escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(escena)
	titulo = _etiqueta(Vector2(80, 32), Vector2(1120, 50), 30)
	instrucciones = _etiqueta(Vector2(80, 85), Vector2(1120, 70), 20)
	horizontal = _etiqueta(Vector2(55, 175), Vector2(430, 88), 19)
	vertical = _etiqueta(Vector2(795, 175), Vector2(430, 88), 19)
	guia = _etiqueta(Vector2(510, 183), Vector2(260, 76), 21)
	guia.modulate = Color("f8ad45")
	estado = _etiqueta(Vector2(190, 545), Vector2(900, 45), 24)
	barra = ProgressBar.new()
	barra.position = Vector2(240, 600)
	barra.size = Vector2(800, 26)
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escena.add_child(barra)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = Color("f8ad45")
	lleno.set_corner_radius_all(8)
	barra.add_theme_stylebox_override("fill", lleno)
	var canal := StyleBoxFlat.new()
	canal.bg_color = Color("352d21")
	canal.set_corner_radius_all(8)
	barra.add_theme_stylebox_override("background", canal)
	salir = _etiqueta(Vector2(100, 653), Vector2(1080, 36), 17)
	salir.text = "E · Salir del acercamiento     |     Esc · Pausar"
	panel.hide()


func _etiqueta(posicion: Vector2, tamano: Vector2, letra: int) -> Label:
	var texto := Label.new()
	texto.position = posicion
	texto.size = tamano
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", letra)
	texto.add_theme_color_override("font_color", Color("fff1cf"))
	texto.add_theme_color_override("font_outline_color", Color("1a1009"))
	texto.add_theme_constant_override("outline_size", 8)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escena.add_child(texto)
	return texto


func cancelar_arrastre() -> void:
	_pulsado = false
	_movimiento = Vector2.ZERO
	_envio = 0


func _input(evento: InputEvent) -> void:
	if not panel.visible or get_tree().paused:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_pulsado = evento.pressed
		_movimiento = Vector2.ZERO
		get_viewport().set_input_as_handled()
	elif evento is InputEventMouseMotion:
		if _pulsado and evento.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_movimiento += evento.relative / escena.scale.x
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		panel.hide()
		cancelar_arrastre()
		return
	var f := get_parent()
	var yo := multiplayer.get_unique_id()
	var jugador_local: Node2D = f._jugador(yo)
	if jugador_local == null:
		panel.hide()
		cancelar_arrastre()
		return
	var abierta: bool = f.dentro(yo)
	panel.visible = abierta
	if abierta != _estaba:
		cancelar_arrastre()
		_estaba = abierta
	if not abierta:
		return
	var escala := minf(get_viewport().get_visible_rect().size.x / 1280, get_viewport().get_visible_rect().size.y / 720)
	escena.scale = Vector2.ONE * escala
	escena.position = (get_viewport().get_visible_rect().size - Vector2(1280, 720) * escala) * 0.5
	salir.text = Controles.indicaciones("E · Salir del acercamiento     |     Esc · Pausar")
	var rol: int = f.participantes.find(yo)
	titulo.text = "ENCENDER LA FOGATA" if rol >= 0 else "FOGATA · ESPECTADOR"
	instrucciones.text = "Mantén clic para tener firmes los brazos, acomódalos en el palo (arriba/abajo) y frota a la derecha y de vuelta" if rol == 0 else "Mantén clic para tener firmes los brazos, acomódalos en el palo (arriba/abajo) y frota a la izquierda y de vuelta" if rol == 1 else "Mira cómo se coordinan tus dos compas. Tus movimientos no afectan el fuego."
	horizontal.text = _nombre(f, 0) + "\n→ FROTA ←\n" + f.consejos[0]
	vertical.text = _nombre(f, 1) + "\n← FROTA →\n" + f.consejos[1]
	horizontal.modulate = Color("a7eda0") if f.ritmo[0] else Color.WHITE
	vertical.modulate = Color("a7eda0") if f.ritmo[1] else Color.WHITE
	if f.participantes.size() < 2:
		estado.text = "Esperando a otro compa: E junto a los palos"
	elif f.preparacion > 0:
		estado.text = "Prepárense… %d" % ceili(f.preparacion)
	else:
		estado.text = "%s · %d s · %d%%" % ["¡Sigan juntos!" if f.coordinados() else "Sigan juntos el ritmo de las flechas", ceili(f.tiempo), roundi(f.calor * 100)]
	estado.text = Controles.indicaciones(estado.text)
	var ida := int((f.TIEMPO - f.tiempo) / f.COMPAS) % 2 == 0
	guia.text = "RITMO GUÍA\n" + ("→   ←" if ida else "←   →")
	guia.visible = f.participantes.size() == 2 and f.preparacion <= 0
	barra.value = f.calor * 100
	escena.gestos = escena.gestos.lerp(Vector2(f.gestos[0], f.gestos[1]), 1.0 - exp(-18.0 * delta))
	escena.calor = f.calor
	escena.agarres = escena.agarres.lerp(Vector2(f.agarres[0], f.agarres[1]), 1.0 - exp(-14.0 * delta))
	escena.derivas = escena.derivas.lerp(Vector2(f.derivas[0], f.derivas[1]), 1.0 - exp(-12.0 * delta))
	escena.firmes = [_pulsado if rol == 0 else true, _pulsado if rol == 1 else true]
	for i in range(2):
		if i < f.participantes.size():
			var j: Node2D = f._jugador(f.participantes[i])
			if j != null:
				escena.colores[i] = j.COLORES[j.color_indice % j.COLORES.size()]
	escena.reloj += delta
	escena.queue_redraw()
	_envio += delta
	if rol >= 0 and _envio >= 0.05 and jugador_local._bot.is_empty():
		_envio = 0
		if multiplayer.is_server():
			f.mover(f.encuentro, _movimiento, _pulsado)
		else:
			f.mover.rpc_id(1, f.encuentro, _movimiento, _pulsado)
		_movimiento = Vector2.ZERO


func _nombre(f: Node, rol: int) -> String:
	if rol >= f.participantes.size():
		return "Esperando compañero"
	var j: Node2D = f._jugador(f.participantes[rol])
	return j.nombre if j != null else "Compa"


class PrimerPlano extends Control:
	## Acercamiento en pixel art (arte/zona1/fogata_cerca): taladro de mano. Un
	## palo parado gira sobre su eje con la punta contra una tabla en el piso; cada
	## compa lo frota con las dos palmas (uno de cada lado, en sentido contrario).
	const CARPETA := "res://arte/zona1/fogata_cerca/%s.png"
	## Punto donde la punta del palo frota la tabla (pantalla de 1280x720).
	const CRUCE := Vector2(640, 395)
	const ESCALA_PALO := 1.7
	const ESCALA_MANOS := 1.5
	## Donde la palma aprieta el palo en el dibujo de la mano (256x80, palma abajo).
	const PALMA := Vector2(212, 34)
	## Separación entre la mano de arriba y la de abajo: abiertas y apretando el palo.
	const ABIERTAS := 78.0
	const APRIETE := 30.0
	var gestos := Vector2.ZERO
	## Qué tan cerradas están las palmas de cada compa sobre el palo (0 a 1).
	var agarres := Vector2.ONE
	## Qué tan desviados están los brazos de cada compa (-1 arriba, 1 abajo).
	var derivas := Vector2.ZERO
	## Si cada compa tiene el clic sostenido (tiembla menos).
	var firmes := [true, true]
	var colores := [Color("c74327"), Color("367eba")]
	var calor := 0.0
	var reloj := 0.0
	var _tabla: Sprite2D
	var _huso: Sprite2D
	## Por compa: [mano de arriba, mano de abajo].
	var _manos: Array = []
	var _fuego: AnimatedSprite2D
	var _encima: Node2D
	var _giro := 0.0
	var _antes := Vector2.ZERO


	func _ready() -> void:
		var fondo := Sprite2D.new()
		fondo.texture = load(CARPETA % "fondo")
		fondo.centered = false
		fondo.scale = Vector2.ONE * 2.0
		fondo.show_behind_parent = true
		add_child(fondo)
		# La tabla: un palo acostado en la yesca, donde gira la punta.
		_tabla = _sprite("palo", ESCALA_PALO)
		_tabla.position = CRUCE + Vector2(40, 14)
		_tabla.flip_h = true
		# El huso: el mismo palo parado, con la punta quemada abajo.
		_huso = _sprite("palo", ESCALA_PALO)
		_huso.rotation = PI * 0.5
		var largo := 256.0 * ESCALA_PALO
		# La punta quemada queda apoyada sobre la tabla.
		_huso.position = CRUCE + Vector2(0, -largo * 0.5 + 38.0)
		var giro := ShaderMaterial.new()
		giro.shader = load("res://arte/zona1/fogata_cerca/girar.gdshader")
		_huso.material = giro
		_fuego = AnimatedSprite2D.new()
		var cuadros := SpriteFrames.new()
		cuadros.set_animation_speed("default", 9.0)
		# Solo las llamas de la fogata del mapa (sin su círculo de piedras).
		for i in range(4):
			var llama := AtlasTexture.new()
			llama.atlas = load("res://arte/zona1/fogata/hd/%d.png" % i)
			llama.region = Rect2(0, 48, 96, 52)
			cuadros.add_frame("default", llama)
		_fuego.sprite_frames = cuadros
		_fuego.centered = false
		_fuego.play()
		add_child(_fuego)
		# Las manos: el compa 1 por la izquierda (arriba del palo) y el compa 2 por
		# la derecha (más abajo). Cada uno aprieta el palo entre sus dos palmas: la
		# de abajo va detrás del palo y la de arriba delante.
		var abajo: Array[Sprite2D] = []
		var arriba: Array[Sprite2D] = []
		for i in range(2):
			abajo.append(_mano(i, true))
		move_child(_huso, -1)
		for i in range(2):
			arriba.append(_mano(i, false))
		for i in range(2):
			_manos.append([arriba[i], abajo[i]])
		_encima = Node2D.new()
		_encima.draw.connect(_chispas)
		add_child(_encima)


	func _sprite(nombre: String, escala: float, color := false) -> Sprite2D:
		var dibujo := Sprite2D.new()
		dibujo.texture = load(CARPETA % nombre)
		dibujo.scale = Vector2.ONE * escala
		if color:
			var tinte := ShaderMaterial.new()
			tinte.shader = preload("res://arte/jugador/color_jugador.gdshader")
			dibujo.material = tinte
		add_child(dibujo)
		return dibujo


	func _mano(compa: int, de_abajo: bool) -> Sprite2D:
		var mano := _sprite("mano", ESCALA_MANOS, true)
		mano.centered = false
		mano.flip_h = compa == 1
		mano.flip_v = de_abajo
		# La manga sigue hasta la orilla de la pantalla (tira repetida).
		var manga := Sprite2D.new()
		manga.texture = load(CARPETA % "manga_mano")
		manga.centered = false
		manga.region_enabled = true
		manga.region_rect = Rect2(0, 0, 700, 80)
		manga.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		manga.flip_v = de_abajo
		manga.position = Vector2(-700 + 1, 0) if compa == 0 else Vector2(255, 0)
		manga.use_parent_material = true
		mano.add_child(manga)
		return mano


	func _process(delta: float) -> void:
		# Qué tan rápido frotan: el palo gira más rápido.
		var rapidez := (gestos - _antes).length() / maxf(delta, 0.001)
		_antes = gestos
		_giro += delta * (0.4 + minf(rapidez, 12.0) * 0.45)
		(_huso.material as ShaderMaterial).set_shader_parameter("giro", _giro)
		var largo := 256.0 * ESCALA_PALO
		var x_huso := _huso.position.x
		# Cada compa frota con sus dos palmas: la de arriba y la de abajo se deslizan
		# en sentidos contrarios; el compa 2 frota al revés que el compa 1.
		var alturas := [CRUCE.y - largo * 0.62, CRUCE.y - largo * 0.3]
		for i in range(2):
			var gesto: float = gestos.x if i == 0 else gestos.y
			var palma_x := (256.0 - PALMA.x) if i == 1 else PALMA.x
			for k in range(2):
				var mano: Sprite2D = _manos[i][k]
				var palma_y := (80.0 - PALMA.y) if k == 1 else PALMA.y
				var deslizar := gesto * 16.0 * (1.0 if k == 0 else -1.0)
				var agarre: float = agarres.x if i == 0 else agarres.y
				var deriva: float = derivas.x if i == 0 else derivas.y
				# Fuera del palo las palmas se abren; los brazos se van arriba o abajo.
				var abre := lerpf(ABIERTAS, APRIETE, agarre)
				# Brazos de borracho: tiemblan, menos con el clic sostenido.
				var temblor := 1.5 if firmes[i] else 4.0
				var sacudida := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * temblor
				var junto := Vector2(x_huso + deslizar, alturas[i] + deriva * 70.0 + (abre if k == 1 else -abre)) + sacudida
				mano.position = junto - Vector2(palma_x, palma_y) * ESCALA_MANOS
				(mano.material as ShaderMaterial).set_shader_parameter("color_jugador", colores[i])
		# La punta y la tabla se ponen al rojo con el calor.
		var brasa := Color(1, 1, 1).lerp(Color(1.35, 0.85, 0.6), calor)
		_huso.modulate = brasa
		(_huso.material as ShaderMaterial).set_shader_parameter("tinte", brasa)
		_tabla.modulate = brasa
		_fuego.visible = calor > 0.5
		var tamano := lerpf(0.6, 2.4, clampf((calor - 0.5) / 0.5, 0, 1))
		_fuego.scale = Vector2.ONE * tamano
		_fuego.position = CRUCE + Vector2(-48.0 * tamano, 20.0 - 52.0 * tamano)
		_encima.queue_redraw()
		queue_redraw()


	func _draw() -> void:
		# Resplandor donde la punta frota la tabla (entre el fondo y los palos).
		if calor > 0.02:
			for i in range(5):
				var r := 30.0 + i * 22.0
				draw_circle(CRUCE + Vector2(0, 12), r * (0.5 + calor * 0.8), Color(1, 0.55, 0.15, calor * 0.12 * (1.0 - i * 0.17)))


	# Chispas y humo donde la punta frota la tabla.
	func _chispas() -> void:
		if calor <= 0.03:
			return
		var punto := CRUCE + Vector2(0, 12)
		for i in range(14):
			var fase := fmod(reloj * (1.2 + (i % 3) * 0.3) + i * 0.071, 1.0)
			var sitio := punto + Vector2(sin(i * 14.0 + reloj) * fase * 70.0, -fase * 150.0)
			var lado := 4.0 if i % 3 == 0 else 3.0
			var color := Color(1, 0.85, 0.3) if i % 2 == 0 else Color(1, 0.5, 0.15)
			color.a = calor * (1.0 - fase)
			_encima.draw_rect(Rect2(sitio.round(), Vector2(lado, lado)), color)
		for i in range(6):
			var fase := fmod(reloj * 0.35 + i * 0.17, 1.0)
			var sitio := punto + Vector2(sin(i * 2.0 + fase * 4.0) * 30.0, -10.0 - fase * 200.0)
			_encima.draw_circle(sitio, 12.0 + fase * 26.0, Color(0.82, 0.8, 0.72, calor * 0.22 * (1.0 - fase)))
