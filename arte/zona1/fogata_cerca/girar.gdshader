shader_type canvas_item;
// Hace girar un palo sobre su propio eje: la corteza de adentro (entre las filas
// `desde` y `hasta` del dibujo) se recorre como si fuera un cilindro. `giro`
// avanza 1 por vuelta completa. El contorno de arriba y abajo no se mueve.
uniform float giro = 0.0;
// Tono de brasa (la punta se pone al rojo con el calor).
uniform vec4 tinte : source_color = vec4(1.0);
uniform float desde = 0.3125; // fila 10 de 32
uniform float hasta = 0.78125; // fila 25 de 32

void fragment() {
	vec2 uv = UV;
	if (uv.y > desde && uv.y < hasta) {
		float n = (uv.y - desde) / (hasta - desde);
		// Posición alrededor del cilindro (0 a 1) que se ve en esta fila.
		float vuelta = asin(clamp(n * 2.0 - 1.0, -1.0, 1.0)) / PI + 0.5;
		vuelta = fract(vuelta * 0.5 + giro);
		// La mitad de atrás no se ve: se dobla sobre la de enfrente.
		float frente = vuelta < 0.5 ? vuelta * 2.0 : 2.0 - vuelta * 2.0;
		float n2 = (sin((frente - 0.5) * PI) + 1.0) * 0.5;
		uv.y = desde + n2 * (hasta - desde);
		vec4 color = texture(TEXTURE, uv);
		// Sombra de cilindro: más oscuro hacia las orillas.
		float luz = 0.72 + 0.38 * sin(n * PI);
		COLOR = vec4(color.rgb * luz * tinte.rgb, color.a);
	}
}
