extends RefCounted
## Sprites compartidos, anclados por los pies; no modifica lógica ni colisiones.

static func estatico(nombre: String, escala := 2.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://arte/zona1/objetos/%s.png" % nombre)
	sprite.centered = false
	var area := sprite.texture.get_image().get_used_rect()
	sprite.offset = Vector2(-area.get_center().x, -area.end.y)
	sprite.scale = Vector2.ONE * escala
	return sprite


static func animado(carpetas: Dictionary, escala := 2.0, fps := 8.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var cuadros := SpriteFrames.new()
	cuadros.remove_animation("default")
	var base: Texture2D
	for anim: String in carpetas:
		cuadros.add_animation(anim)
		cuadros.set_animation_speed(anim, fps)
		cuadros.set_animation_loop(anim, true)
		var i := 0
		while ResourceLoader.exists("%s/%d.png" % [carpetas[anim], i]):
			var textura: Texture2D = load("%s/%d.png" % [carpetas[anim], i])
			cuadros.add_frame(anim, textura)
			if base == null:
				base = textura
			i += 1
	sprite.sprite_frames = cuadros
	sprite.centered = false
	if base != null:
		var area := base.get_image().get_used_rect()
		sprite.offset = Vector2(-area.get_center().x, -area.end.y)
	sprite.scale = Vector2.ONE * escala
	sprite.play(carpetas.keys()[0])
	return sprite
