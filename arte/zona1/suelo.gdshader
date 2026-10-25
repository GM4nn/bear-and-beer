shader_type canvas_item;
// Piso del bosque en pixel art, dibujado en coordenadas del mundo para que no
// se repita: pasto con manchas de luz y sombra, briznas sueltas y un camino de
// tierra que serpentea (sube y baja) con orillas irregulares. Cerca del lago el
// camino se endereza para entrar a las playitas (ver lago.gdshader).
// camino_centro / camino_ancho tienen su copia en ambientacion.gd: si cambias
// una, cambia la otra.
// Se dibuja en píxeles de 1x1 (al nivel de detalle de los personajes); las
// orillas, dientes y huellas conservan el tamaño de antes (ARTE = 3 px).

uniform vec2 tamano = vec2(11200.0, 610.0);
uniform vec2 origen = vec2(-2000.0, 190.0);
uniform float pixel = 1.0;
const float ARTE = 3.0;
uniform float lago_x = 5900.0;
uniform vec4 pasto : source_color = vec4(0.522, 0.651, 0.282, 1.0);
uniform vec4 pasto_claro : source_color = vec4(0.584, 0.706, 0.322, 1.0);
uniform vec4 pasto_brillo : source_color = vec4(0.678, 0.776, 0.384, 1.0);
uniform vec4 pasto_oscuro : source_color = vec4(0.380, 0.545, 0.224, 1.0);
uniform vec4 pasto_sombra : source_color = vec4(0.282, 0.502, 0.306, 1.0);
uniform vec4 sombra_bosque : source_color = vec4(0.204, 0.451, 0.369, 1.0);
uniform vec4 tierra : source_color = vec4(0.859, 0.624, 0.345, 1.0);
uniform vec4 tierra_media : source_color = vec4(0.776, 0.518, 0.247, 1.0);
uniform vec4 tierra_oscura : source_color = vec4(0.682, 0.435, 0.231, 1.0);
uniform vec4 tierra_clara : source_color = vec4(0.910, 0.722, 0.455, 1.0);
uniform vec4 piedra : source_color = vec4(0.66, 0.62, 0.56, 1.0);
uniform vec4 piedra_oscura : source_color = vec4(0.48, 0.42, 0.36, 1.0);

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float azar1(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

// Ruido suave (valor interpolado) para las manchas grandes del pasto.
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = azar(i);
	float b = azar(i + vec2(1.0, 0.0));
	float c = azar(i + vec2(0.0, 1.0));
	float d = azar(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float camino_centro(float x) {
	// Cerca del lago el camino va derecho a la altura de las playitas.
	float libre = clamp((abs(x - lago_x) - 650.0) / 350.0, 0.0, 1.0);
	return 535.0 + libre * (60.0 * sin(x * 0.0019 + 0.6) + 28.0 * sin(x * 0.0051 + 2.0));
}

float camino_ancho(float x) {
	return 44.0 + 9.0 * sin(x * 0.0033 + 1.3) + 5.0 * sin(x * 0.0091);
}

// Matriz de Bayer 4x4: tramado de pixel art entre dos tonos.
float bayer(vec2 celda) {
	int x = int(mod(celda.x, 4.0));
	int y = int(mod(celda.y, 4.0));
	int i = x + y * 4;
	int tabla[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(tabla[i]) / 16.0;
}

vec4 color_pasto(vec2 p, vec2 celda) {
	// Manchas grandes de luz y sombra, con tramado en las orillas.
	// Coordenadas giradas y torcidas para que las manchas no salgan cuadradas.
	vec2 q = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p;
	q += 40.0 * vec2(ruido(p / 90.0 + 7.0), ruido(p / 90.0 + 19.0));
	float mancha = ruido(q / vec2(150.0, 80.0)) * 0.6 + ruido(q / vec2(55.0, 32.0)) * 0.3 + ruido(q / 18.0) * 0.1;
	mancha += (bayer(celda) - 0.5) * 0.12;
	vec4 color = pasto;
	if (mancha > 0.66) {
		color = pasto_claro;
	} else if (mancha < 0.32) {
		color = pasto_oscuro;
	}
	// Briznas: trazos de 1 píxel de ancho y 3 a 6 de alto, oscuros con la
	// punta clara; en las manchas de luz algunas son brillantes.
	// Cada columna de 5 px va desfasada en alto para que no formen filas.
	float desfase = floor(azar1(floor(p.x / 5.0) + 3.7) * 11.0);
	vec2 q2 = p + vec2(0.0, desfase);
	vec2 caja = floor(q2 / vec2(5.0, 11.0));
	vec2 dentro = q2 - caja * vec2(5.0, 11.0);
	float h = azar(caja + vec2(3.1, 7.7));
	float columna = floor(azar(caja + vec2(1.7, 4.4)) * 5.0);
	float largo = 3.0 + floor(azar(caja + vec2(8.3, 2.9)) * 4.0);
	if (h > 0.72 && dentro.x == columna && dentro.y >= 11.0 - largo) {
		if (h > 0.9 && mancha > 0.45) {
			color = pasto_brillo;
		} else {
			color = dentro.y == 11.0 - largo ? pasto_claro : pasto_oscuro;
		}
	}
	// Junto al bosque el pasto queda a la sombra de los árboles.
	// La sombra sigue la orilla ondulada (orilla_bosque en ambientacion.gd).
	float orilla = 238.0 + 20.0 * sin(p.x * 0.0027 + 0.4) + 11.0 * sin(p.x * 0.0083 + 1.7);
	// Tramado ancho entre tonos para que la sombra no forme una franja recta.
	float sombra = smoothstep(orilla + 70.0, orilla - 10.0, p.y) + (bayer(celda) - 0.5) * 0.45
		+ (ruido(p / 24.0) - 0.5) * 0.3;
	if (sombra > 0.8) {
		color = sombra_bosque;
	} else if (sombra > 0.45) {
		color = pasto_sombra;
	}
	return color;
}

vec4 color_tierra(vec2 p, vec2 celda, float desde_arriba, float ancho) {
	vec4 color = tierra;
	// Terrones: manchitas de 3x2 en tonos de tierra.
	float t = azar(floor(celda / vec2(3.0, 2.0)) + vec2(9.2, 1.3));
	if (t > 0.93) {
		color = tierra_media;
	} else if (t > 0.9) {
		color = tierra_clara;
	}
	// Dos huellas de llanta que siguen la curva del camino.
	float r = desde_arriba / (2.0 * ancho);
	float huella = min(abs(r - 0.33), abs(r - 0.68)) * 2.0 * ancho;
	if (huella < ARTE && azar1(floor(p.x / 9.0)) > 0.25) {
		color = tierra_media;
	}
	// Piedritas grises (pocas): 5x4 con brillo arriba y sombra abajo.
	vec2 bloque = floor(p / 7.0);
	vec2 en_bloque = p - bloque * 7.0;
	if (azar(bloque + vec2(5.5, 2.2)) > 0.993 && en_bloque.x >= 1.0 && en_bloque.x <= 5.0
			&& en_bloque.y >= 2.0 && en_bloque.y <= 5.0
			&& !((en_bloque.x == 1.0 || en_bloque.x == 5.0) && (en_bloque.y == 2.0 || en_bloque.y == 5.0))) {
		color = en_bloque.y >= 4.0 ? piedra_oscura : (en_bloque.y == 2.0 && en_bloque.x < 4.0 ? tierra_clara : piedra);
	}
	// Sombra del pasto que cuelga sobre la orilla de arriba.
	if (desde_arriba < ARTE * 2.0) {
		color = tierra_oscura;
	}
	return color;
}

void fragment() {
	vec2 p = origen + floor(UV * tamano / pixel) * pixel;
	vec2 celda = floor(p / pixel);
	float centro = camino_centro(p.x);
	float ancho = camino_ancho(p.x);
	// Orillas irregulares: cada 6 píxeles la orilla sube o baja un poco,
	// y del lado de arriba el pasto cuelga en dientes.
	float borde_x = floor(p.x / (ARTE * 2.0));
	float arriba = floor(centro - ancho + (azar1(borde_x) - 0.5) * 2.0 * ARTE + floor(azar1(borde_x + 50.0) * 2.5) * ARTE);
	float abajo = floor(centro + ancho + (azar1(borde_x + 17.0) - 0.5) * 2.0 * ARTE);
	if (p.y >= arriba && p.y < abajo) {
		COLOR = color_tierra(p, celda, p.y - arriba, ancho);
	} else if (p.y >= abajo && p.y < abajo + 2.0) {
		// Borde oscuro del pasto bajo el camino.
		COLOR = pasto_sombra;
	} else if (p.y < arriba && p.y >= arriba - 2.0) {
		COLOR = pasto_oscuro;
	} else {
		COLOR = color_pasto(p, celda);
	}
}
