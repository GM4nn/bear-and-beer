shader_type canvas_item;
// Lago visto de lado, en pixel art y animado. El agua es un óvalo irregular
// (ver forma_lago en ambientacion.gd: nadar usa la misma fórmula) con dos
// playitas de arena en los extremos, donde el camino de tierra entra al agua.
// Dentro del agua: franjas de profundidad, reflejo en la orilla de atrás, olas
// que avanzan, destellos y espuma en la orilla de enfrente.

uniform vec2 tamano = vec2(1200.0, 190.0);
uniform vec2 centro_agua = vec2(600.0, 95.0);
uniform vec2 radio_agua = vec2(440.0, 75.0);
uniform vec2 radio_playa = vec2(150.0, 72.0);
uniform float pixel = 3.0;
uniform vec4 agua_lejos : source_color = vec4(0.42, 0.78, 0.88, 1.0);
uniform vec4 agua_cerca : source_color = vec4(0.09, 0.40, 0.60, 1.0);
uniform vec4 reflejo : source_color = vec4(0.16, 0.42, 0.40, 1.0);
uniform vec4 brillo : source_color = vec4(0.88, 1.0, 1.0, 1.0);
uniform vec4 arena : source_color = vec4(0.91, 0.76, 0.50, 1.0);
uniform vec4 arena_clara : source_color = vec4(0.97, 0.87, 0.64, 1.0);
uniform vec4 arena_mojada : source_color = vec4(0.66, 0.51, 0.31, 1.0);
uniform vec4 tierra : source_color = vec4(0.80, 0.52, 0.28, 1.0);
uniform vec4 piedrita : source_color = vec4(0.55, 0.55, 0.60, 1.0);

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Radio relativo del óvalo según el ángulo: lo que lo hace "imperfecto".
float forma(float a) {
	return 0.97 + 0.035 * sin(3.0 * a + 0.7) + 0.02 * sin(7.0 * a + 2.1) + 0.012 * sin(13.0 * a + 4.0);
}

// Playita en un extremo: arena clara al centro, mojada junto al agua y
// mezclada con la tierra del camino en la orilla de afuera.
vec4 playa(vec2 p, float lado) {
	vec2 q = (p + pixel * 0.5 - (centro_agua + vec2(lado * radio_agua.x * 0.92, 0.0))) / radio_playa;
	float borde = length(q) + 0.06 * sin(p.y * 0.21) + 0.05 * sin(p.x * 0.13);
	if (borde >= 1.0) {
		return vec4(0.0);
	}
	vec2 celda = floor(p / pixel);
	if (azar(celda) > 0.985 && borde < 0.85) {
		return piedrita;
	}
	if (borde > 0.84) {
		return mix(arena, tierra, 0.55);
	}
	// Vetas claras de arena para que no se vea de un solo color.
	if (azar(floor(p / (pixel * 4.0))) > 0.8) {
		return arena_clara;
	}
	return arena;
}

void fragment() {
	// Trabajar en "píxeles de arte" de 3x3 para que se vea igual que los sprites.
	vec2 p = floor(UV * tamano / pixel) * pixel;
	float t = TIME;
	vec2 d = (p + pixel * 0.5 - centro_agua) / radio_agua;
	float largo = length(d);
	float angulo = atan(d.y, d.x);
	// Distancia aproximada en píxeles hasta la orilla del agua (positiva = dentro).
	vec2 dir = d / max(largo, 0.0001);
	float hasta_orilla = (forma(angulo) - largo) / max(length(dir / radio_agua), 0.0001);

	if (hasta_orilla < 0.0) {
		vec4 izquierda = playa(p, -1.0);
		COLOR = izquierda.a > 0.0 ? izquierda : playa(p, 1.0);
	} else if (hasta_orilla < 2.0 * pixel) {
		COLOR = arena_mojada;
	} else {
		float y = (p.y - (centro_agua.y - radio_agua.y)) / (2.0 * radio_agua.y);
		// Franjas de profundidad: claro al fondo (refleja el cielo), oscuro cerca.
		vec4 color = mix(agua_lejos, agua_cerca, clamp(floor(y * 5.0) / 4.0, 0.0, 1.0));

		// Reflejo ondulado del pasto, pegado a la orilla de atrás.
		float ancho_reflejo = 9.0 + 4.0 * sin(p.x * 0.03 + t * 0.7) + 2.0 * sin(p.x * 0.09 - t);
		bool en_reflejo = d.y < 0.0 && hasta_orilla < ancho_reflejo + 2.0 * pixel;
		if (en_reflejo) {
			color = mix(color, reflejo, 0.6);
		}

		// Crestas de ola: rayitas claras que avanzan, más largas y lentas cerca.
		float renglon = floor(p.y / 15.0);
		float dentro = mod(p.y, 15.0);
		float sube = floor(sin(p.x * 0.012 + t * 1.3 + renglon) * 1.5) * pixel;
		if (abs(dentro - 6.0 - sube) < pixel * 0.5 && !en_reflejo) {
			float ola = sin(p.x * (0.05 - 0.02 * y) + t * (1.0 + renglon * 0.12) + renglon * 1.7)
				* sin(p.x * 0.011 - t * 0.45 + renglon * 2.3);
			if (ola > 0.62 - 0.25 * y) {
				color = mix(color, brillo, 0.55 + 0.35 * y);
			}
		}

		// Destellos del sol que aparecen y desaparecen.
		vec2 celda = floor(p / (pixel * 7.0));
		float suerte = azar(celda);
		vec2 en_celda = mod(p, pixel * 7.0);
		if (suerte > 0.965 && sin(t * 2.5 + suerte * 60.0) > 0.85 && !en_reflejo
				&& en_celda.x < pixel * 2.0 && en_celda.y < pixel) {
			color = brillo;
		}

		// Espuma que va y viene sobre la orilla.
		float espuma = 3.0 * pixel + floor(sin(p.x * 0.04 + p.y * 0.05 + t * 1.8) * 1.5) * pixel;
		if (d.y > -0.3 && hasta_orilla < espuma) {
			color = brillo;
		}
		COLOR = color;
	}
}
