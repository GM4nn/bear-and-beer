extends RefCounted
## Sprites compartidos, anclados por los pies; no modifica lógica ni colisiones.

## Versión en alta resolución de un dibujo, si existe: misma imagen redibujada
## con más detalle en la carpeta hd/ junto al original. Devuelve [textura, factor]:
## dibujada a escala / factor ocupa lo mismo que el original.
static func hd(ruta: String) -> Array:
	var original: Texture2D = load(ruta)
	var ruta_hd := ruta.get_base_dir().path_join("hd").path_join(ruta.get_file())
	if ResourceLoader.exists(ruta_hd):
		var fina: Texture2D = load(ruta_hd)
		return [fina, float(fina.get_width()) / original.get_width()]
	return [original, 1.0]


## Escala de dibujo; si queda por debajo de 1 se suaviza para no perder líneas.
static func escalar(dibujo: CanvasItem, escala: float) -> void:
	dibujo.scale = Vector2.ONE * escala
	if escala < 1.0:
		dibujo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


static func estatico(nombre: String, escala := 2.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	var fina := hd("res://arte/zona1/objetos/%s.png" % nombre)
	sprite.texture = fina[0]
	sprite.centered = false
	var area := sprite.texture.get_image().get_used_rect()
	sprite.offset = Vector2(-area.get_center().x, -area.end.y)
	escalar(sprite, escala / fina[1])
	return sprite


static func animado(carpetas: Dictionary, escala := 2.0, fps := 8.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var cuadros := SpriteFrames.new()
	cuadros.remove_animation("default")
	var base: Texture2D
	var factor := 1.0
	for anim: String in carpetas:
		cuadros.add_animation(anim)
		cuadros.set_animation_speed(anim, fps)
		cuadros.set_animation_loop(anim, true)
		var i := 0
		while ResourceLoader.exists("%s/%d.png" % [carpetas[anim], i]):
			var fina := hd("%s/%d.png" % [carpetas[anim], i])
			var textura: Texture2D = fina[0]
			cuadros.add_frame(anim, textura)
			if base == null:
				base = textura
				factor = fina[1]
			i += 1
	sprite.sprite_frames = cuadros
	sprite.centered = false
	if base != null:
		var area := base.get_image().get_used_rect()
		sprite.offset = Vector2(-area.get_center().x, -area.end.y)
	escalar(sprite, escala / factor)
	sprite.play(carpetas.keys()[0])
	return sprite
