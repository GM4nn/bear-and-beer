class_name TemaUI
## Estilo de la interfaz: cómic de cantina mexicana (madera, cerveza y papel picado).
## Las piezas vienen de PixelLab (arte/ui) y se estiran en 9 partes sin deformar
## las esquinas; los márgenes se midieron sobre cada PNG.

const CREMA := Color("fff3d6")
const CAFE_OSCURO := Color("2b160b")
const AMBAR := Color("f2a93b")
const MADERA_OSCURA := Color("3a2416")

## Lista de controles: se muestra en Opciones (menú y pausa), no durante la partida.
const CONTROLES := "Mover: WASD / stick   ·   Saltar: Espacio   ·   Rodar: Shift\n" + \
	"Puño derecho: H   ·   Puño izquierdo: J\n" + \
	"Cabezazo: K   ·   Patada: L   ·   Parada: F\n" + \
	"Recoger chelas y piezas / soltar pieza: E   ·   Beber: Q\n" + \
	"Levantar a un compa caído: mantén E   ·   Subir a hombros: salta y E\n" + \
	"Apuntar botella: mantén R y suelta\n" + \
	"Lanzar compa desde la torre: R   ·   Pausa: Esc"

const PANEL := preload("res://arte/ui/panel_letrero.png")
const PLACA := preload("res://arte/ui/placa.png")
const BOTON := preload("res://arte/ui/boton.png")
const BARRA := preload("res://arte/ui/barra.png")

static var _tema: Theme
static var _fuentes: Dictionary = {}


static func tema() -> Theme:
	if _tema == null:
		_preparar_fuentes()
		_tema = _crear()
	return _tema


## Letra pixel de PixelLab: "bold" para títulos y botones, "regular" para el resto.
static func fuente(cual: String) -> Font:
	_preparar_fuentes()
	return _fuentes[cual]


## Las letras de PixelLab no traen acentos, ñ, ¡ ni ¿: esas se toman de la letra
## original de Godot. La regular se vuelve la letra por defecto de todo el juego
## (también nombres y avisos sobre los personajes, y los POW! de los golpes).
static func _preparar_fuentes() -> void:
	if not _fuentes.is_empty():
		return
	var original: Font = ThemeDB.fallback_font
	for cual in ["bold", "regular"]:
		var letra: FontFile = load("res://arte/ui/fuentes/cantina_%s.ttf" % cual).duplicate()
		letra.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		letra.hinting = TextServer.HINTING_NONE
		letra.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		letra.fallbacks = [original]
		_fuentes[cual] = letra
	ThemeDB.fallback_font = _fuentes["regular"]


## Letrero grande de madera con papel picado (menús, sala, resultados).
static func panel_letrero() -> StyleBoxTexture:
	return _textura(PANEL, [71, 73, 72, 67], [62, 66, 62, 56])


## Placa con espuma para las tarjetas de cada jugador (fondo crema, texto oscuro).
static func placa() -> StyleBoxTexture:
	# La parte crema empieza a 47 px de los lados, 50 arriba (espuma) y 40 abajo.
	return _textura(PLACA, [47, 50, 47, 40], [50, 50, 50, 40])


## Marco de madera para barras grandes (la vida de Mamá Osa).
static func marco_barra() -> StyleBoxTexture:
	var estilo := _textura(BARRA, [48, 12, 48, 10], [0, 0, 0, 0])
	# Sin el centro: la canaleta y el relleno de la barra se ven a través del marco.
	estilo.draw_center = false
	return estilo


## Espacio libre dentro de marco_barra (la canaleta oscura).
const HUECO_BARRA := [46, 11, 46, 9]


static func _textura(textura: Texture2D, margen: Array, contenido: Array) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = textura
	estilo.texture_margin_left = margen[0]
	estilo.texture_margin_top = margen[1]
	estilo.texture_margin_right = margen[2]
	estilo.texture_margin_bottom = margen[3]
	estilo.content_margin_left = contenido[0]
	estilo.content_margin_top = contenido[1]
	estilo.content_margin_right = contenido[2]
	estilo.content_margin_bottom = contenido[3]
	return estilo


static func _plano(fondo: Color, borde: Color, grosor := 3, radio := 6) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(radio)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	return estilo


static func _crear() -> Theme:
	var t := Theme.new()
	t.default_font = _fuentes["regular"]
	t.default_font_size = 16

	# Textos: crema con contorno café, como letrero pintado a mano.
	t.set_color("font_color", "Label", CREMA)
	t.set_color("font_outline_color", "Label", CAFE_OSCURO)
	t.set_constant("outline_size", "Label", 5)

	# Botones: tablón con corcholatas; al pasar encima se ilumina y al apretar se oscurece.
	var normal := _textura(BOTON, [20, 10, 20, 10], [30, 7, 30, 7])
	var encima := normal.duplicate()
	encima.modulate_color = Color(1.18, 1.12, 1.0)
	var apretado := normal.duplicate()
	apretado.modulate_color = Color(0.78, 0.74, 0.7)
	var apagado := normal.duplicate()
	apagado.modulate_color = Color(0.55, 0.55, 0.55, 0.8)
	for tipo in ["Button", "CheckButton", "OptionButton"]:
		t.set_stylebox("normal", tipo, normal)
		t.set_stylebox("hover", tipo, encima)
		t.set_stylebox("pressed", tipo, apretado)
		t.set_stylebox("hover_pressed", tipo, apretado)
		t.set_stylebox("disabled", tipo, apagado)
		t.set_stylebox("focus", tipo, StyleBoxEmpty.new())
		t.set_color("font_color", tipo, CREMA)
		t.set_color("font_hover_color", tipo, Color.WHITE)
		t.set_color("font_pressed_color", tipo, Color("ffd889"))
		t.set_color("font_focus_color", tipo, CREMA)
		t.set_color("font_disabled_color", tipo, Color("b9a58a"))
		t.set_color("font_outline_color", tipo, CAFE_OSCURO)
		t.set_constant("outline_size", tipo, 5)
		t.set_font("font", tipo, _fuentes["bold"])
		t.set_font_size("font_size", tipo, 20)

	# Campos de texto: papel crema con borde ámbar.
	var campo := _plano(Color("f3dfb5"), Color("c8841f"))
	var campo_activo := _plano(Color("fff0cc"), AMBAR, 4)
	t.set_stylebox("normal", "LineEdit", campo)
	t.set_stylebox("focus", "LineEdit", campo_activo)
	t.set_stylebox("read_only", "LineEdit", campo)
	t.set_color("font_color", "LineEdit", CAFE_OSCURO)
	t.set_color("font_placeholder_color", "LineEdit", Color("8a6a4a"))
	t.set_color("caret_color", "LineEdit", CAFE_OSCURO)
	t.set_color("selection_color", "LineEdit", Color(0.95, 0.66, 0.23, 0.5))

	# Paneles.
	t.set_stylebox("panel", "PanelContainer", panel_letrero())
	t.set_stylebox("panel", "Panel", panel_letrero())

	# Barras pequeñas (tarjetas): canaleta de madera oscura con borde ámbar.
	t.set_stylebox("background", "ProgressBar", _plano(MADERA_OSCURA, Color("8a5a2b"), 2, 3))
	var llenado := _plano(AMBAR, Color(0, 0, 0, 0), 0, 2)
	t.set_stylebox("fill", "ProgressBar", llenado)

	# Deslizador del volumen: canaleta oscura y parte llena ámbar.
	var riel := _plano(MADERA_OSCURA, Color("8a5a2b"), 2, 4)
	riel.content_margin_top = 4
	riel.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", riel)
	t.set_stylebox("grabber_area", "HSlider", _plano(AMBAR, Color("8a5a2b"), 2, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _plano(Color("ffc45e"), Color("8a5a2b"), 2, 4))
	t.set_color("font_color", "CheckButton", CREMA)
	return t
