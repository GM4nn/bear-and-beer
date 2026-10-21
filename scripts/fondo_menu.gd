extends TextureRect
## Conserva el dibujo original. Ambiente y personajes tienen relojes independientes.
## Nunca se reemplazan rectángulos completos por cuadros aleatorios del paisaje.
const LIENZO := Vector2(256, 144)
const POS_BOLSA := Vector2(2, 104)
const POS_SILLA := Vector2(34, 58)
const POS_TRONCO := Vector2(160, 74)
const CABEZA_DORMIDO := Vector2(16, 104)
const FONDO := preload("res://arte/ui/menu/fondo.png")
const BOLSA := preload("res://arte/ui/menu/bolsa.png")
const SILLA := preload("res://arte/ui/menu/silla.png")
# Comisura señalada en la referencia del usuario, medida sobre el sprite 48×64.
## Comisura de la boca del de la silla (de ahí cuelga la baba).
const BOCA_SILLA := POS_SILLA + Vector2(18.1, 18.6)
var _tronco_cuadros: Array[Texture2D] = []
var _tiempo := 0.0
var _ambiente: TextureRect
var _personajes: Node2D
var _material: ShaderMaterial


func _ready() -> void:
	# El shader no debe deformar personas, letras ni muebles.
	texture = null
	_ambiente = TextureRect.new()
	_ambiente.texture = FONDO
	_ambiente.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ambiente.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ambiente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ambiente.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://arte/ui/menu/ambiente.gdshader")
	_ambiente.material = _material
	add_child(_ambiente)
	_personajes = Node2D.new()
	add_child(_personajes)
	_personajes.draw.connect(_dibujar_personajes)
	_tronco_cuadros = _cargar("tronco")


func _cargar(nombre: String) -> Array[Texture2D]:
	var lista: Array[Texture2D] = []
	var patron := "res://arte/ui/menu/" + nombre + "_anim/%d.png"
	var n := 0
	while ResourceLoader.exists(patron % n):
		lista.append(load(patron % n))
		n += 1
	if lista.is_empty():
		lista.append(load("res://arte/ui/menu/%s.png" % nombre))
	return lista


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_tiempo += delta
	_material.set_shader_parameter("tiempo", _tiempo)
	_personajes.queue_redraw()


func _dibujar_personajes() -> void:
	var escala: float = maxf(size.x / LIENZO.x, size.y / LIENZO.y)
	var origen: Vector2 = (size - LIENZO * escala) / 2
	_dibujar_brasas(escala, origen)
	# Los dos dormidos quedan completamente quietos; solo se mueven baba y Z.
	_figura(BOLSA, POS_BOLSA, escala, origen)
	_figura(SILLA, POS_SILLA, escala, origen)
	_dibujar_baba(escala, origen)
	_figura(_tronco_cuadros[_cuadro_trago()], POS_TRONCO, escala, origen)
	_dibujar_z(escala, origen)


func _cuadro_trago() -> int:
	# Bajar, descansar, subir y sostener el sorbo. Ida/vuelta sin salto al inicio.
	var ultimo := _tronco_cuadros.size() - 1
	if ultimo <= 0:
		return 0
	var fase := fmod(_tiempo, 7.6)
	if fase < 1.2:
		return 0
	if fase < 2.8:
		return mini(int((fase - 1.2) / 1.6 * (ultimo + 1)), ultimo)
	if fase < 5.8:
		return ultimo
	return maxi(ultimo - int((fase - 5.8) / 1.8 * (ultimo + 1)), 0)


func _figura(dibujo: Texture2D, pos: Vector2, escala: float, origen: Vector2) -> void:
	_personajes.draw_texture_rect(dibujo, Rect2(origen + pos * escala, dibujo.get_size() * escala), false)


func _dibujar_baba(escala: float, origen: Vector2) -> void:
	# Un hilo de baba siempre colgando de la comisura: solo se estira y se encoge
	# despacio (arriba y abajo), como si ya fuera a caer; la gota nunca se suelta.
	var estiron := 0.5 + 0.5 * sin(_tiempo * 0.9)
	var largo := lerpf(4.5, 8.0, estiron * estiron)
	var punta := BOCA_SILLA + Vector2(0, largo)
	var baba := Color(0.78, 0.86, 0.8, 0.82)
	var hilo := PackedVector2Array([origen + BOCA_SILLA * escala, origen + punta * escala])
	_personajes.draw_polyline(hilo, baba, maxf(1.5, escala * 0.55))
	# Gota grande colgando, más llena cuando el hilo está más estirado.
	var radio := lerpf(1.1, 1.6, estiron)
	var gota := PackedVector2Array()
	for vertice: Vector2 in [Vector2(0, -0.9), Vector2(-0.6, -0.2), Vector2(-0.75, 0.45),
			Vector2(-0.4, 0.95), Vector2(0.4, 0.95), Vector2(0.75, 0.45), Vector2(0.6, -0.2)]:
		gota.append(origen + (punta + vertice * radio) * escala)
	_personajes.draw_colored_polygon(gota, baba)
	# Brillito para que se lea como líquido.
	var brillo := origen + (punta + Vector2(-0.35, -0.1) * radio) * escala
	_personajes.draw_rect(Rect2(brillo, Vector2.ONE * maxf(1.0, escala * 0.45)), Color(1, 1, 1, 0.85))


func _dibujar_brasas(escala: float, origen: Vector2) -> void:
	for k in 5:
		var fase := fmod(_tiempo / (2.4 + k * 0.37) + k * 0.21, 1.0)
		var punto := Vector2(220 + sin(fase * 4.0 + k * 2.1) * (2 + fase * 5), 103 - fase * 28)
		_personajes.draw_rect(Rect2(origen + punto.floor() * escala, Vector2.ONE * escala), Color(1, 0.65, 0.22, sin(fase * PI) * 0.65))


func _dibujar_z(escala: float, origen: Vector2) -> void:
	var letra := TemaUI.fuente("bold")
	for k in 3:
		var fase := fmod(_tiempo * 0.28 + k / 3.0, 1.0)
		var punto := origen + (CABEZA_DORMIDO + Vector2(4 + fase * 6, -4 - fase * 18)) * escala
		var tamano := int(lerpf(18, 30, fase) * escala / 5.0)
		var alfa := sin(fase * PI) * 0.8
		_personajes.draw_string_outline(letra, punto, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, 4, Color(0.17, 0.09, 0.04, alfa))
		_personajes.draw_string(letra, punto, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, Color(1, 0.95, 0.8, alfa))
