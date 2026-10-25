extends Polygon2D
## Extensión articulada con la tela existente; no estira los píxeles de la garra.
var _contorno: Polygon2D


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_contorno = Polygon2D.new()
	_contorno.color = Color("180c19")
	_contorno.show_behind_parent = true
	add_child(_contorno)


func colocar(inicio: Vector2, fin: Vector2, ancho_inicio: float, ancho_fin: float, curva: float, horizontal := false) -> void:
	var eje := (fin - inicio).normalized()
	var normal := Vector2(-eje.y, eje.x)
	var control := (inicio + fin) * 0.5 + normal * curva
	var a := PackedVector2Array()
	var b := PackedVector2Array()
	var borde_a := PackedVector2Array()
	var borde_b := PackedVector2Array()
	var uv_a := PackedVector2Array()
	var uv_b := PackedVector2Array()
	var distancia := 0.0
	var anterior := inicio
	for i in range(13):
		var t := i / 12.0
		var centro := inicio.lerp(control, t).lerp(control.lerp(fin, t), t)
		distancia += centro.distance_to(anterior)
		anterior = centro
		# Las secciones conservan la orientación de la costura del sprite.
		var transversal := Vector2.DOWN if horizontal else Vector2.RIGHT
		var radio := lerpf(ancho_inicio, ancho_fin, smoothstep(0, 1, t)) * 0.5
		a.append((centro - transversal * radio).round())
		b.append((centro + transversal * radio).round())
		borde_a.append((centro - transversal * (radio + 1.5)).round())
		borde_b.append((centro + transversal * (radio + 1.5)).round())
		uv_a.append(Vector2(distancia, 0) if horizontal else Vector2(0, distancia))
		uv_b.append(Vector2(distancia, radio * 2) if horizontal else Vector2(radio * 2, distancia))
	b.reverse()
	borde_b.reverse()
	uv_b.reverse()
	a.append_array(b)
	borde_a.append_array(borde_b)
	uv_a.append_array(uv_b)
	polygon = a
	uv = uv_a
	_contorno.polygon = borde_a
