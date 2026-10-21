extends Control
## Flecha al borde de la pantalla que apunta hacia donde hay que ir (como el
## "GO!" de Castle Crashers). Solo aparece cuando el objetivo no se ve.

## Punto del mundo al que apuntar; con `activa` en false no se dibuja.
var objetivo := Vector2.ZERO
var activa := false
var _tiempo := 0.0
var _angulo := 0.0
const MARGEN := 70.0
const AMBAR := Color("f2a93b")
const CREMA := Color("fff3d6")
const TINTA := Color("1d120c")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_tiempo += delta
	queue_redraw()


func _draw() -> void:
	if not activa:
		return
	# Del mundo a la pantalla con la cámara actual.
	var en_pantalla := get_viewport().canvas_transform * objetivo
	var caja := Rect2(Vector2.ZERO, size).grow(-MARGEN)
	if caja.has_point(en_pantalla):
		return
	var centro := size * 0.5
	var direccion := (en_pantalla - centro).normalized()
	_angulo = direccion.angle()
	# Punto del borde de la caja en esa dirección.
	var escala := INF
	if direccion.x != 0.0:
		escala = minf(escala, absf((caja.size.x * 0.5) / direccion.x))
	if direccion.y != 0.0:
		escala = minf(escala, absf((caja.size.y * 0.5) / direccion.y))
	var punta := centro + direccion * escala
	# Va y viene hacia el objetivo, y parpadea un poco.
	punta += direccion * sin(_tiempo * 7.0) * 6.0
	var brillo := 0.75 + 0.25 * sin(_tiempo * 7.0)
	var forma := PackedVector2Array([Vector2(26, 0), Vector2(0, -22), Vector2(0, -10), Vector2(-24, -10),
		Vector2(-24, 10), Vector2(0, 10), Vector2(0, 22)])
	var transformada := Transform2D(_angulo, punta - direccion * 26.0)
	var puntos := transformada * forma
	var borde := puntos.duplicate()
	borde.append(puntos[0])
	draw_colored_polygon(puntos, AMBAR.lerp(CREMA, 1.0 - brillo))
	draw_polyline(borde, TINTA, 4.0, true)
	# Letrero "¡ÓRALE!" del lado de adentro de la flecha.
	var fuente := TemaUI.fuente("bold")
	var texto := "¡ÓRALE!"
	var tamano := 18
	var medida := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano)
	var pos_texto := punta - direccion * 78.0 - Vector2(medida.x * 0.5, -medida.y * 0.3)
	draw_string_outline(fuente, pos_texto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, 6, TINTA)
	draw_string(fuente, pos_texto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, CREMA)
