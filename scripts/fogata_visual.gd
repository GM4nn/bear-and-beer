extends Node2D
## Humo y chispas cosméticos, sin red ni daño.
var tiempo := 0.0


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	for i in range(5):
		var fase := fmod(tiempo * 0.22 + i * 0.2, 1.0)
		var sitio := Vector2(roundf(sin(fase * 5.0 + i) * 9), -48 - roundf(fase * 72))
		var tamano := 4 + floorf(fase * 4) * 2
		draw_rect(Rect2(sitio, Vector2.ONE * tamano), Color(0.73, 0.78, 0.67, (1 - fase) * 0.35))
	for i in range(3):
		var fase := fmod(tiempo * 0.65 + i * 0.33, 1.0)
		draw_rect(Rect2(Vector2(sin(fase * 6 + i) * 12, -26 - fase * 50).round(), Vector2(2, 3)),
			Color(1, 0.73, 0.3, 1 - fase))
