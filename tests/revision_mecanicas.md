# Revisión de mecánicas — 20/10/2026

Motor: Godot 4.7.2 stable. Pruebas automatizadas headless en Windows; red ENet local con anfitrión y cliente en procesos independientes. Se preservaron el arte, las animaciones, el audio y la interfaz de Claude.

## Correcciones

- **Embestida contra el lago:** antes, la osa avanzaba recto y se proyectaba de vuelta a la orilla. Se reprodujeron atascos y desplazamientos discontinuos en las 64 combinaciones iniciales de dirección/frecuencia. Ahora consulta la costa antes de avanzar, elige un lado de desvío y mantiene ese lado durante la carrera. Conserva la dirección anunciada como referencia, sin volver a perseguir al jugador. Los subpasos de hasta 8 píxeles comprueban contactos intermedios y paran inmediatamente si la osa queda tambaleando. El ataque especial de saltar al lago continúa funcionando.
- **Daño después de una parada válida:** cuando la osa era inmune al tambaleo, la parada protegía un solo contacto y el siguiente podía dañar al mismo jugador. La prueba nueva falló antes del arreglo y pasa después: se registra al jugador que paró entre los contactos ya resueltos de esa carrera. Se mantiene la inmunidad temporal al tambaleo.

## Resultados

Todos los casos finales siguientes terminaron con cero fallos de comprobación y salida 0 de los procesos participantes:

| Prueba | Comprobaciones del anfitrión | Cobertura |
|---|---:|---|
| `embestida_lago.gd` | 85 | Orilla a 15/30/60/120 Hz, arranque pegado al agua, carrera en seco, límites, inmersión especial, impacto único y parada con tick largo |
| `combate_compas.gd` | 27 | Parada, inmunidad al tambaleo, compazo, daño único, permisos y torre |
| `combo_red.gd` | 34 | Secuencia H/J/K/L, crítico, cola de entradas, interrupciones y réplica |
| `botella_arco.gd` | 10 | Carga, trayectoria, alturas, fuego amigo y permisos |
| `combate_red.gd` | 46 | Vida, combate, reanimación, borrachera, vómito, rodada, fases, resultados y nueva ronda |
| `botellas_agarre.gd` | 23 | Botellas, agarre y rescate desde ambos peers |
| `cerveza_recorrido.gd` | 15 | Recoger, beber, niveles de borrachera y reposición |
| `pausa_red.gd` | 21 | Pausa compartida, reanudación, lobby y desconexiones; también ejecuta comprobaciones propias del cliente |
| `mision_lago_red.gd` | 23 | Saltos, golpes aéreos, agua, misión cooperativa y victoria |
| `mision_lago_red.gd --fallar-mision` | 20 | Mismos preparativos y derrota al agotarse el tiempo de alimentación |

Los nuevos casos de misión usan pulsaciones de acciones reales, sin completar barras ni entregar piezas mediante asignaciones. Para aislar condiciones, se acortan los trayectos entre objetos, se detienen las abejas y se deja al jefe quieto durante las comprobaciones de golpes. Su entrada y su embestida usan la física normal. No se hizo una sesión humana completa ni una prueba entre computadoras por Internet.

## Pendientes comprobados

1. **Persecución normal alrededor del lago.** La corrección corresponde a la embestida. `_mover()` todavía proyecta pasos hacia fuera del agua. Reproducción con `embestida_lago.gd --diagnostico`: desde `(5900, 410)`, tras simular 10 segundos de caminar hacia `(5900, 650)`, la osa termina aproximadamente en `(5900, 449.41)`, en la misma orilla. Esto comprueba el movimiento aislado; en una pelea completa se intercalan ataques. Conviene añadir rutas por tierra a la persecución y a la aproximación del agarre.
2. **Avisos de audio al cerrar.** Algunas ejecuciones imprimen recursos MP3 pendientes de liberar. También se reprodujo al cerrar el menú sin jugar, con `--headless --quit-after 10 --verbose`: `AudioStreamPlaybackMP3`, `AudioStreamMP3` y `arte/audio/musica/menu.mp3`. No hubo errores de script ni bloqueos durante los casos. No se ha demostrado crecimiento de memoria durante partidas; el diagnóstico corresponde al cierre y queda separado de los fallos de combate.

## Mejoras recomendadas

- Priorizar la navegación normal de la osa por ambas orillas para que un jugador al otro lado no la deje insistiendo contra el agua.
- Probar la parada y la coordinación de torre con 3 jugadores en computadoras distintas y latencia real. Los resultados locales no bastan para valorar la ventana de parada de 0,22 s ni la de coordinación de 0,18 s.
- Hacer una sesión de balance sin ayudas para medir duración de pelea, facilidad de reanimar y presión del reloj de alimentación. Estas pruebas funcionales no determinan si la dificultad resulta divertida.

Los registros completos de esta ejecución están en `user://logs/revision_mecanicas_2026-10-20/`.
