shader_type canvas_item;
render_mode unshaded;
// Recolorea el paisaje existente conservando sus píxeles, formas y parallax.
// 0: cielo/montañas, 1: bosque distante, 2: suelo y decoración cercana.
uniform int capa = 2;

void fragment() {
	vec4 tinte = COLOR;
	vec4 original = texture(TEXTURE, UV);
	vec3 c = original.rgb;
	float luz = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 color;
	if (capa == 0) {
		float y = floor(UV.y / TEXTURE_PIXEL_SIZE.y) + 0.5;
		if (c.b > 0.92 && c.g > 0.8) {
			// La parte visible del atlas empieza cerca de la fila 66.
			float horizonte = smoothstep(55.0, 105.0, y);
			vec3 cielo = mix(vec3(0.36, 0.27, 0.44), vec3(0.94, 0.37, 0.16), horizonte);
			float nube = smoothstep(0.48, 0.76, c.r);
			vec3 nubes = mix(vec3(0.62, 0.30, 0.36), vec3(0.94, 0.53, 0.28), horizonte);
			nubes *= 0.88 + 0.12 * smoothstep(0.6, 0.95, c.r);
			color = mix(cielo, nubes, nube);
			// Un solo sol en pantalla: no se duplica al repetir o reflejar el atlas.
			float sol_x = floor((SCREEN_UV.x - 0.73) / SCREEN_PIXEL_SIZE.x / 3.0) * 3.0;
			float sol_y = (y - 91.0) * 3.0;
			float distancia = length(vec2(sol_x, sol_y));
			float halo = (1.0 - smoothstep(40.0, 115.0, distancia)) * 0.18;
			color = mix(color, vec3(1.0, 0.60, 0.24), halo);
			if (distancia < 43.0) {
				color = mix(vec3(1.0, 0.78, 0.35), nubes, nube * 0.24);
			}
		} else {
			// Lejanía malva; siluetas cercanas más oscuras, como en el menú.
			float altura = smoothstep(0.23, 0.84, luz);
			color = mix(vec3(0.20, 0.17, 0.29), vec3(0.52, 0.36, 0.49), altura);
		}
	} else if (capa == 1) {
		color = mix(vec3(0.12, 0.18, 0.18), vec3(0.40, 0.37, 0.32), smoothstep(0.1, 0.68, luz));
	} else {
		// Luz cálida moderada: mantiene verdes y texturas legibles en el camino.
		color = c * vec3(1.08, 0.78, 0.70);
		color = mix(color, vec3(luz * 1.06, luz * 0.76, luz * 0.53), 0.12);
	}
	COLOR = vec4(color, original.a) * tinte;
}
