extends Control
## Indicadores por jugador y resultados compartidos de la Zona 1.

signal volver_sala
signal salir

var _tarjetas: Dictionary = {}
var _fila: HBoxContainer
var _resultado: ColorRect
var _conexion: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conexion = Label.new()
	_conexion.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_conexion.offset_left = -320
	_conexion.offset_right = -16
	_conexion.offset_top = 12
	_conexion.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_conexion.add_theme_font_size_override("font_size", 12)
	_conexion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_conexion)
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
	var conexiones := PackedStringArray()
	for id in Red.jugadores:
		conexiones.append("%s · %s" % [Red.jugadores[id].nombre, Red.texto_conexion(id)])
	_conexion.text = "\n".join(conexiones)
	var ids := []
	for j in get_tree().get_nodes_in_group("jugadores"):
		# Solo la tarjeta del que juega en esta pantalla.
		if not j.is_multiplayer_authority():
			continue
		ids.append(j.name)
		if not _tarjetas.has(j.name):
			_crear_tarjeta(j)
		var tarjeta: Dictionary = _tarjetas[j.name]
		tarjeta.vida.value = j.vida
		tarjeta.borracho.value = j.borrachera
		tarjeta.chelas.text = "×%d" % j.cervezas
		tarjeta.botellas.text = "×%d" % j.botellas
		# Solo qué tan borracho va; las acciones (rodar, parar, trepar…) ya se ven
		# en el personaje y las teclas están en Opciones.
		tarjeta.estado.text = j.NIVELES[j.nivel_borrachera()]
		var avisos: Array[String] = []
		var fogata := get_tree().get_first_node_in_group("fogata_cooperativa")
		if fogata != null and fogata.cantidad(j.name.to_int()) > 0:
			avisos.append("PALOS ×%d/2" % fogata.cantidad(j.name.to_int()))
		if j.arma_tiempo > 0:
			avisos.append("AGUIJÓN · %ds · daño +50%%" % ceili(j.arma_tiempo))
		if j.combo.paso > 0:
			avisos.append("COMBO %d/4" % j.combo.paso)
		if not j.aviso_bebida().is_empty():
			avisos.append(j.aviso_bebida())
		tarjeta.detalle.text = "\n".join(avisos)
		tarjeta.detalle.visible = not avisos.is_empty()
		# El retrato parpadea en rojo al recibir daño.
		if j.vida < tarjeta.vida_vista:
			tarjeta.golpe = 0.25
		tarjeta.vida_vista = j.vida
		tarjeta.golpe = maxf(tarjeta.golpe - get_process_delta_time(), 0.0)
		tarjeta.retrato.modulate = Color(1, 0.45, 0.45) if tarjeta.golpe > 0.0 else Color.WHITE
	for id in _tarjetas.keys():
		if id not in ids:
			_tarjetas[id].panel.queue_free()
			_tarjetas.erase(id)
	_fila.position = Vector2(16, 12)


## Tarjeta compacta, al estilo de Castle Crashers: retrato redondo del jugador
## con su color, nombre y estado, barras delgadas de vida y borrachera, y chelas
## y botellas en chiquito. Sin placa de fondo para no tapar el bosque.
func _crear_tarjeta(j: Node) -> void:
	var panel := HBoxContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_constant_override("separation", 8)
	_fila.add_child(panel)
	var medallon := Medallon.new()
	medallon.color = j.COLORES[j.color_indice % j.COLORES.size()]
	medallon.custom_minimum_size = Vector2(64, 64)
	medallon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(medallon)
	var retrato := TextureRect.new()
	var cara := AtlasTexture.new()
	cara.atlas = RETRATO
	cara.region = Rect2(68, 24, 52, 52)
	retrato.texture = cara
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retrato.offset_left = 7
	retrato.offset_top = 7
	retrato.offset_right = -7
	retrato.offset_bottom = 7
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# La playera se pinta del color del jugador, igual que su personaje.
	var material := ShaderMaterial.new()
	material.shader = COLOR_JUGADOR
	material.set_shader_parameter("color_jugador", medallon.color)
	retrato.material = material
	medallon.add_child(retrato)
	# El aro va encima del retrato, que queda recortado dentro del círculo.
	var aro := Aro.new()
	aro.color = medallon.color
	aro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medallon.add_child(aro)
	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_theme_constant_override("separation", 3)
	columna.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(columna)
	var cabecera := _renglon(columna)
	var nombre := _texto(j.nombre, 15)
	nombre.add_theme_font_override("font", TemaUI.fuente("bold"))
	cabecera.add_child(nombre)
	var estado := _texto("", 12)
	estado.add_theme_color_override("font_color", Color("ffd36b"))
	estado.size_flags_vertical = Control.SIZE_SHRINK_END
	cabecera.add_child(estado)
	var vida := _barra(Color("e04a3c"), 150, 10)
	columna.add_child(vida)
	var borracho := _barra(Color("f2a93b"), 120, 6)
	columna.add_child(borracho)
	var inventario := _renglon(columna)
	inventario.add_child(_icono(ICONO_CHELA))
	var chelas := _texto("", 14)
	inventario.add_child(chelas)
	inventario.add_child(_icono(ICONO_BOTELLA))
	var botellas := _texto("", 14)
	inventario.add_child(botellas)
	var detalle := _texto("", 12)
	detalle.add_theme_color_override("font_color", Color("ffd36b"))
	columna.add_child(detalle)
	_tarjetas[j.name] = {"panel": panel, "vida": vida, "borracho": borracho, "detalle": detalle,
		"chelas": chelas, "botellas": botellas, "estado": estado, "retrato": retrato,
		"vida_vista": j.vida, "golpe": 0.0}


const ICONO_CHELA := preload("res://arte/ui/icono_chela.png")
const ICONO_BOTELLA := preload("res://arte/ui/icono_botella.png")
const RETRATO := preload("res://arte/jugador/quieto/0.png")
const COLOR_JUGADOR := preload("res://arte/jugador/color_jugador.gdshader")
const TINTA_BORDE := Color("1d120c")


## Círculo de fondo del retrato; recorta a sus hijos con su propia forma.
class Medallon extends Control:
	var color := Color.WHITE

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW

	func _draw() -> void:
		var centro := size * 0.5
		var radio := minf(size.x, size.y) * 0.5
		draw_circle(centro, radio, Color("fff3d6"))
		draw_circle(centro + Vector2(0, radio * 0.3), radio * 0.8, color.lightened(0.55))


## Aro del color del jugador con contorno oscuro, encima del retrato.
class Aro extends Control:
	var color := Color.WHITE

	func _draw() -> void:
		var centro := size * 0.5
		var radio := minf(size.x, size.y) * 0.5
		draw_arc(centro, radio - 4.5, 0, TAU, 48, color.darkened(0.1), 5.0, true)
		draw_arc(centro, radio - 1, 0, TAU, 48, Color("1d120c"), 2.5, true)
		draw_arc(centro, radio - 8, 0, TAU, 48, Color("1d120c"), 2.0, true)


func _renglon(padre: Control) -> HBoxContainer:
	var renglon := HBoxContainer.new()
	renglon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	renglon.add_theme_constant_override("separation", 6)
	padre.add_child(renglon)
	return renglon


func _icono(textura: Texture2D) -> TextureRect:
	var icono := TextureRect.new()
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.custom_minimum_size = Vector2(26, 26)
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icono


## Barra delgada con borde oscuro (la canaleta también oscura).
func _barra(color: Color, ancho: float, alto: float) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(ancho, alto)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.11, 0.07, 0.05, 0.85)
	fondo.border_color = TINTA_BORDE
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(2)
	barra.add_theme_stylebox_override("background", fondo)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = color
	lleno.border_color = TINTA_BORDE
	lleno.set_border_width_all(2)
	lleno.border_width_right = 0
	lleno.set_corner_radius_all(2)
	barra.add_theme_stylebox_override("fill", lleno)
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
	_resultado.color = Color(0.06, 0.03, 0.02, 0.72)
	_resultado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_resultado)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	_resultado.add_child(margen)
	# Letrero grande de madera con papel picado (tema cantina).
	var letrero := PanelContainer.new()
	letrero.add_theme_stylebox_override("panel", TemaUI.panel_letrero())
	margen.add_child(letrero)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	letrero.add_child(columna)
	var encabezado_final := _texto("¡RECUPERARON LAS CHELAS!" if victoria else "SE NOS CAYÓ TODO EL EQUIPO", 32)
	encabezado_final.add_theme_font_override("font", TemaUI.fuente("bold"))
	encabezado_final.add_theme_color_override("font_color", Color("ffd36b"))
	columna.add_child(encabezado_final)
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
