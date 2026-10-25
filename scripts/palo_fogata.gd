extends Node2D
## Palo de misión en el suelo: la recogida la decide Fogata, nunca este dibujo.
var caida := 70.0


func _ready() -> void:
	var texto := Label.new()
	texto.text = "E · PALO"
	texto.position = Vector2(-31, -37)
	texto.add_theme_font_size_override("font_size", 12)
	texto.add_theme_color_override("font_shadow_color", Color.BLACK)
	texto.add_theme_constant_override("shadow_offset_x", 1)
	texto.add_theme_constant_override("shadow_offset_y", 1)
	add_child(texto)


func _process(delta: float) -> void:
	caida = maxf(0, caida - delta * 160)
	queue_redraw()


func _draw() -> void:
	_dibujar_sombra()
	var a := Vector2(-18, -6 - caida)
	var b := Vector2(19, -12 - caida)
	draw_line(a, b, Color("29180f"), 9)
	draw_line(a, b, Color("9e6635"), 5)
	draw_line(a + Vector2(0, -2), b + Vector2(0, -2), Color("d59b55"), 2)
	draw_line(Vector2(4, -10 - caida), Vector2(12, -19 - caida), Color("744425"), 4)


func _dibujar_sombra() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 21, Color(0, 0, 0, 0.23))
	draw_set_transform(Vector2.ZERO)
