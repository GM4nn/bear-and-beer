extends Node2D
## Impacto de tinta: destello blanco y trazos negros radiales, sin palabras.
var tipo := 0
var critico := false
var tiempo := 0.0
var duracion := 0.24


func _ready() -> void:
	z_index = 50
	duracion = 0.34 if critico else 0.24
	rotation = -0.10 if tipo % 2 == 0 else 0.10
	add_to_group("impactos_comic")


func _process(delta: float) -> void:
	tiempo += delta
	if tiempo >= duracion:
		queue_free()
		return
	var entrada := minf(tiempo / 0.07, 1.0)
	var tamano := lerpf(0.35, 1.0, 1.0 - pow(1.0 - entrada, 3))
	scale = Vector2.ONE * tamano
	modulate.a = 1.0 - clampf((tiempo - duracion * 0.65) / (duracion * 0.35), 0, 1)
	queue_redraw()


func _borde(radio: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in range(80):
		var angulo := TAU * i / 80.0
		var largo := 0.60 + 0.16 * absf(sin(i * 7.13 + tipo))
		puntos.append(Vector2.from_angle(angulo) * radio * largo)
	return puntos


func _draw() -> void:
	var radio := 49.0 if critico else 33.0
	var borde := _borde(radio)
	draw_colored_polygon(borde, Color(1, 1, 1, 0.82))
	var cerrado := borde.duplicate()
	cerrado.append(borde[0])
	draw_polyline(cerrado, Color.WHITE, 3)
	draw_polyline(cerrado, Color("171719"), 1)
	# Grupos irregulares de trazos finos, como tinta raspada hacia fuera.
	for i in range(34):
		var angulo := TAU * i / 34.0 + sin(i * 5.2) * 0.045
		var rayo := Vector2.from_angle(angulo)
		var tangente := rayo.orthogonal()
		var interior := radio * (0.66 + 0.12 * absf(sin(i * 3.7)))
		var exterior := radio * (0.93 + 0.32 * absf(cos(i * 2.3 + tipo)))
		var inicio := rayo * interior
		var punta := rayo * exterior
		draw_line(inicio, punta, Color.WHITE, 3)
		draw_line(inicio, punta, Color("171719"), 1)
		draw_line(inicio + tangente * 2, punta * 0.94 + tangente, Color("171719"), 1)
		if i % 3 == 0:
			draw_line(punta * 1.08, punta * 1.15 + tangente * 2, Color("171719"), 1)
