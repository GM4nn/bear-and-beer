shader_type canvas_item;
// No dibuja nada por debajo de limite_y (en coordenadas del mundo): la osa
// gigante sube desde detrás de la orilla del bosque sin asomarse por el pasto.
uniform float limite_y = 300.0;
varying float mundo_y;

void vertex() {
	mundo_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	if (mundo_y > limite_y) {
		COLOR.a = 0.0;
	}
}
