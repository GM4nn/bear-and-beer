shader_type canvas_item;
// Cambia el rojo de la playera por el color del jugador (un solo personaje,
// 6 colores) y lo hace destellar cuando recibe un golpe.

uniform vec3 color_jugador : source_color = vec3(0.88, 0.33, 0.24);
uniform float destello : hint_range(0.0, 1.0) = 0.0;
// Altura (en UV del cuadro) desde la que el cuerpo queda bajo el agua al nadar;
// 1.0 o más = no se esconde nada.
uniform float linea_agua = 1.0;
uniform float empapado : hint_range(0.0, 1.0) = 0.0;

vec3 a_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 a_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	vec3 hsv = a_hsv(pixel.rgb);
	// Los rojos de la playera; la piel es más anaranjada y no entra.
	if ((hsv.x < 0.03 || hsv.x > 0.93) && hsv.y > 0.5 && hsv.z > 0.25) {
		vec3 destino = a_hsv(color_jugador);
		pixel.rgb = a_rgb(vec3(destino.x, destino.y * clamp(hsv.y / 0.6, 0.8, 1.25), clamp(hsv.z * destino.z / 0.8, 0.0, 1.0)));
	}
	// Recubrimiento de miel: conserva la silueta y el sombreado del personaje.
	float brillo_miel = dot(pixel.rgb, vec3(0.3, 0.59, 0.11));
	vec3 miel = vec3(1.0, 0.62, 0.07) * (0.35 + brillo_miel * 0.85);
	pixel.rgb = mix(pixel.rgb, miel, empapado * 0.8);
	pixel.rgb = mix(pixel.rgb, vec3(1.0), destello);
	if (UV.y > linea_agua) {
		pixel.a = 0.0;
	}
	COLOR = pixel;
}
