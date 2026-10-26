extends SceneTree
## Geometría y validación del círculo completo, con muestras retrasadas y a 20 Hz.
var casos := 0
var fallos := 0

class Rescate extends Node:
	var rescatados := 0
	var participantes: Array = [1]
	var estado := "ritmo"
	var encuentro := 1
	var paso := 0
	var tiempo := 0.0
	var avances: Array = [0.0]
	var miedo := 0.0
	var calma := 0.0
	var finalizada := false
	func _partida() -> Node:
		return self
	func _fallar(_rasguno: bool, _ids: Array = []) -> void:
		estado = "fallo"
	func completar_reto() -> void:
		estado = "completo"

func _initialize() -> void:
	call_deferred("probar")

func comprobar(ok: bool, descripcion: String) -> void:
	casos += 1
	if not ok:
		fallos += 1
	print(("OK: " if ok else "FALLO: ") + descripcion)

func probar() -> void:
	var r := Rescate.new()
	root.add_child(r)
	var reto = load("res://scripts/reto_rescate.gd").new()
	r.add_child(reto)
	reto.set_process(false)
	reto.set_physics_process(false)
	for cria in 2:
		r.rescatados = cria
		var iguales := true
		var interior := true
		var exterior := true
		var antes_rechazados := 0
		for paso in 6:
			for muestra in 21:
				var u := muestra / 20.0
				var centro: Vector2 = reto.objetivo(paso, 0, u)
				var t: float = reto.aviso() + u * reto.duracion()
				for piso in 6:
					iguales = iguales and centro.is_equal_approx(reto.objetivo(paso, piso, u))
				for lado in 16:
					var direccion := Vector2.from_angle(lado * TAU / 16)
					var punto: Vector2 = centro + direccion * (reto.radio() - 1) / reto.LIENZO
					interior = interior and reto.contiene_cursor(paso, 0, t, punto)
					interior = interior and reto.contiene_cursor(paso, 0, t, centro + direccion * (reto.radio() + 1.9) / reto.LIENZO)
					exterior = exterior and not reto.contiene_cursor(paso, 0, t, centro + direccion * (reto.radio() + 4) / reto.LIENZO)
					var viejo: Vector2 = reto.objetivo(paso, 0, clampf((t - reto.aviso() - 0.08) / reto.duracion(), 0, 1))
					if ((punto - viejo) * reto.LIENZO).length() > reto.radio():
						antes_rechazados += 1
		comprobar(iguales, "Osezno %d: los seis puestos ven exactamente la misma trayectoria" % (cria + 1))
		comprobar(interior and exterior, "Osezno %d: interior y contorno válidos, exterior inválido en todos los recorridos" % (cria + 1))
		comprobar(antes_rechazados > 0, "Osezno %d: reproduce y corrige %d falsos fallos del desfase anterior" % [cria + 1, antes_rechazados])
		for retraso in [0.0, 0.12, 0.25]:
			r.estado = "ritmo"
			r.paso = 0
			r.tiempo = 0
			r.encuentro += 1
			reto.iniciar()
			root.get_node("Red").latencias[1] = 250
			for cuadro in 1200:
				r.tiempo += 1.0 / 60
				if cuadro % 3 == 0:
					var visto: float = maxf(0, r.tiempo - retraso)
					var u: float = clampf((visto - reto.aviso()) / reto.duracion(), 0, 1)
					var cursor: Vector2 = reto.objetivo(r.paso, 0, u) + Vector2.from_angle(cuadro * 0.04) * (reto.radio() - 1) / reto.LIENZO
					reto.mover(r.encuentro, r.paso, cuadro, cursor, true, visto)
				reto._physics_process(1.0 / 60)
				if r.estado != "ritmo":
					break
			comprobar(r.estado == "completo", "Osezno %d: completa los seis objetivos por el borde con %d ms de retraso" % [cria + 1, retraso * 1000])
	r.estado = "ritmo"
	r.paso = 0
	r.tiempo = 1.5
	reto.iniciar()
	var centro: Vector2 = reto.objetivo(0, 0, 0.5)
	reto.mover(r.encuentro, 0, 1, centro, true, NAN)
	reto.mover(r.encuentro, 0, 2, centro, true, 99)
	reto.mover(r.encuentro, 0, 3, centro, true, 0)
	comprobar(reto.entradas[1].secuencia == -1, "Rechaza reloj inválido, futuro y demasiado antiguo")
	reto.mover(r.encuentro, 0, 4, centro, true, 1.4)
	reto.mover(r.encuentro, 0, 5, centro, true, 1.3)
	comprobar(reto.entradas[1].secuencia == 4, "No permite retroceder el reloj para elegir otro punto del camino")
	r.estado = "preparando"
	r.tiempo = 2.9
	reto.iniciar()
	centro = reto.objetivo(0, 0, 0)
	reto.mover(r.encuentro, 0, 1, centro, true, 2.9)
	comprobar(reto.entradas[1].dentro, "La cuenta atrás mantiene el círculo en su posición inicial")
	r.estado = "ritmo"
	r.tiempo = 0.05
	reto.mover(r.encuentro, 0, 2, centro, true, 0.02)
	comprobar(reto.entradas[1].secuencia == 2 and reto.entradas[1].dentro, "Acepta el reinicio del reloj al terminar la cuenta atrás")
	root.get_node("Red").latencias.clear()
	r.queue_free()
	print("RESULTADO CÍRCULO: %d comprobaciones, %d fallos" % [casos, fallos])
	quit(1 if fallos else 0)
