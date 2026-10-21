shader_type canvas_item;
render_mode unshaded;
// Coordenadas del arte original, independientes de la resolución de ventana.
uniform float tiempo = 0.0;
const vec2 LIENZO = vec2(256.0, 144.0);

float cielo(vec3 c) {
	// Árboles, cables, faroles y papel picado quedan fijos.
	return step(0.34, c.r) * step(0.21, c.b) * step(c.g * 1.15, c.r);
}

void fragment() {
	// Mantener la cuadrícula original: las ondas no parten un píxel en tiras finas.
	vec2 p = floor(UV * LIENZO) + vec2(0.5);
	vec4 base = texture(TEXTURE, p / LIENZO);
	vec4 color = base;
	// Nubes: movimiento lento dentro de los claros, sin disolver cuadros.
	if (p.y < 32.0 && p.x > 128.0 && p.x < 201.0) {
		float borde = smoothstep(128.0, 136.0, p.x) * (1.0 - smoothstep(194.0, 201.0, p.x));
		borde *= 1.0 - smoothstep(28.0, 32.0, p.y);
		float viento = sin(tiempo * 0.045) * 6.0;
		vec2 uv_cielo = (p - vec2(viento * borde, 0.0)) / LIENZO;
		vec4 nube = texture(TEXTURE, clamp(uv_cielo, vec2(0.002), vec2(0.998)));
		color = mix(base, nube, cielo(base.rgb) * cielo(nube.rgb));
	}
	// Ondas horizontales en las vetas existentes, con reflejo cálido tenue.
	if (p.x > 133.0 && p.x < 201.0 && p.y > 68.0 && p.y < 94.0) {
		float borde = smoothstep(133.0, 140.0, p.x) * (1.0 - smoothstep(195.0, 201.0, p.x));
		borde *= smoothstep(68.0, 71.0, p.y) * (1.0 - smoothstep(89.0, 94.0, p.y));
		float onda = sin(p.y * 1.7 - tiempo * 1.5) * 0.65 + sin(p.y * 0.63 + tiempo * 0.9) * 0.35;
		vec4 agua = texture(TEXTURE, (p + vec2(onda * borde, 0.0)) / LIENZO);
		float luz = 1.0 + 0.035 * sin(tiempo * 1.8 - p.y * 0.8 + p.x * 0.09) * borde;
		color = vec4(agua.rgb * luz, agua.a);
	}
	// La llama se flexiona desde una base fija. Leña, piedras y suelo no se mueven.
	if (p.x > 207.0 && p.x < 235.0 && p.y > 80.0 && p.y < 117.0) {
		float alto = clamp((116.0 - p.y) / 30.0, 0.0, 1.0);
		float lateral = smoothstep(207.0, 214.0, p.x) * (1.0 - smoothstep(228.0, 235.0, p.x));
		float t = floor(tiempo * 12.0) / 12.0;
		float balanceo = (sin(t * 4.8 - alto * 5.0) + 0.45 * sin(t * 7.1 + alto * 8.0)) * alto * lateral;
		float estiron = (sin(t * 3.6) + 0.45 * sin(t * 6.3 + p.x)) * alto * lateral * 1.3;
		vec4 llama = texture(TEXTURE, (p + vec2(balanceo, estiron)) / LIENZO);
		float caliente = step(0.65, max(base.r, llama.r)) * step(0.23, max(base.g, llama.g));
		color = mix(base, llama, caliente);
	}
	COLOR = color;
}
