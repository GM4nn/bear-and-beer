# Pruebas del combate y la supervivencia

Revisión de mecánicas del 20/10/2026: ver [revision_mecanicas.md](revision_mecanicas.md), con resultados, límites de las pruebas y pendientes reproducidos.

`embestida_lago.gd` se ejecuta solo: `godot --headless --path . --script tests/embestida_lago.gd -- --host --puerto=18010`. Comprueba 16 direcciones de orilla a 15/30/60/120 Hz, otros 16 arranques pegados al agua, velocidad en seco, límites de arena, salto especial al lago, contacto único e interrupción por parada en un tick largo. Son 85 comprobaciones. `--diagnostico` añade la reproducción del pendiente de persecución normal a través del lago; ese diagnóstico no es una regresión resuelta.

`mision_lago_red.gd` usa dos procesos con `--auto` y el mismo puerto: uno `--host`, otro `--join=127.0.0.1`. Comprueba saltar, pegar en el aire, evitar el golpe al suelo, restricciones al nadar, recoger/entregar piezas con E desde ambos peers, avance e interrupción de cocina, cooperación, alimentación, aparición del jefe, réplica de su desvío y victoria con golpes reales. Se acortan traslados y se inmovilizan enemigos en los casos aislados; no representa una partida humana completa. Añadir `--fallar-mision` a ambos procesos verifica el vencimiento real de los 30 segundos de alimentación y la derrota del equipo. Deben terminar con `RESULTADO MISION LAGO: 0 fallos`.

Revisión del fondo del menú: `godot --path . --script tests/vista_fondo_menu.gd` abre el menú con su animación normal. Añadir `-- --capturas` guarda ocho momentos reproducibles y una vista sin botones en `user://fondo_menu_*.png`, y termina. Usar renderizador, no `--headless`. Revisar sleeping quieto con Z, baba del compa de la silla, sorbo completo, nubes, reflejo del lago y fuego; la tienda, árboles, muebles, suelo y encuadre deben conservarse.

`pausa_red.gd` prueba dos peers reales con `--auto` y el mismo puerto (por ejemplo 17973). Ejecutar uno con `--host` y otro con `--join=127.0.0.1`, usando `--headless --max-fps 60 --path . --script tests/pausa_red.gd` antes de `--`. Verifica Esc desde ambos peers, congelación de física y reloj, foco/Enter, opciones y volumen, cancelación del apuntado sin lanzar botellas, regreso al lobby, una segunda ronda, salida del cliente que pausó, reconexión y cierre del anfitrión. Ambos deben salir con código 0 y `RESULTADO PAUSA: 0 fallos` / `RESULTADO PAUSA CLIENTE: 0 fallos`. Con renderizador y `--captura` en el anfitrión guarda `user://pausa_menu.png` y `user://pausa_opciones.png`.

El combate rápido se comprueba en `combo_red.gd`: secuencia completa en menos de 0,8 s desde ambos peers, tres pulsaciones rápidas del mismo puño (salen cada 0,15 s, sin perderse), orden de entrada al acabar un contacto y cancelación de toda la cola al recibir daño. Comprueba H/J/K/L, Espacio para saltar, Shift para rodar y F para parar, sin conflictos entre teclas ni acciones de combate ligadas al ratón. Entre el inicio de un golpe y el siguiente pasan al menos 0,15 s; las pruebas generales limpian entradas pendientes entre casos.

`combo_red.gd` usa anfitrión y cliente con `--auto` y el mismo puerto (por ejemplo 17876). Verifica los cuatro contactos reales, daño normal y crítico, sincronización en ambos sentidos, orden incorrecto, espera, fallo al aire, interrupción por daño, tipos inválidos, jefe en el lago, dirección izquierda, torre y fin de ronda. También comprueba los controles de teclado sin conflictos, la ausencia de combate con ratón y que los efectos desaparezcan. Usa acciones sintéticas e ignora el mando físico para evitar interferencias. Con ventana y `--captura` en el anfitrión guarda `user://combo_0.png` a `combo_3.png`. Debe terminar con `RESULTADO COMBO: 0 fallos` y ambos procesos con salida 0.

`combate_compas.gd` usa anfitrión y cliente con `--auto` y el mismo puerto, como `combate_red.gd`. Verifica parada a tiempo, dirección, espera, embestida, rechazo del golpe al suelo, permisos por jugador, lanzamiento desde ambos peers, daño único a osa y compañero, fallo sin daño, alcance, lanzamiento desde hombros y cancelación al terminar. Con ventana y `--captura` en el anfitrión guarda `user://combate_*.png`. Termina con `RESULTADO COMBATE COMPAS: 0 fallos`.

`botella_arco.gd` se ejecuta en anfitrión y cliente con `--auto` y el mismo puerto (por ejemplo 17861). Comprueba diez casos: mantener R sin gastar, límite de carga, soltar, arco replicado, ascenso/descenso, pasar por encima de alguien, tiro corto con fuego amigo, cancelación por daño, rechazo de fuerza inválida y carga desde el cliente. Con ventana y `--captura` en el anfitrión guarda `user://botella_trayectoria.png`. Termina con `RESULTADO ARCO: 0 fallos`. La demo de `bots_torre.gd` también entrega seis botellas para probar a mano.

`bots_torre.gd` prueba los bots reales en tres procesos: anfitrión con `--script tests/bots_torre.gd -- --host --puerto=17850`, dos clientes con `-- --join=127.0.0.1 --auto --bot-torre --bot-ayuda --bot-turno=1 --puerto=17850` (el segundo usa `--bot-turno=2`). Comprueba que sin Mamá Osa no se montan y van por las piezas, que con ella presente suben solos, esperan el puñetazo del anfitrión, generan un único crítico por pulsación hacia ambos lados, bajan con E, vuelven a subir y se bajan solos cuando la osa ya no está. El modo `--demo` del anfitrión, con ventana y sin clientes manuales, lanza los dos bots y deja a Mamá Osa inmóvil con 5000 de vida para practicar; no cambia su balance en las partidas normales.

Los dos bots de ayuda del menú usan el modo torre: ayudan con la misión y solo se montan en el anfitrión mientras pelea Mamá Osa. Para restaurar los bots de misión, desactivar `probar_torre_con_bots` en Main; `bot_de_ayuda = false` continúa desactivándolos por completo.

`objetos_visuales.gd` verifica 11 estados de los sprites: oseznos en espera, piezas cargadas y entregadas, hervido al mantener E, alimentación interrumpible, llanto, olla rota y susto de Mamá Osa. Se ejecuta en una instancia con `--host --puerto=17812`, sin `--auto`. Termina con `RESULTADO OBJETOS: 0 fallos`. Para guardar capturas de cada estado, quitar `--headless` y añadir `--capturas` después de `--`; las imágenes quedan como `user://objetos_*.png`.

`vista_campamento.gd -- --host --puerto=17825 --capturas` permite revisar la sala, el campamento, el bosque, el cartel y el lago con renderizador. Guarda `user://vista_*.png` y se cierra. Sin `--capturas` deja la partida abierta.

`combate_red.gd` abre la escena real y conecta dos instancias por ENet. Comprueba vida autoritativa, espera entre golpes, cerveza, reanimación interrumpible, vómito, resbalones, sueño, rodada, daño aumentado, fases del jefe, resultados y una segunda ronda sobre la misma conexión.

Desde la raíz del proyecto, abrir dos terminales y ejecutar (sustituir `godot` por la ruta del ejecutable de Godot 4):

```powershell
godot --headless --max-fps 60 --path . --script tests/combate_red.gd -- --host --auto --puerto=17781
```

```powershell
godot --headless --max-fps 60 --path . --script tests/combate_red.gd -- --join=127.0.0.1 --auto --puerto=17781
```

Iniciar el cliente antes de que termine la espera inicial de 10 segundos del anfitrión. La prueba tarda unos 25 segundos y ambas instancias se cierran solas. Debe terminar con `RESULTADO: 0 fallos`, código de salida 0 y sin errores de Godot en ninguna instancia. Usa un puerto distinto al de una partida normal.

Prueba manual de balance: recoger una botella con E/Y, beber con Q/RB, rodar con Shift/B y mantener E/Y junto a un compañero caído. Saltar con Espacio/A. Para el combo: H → J → K → L. Verificar en dos computadoras la latencia y la dificultad real del Lago; las pruebas locales no sustituyen esa sesión.

`botellas_agarre.gd` se ejecuta igual. Comprueba que terminar una chela deja una botella vacía, que lanzarla la gasta, le pega al compañero (fuego amigo) y al jefe, y que Mamá Osa agarra, sostiene y avienta lejos al jugador que tiene enfrente, salvo que esté invulnerable. También verifica que un golpe amigo libera tanto al anfitrión como al cliente justo antes del lanzamiento, aunque todavía estén junto a la mano, sin recibir el daño adicional del agarre. Termina con `RESULTADO BOTELLAS Y AGARRE: 0 fallos`.

`cerveza_recorrido.gd` se ejecuta con los mismos comandos sustituyendo el nombre del script. Parte con el inventario vacío y el medidor en cero; usa las acciones E/Q para recoger seis botellas, beber cuatro, pasar por los tres niveles de borrachera, vomitar y reponer el inventario. No asigna cerveza ni borrachera artificialmente; solo acorta el recorrido entre botellas. Comprueba los valores en anfitrión y cliente y termina con `RESULTADO RECORRIDO: 0 fallos`.

`animacion_jugador.gd` se ejecuta en una sola instancia, con `--host --puerto=17792` (sin `--auto` ni cliente). Verifica que el puñetazo espere a la extensión de la mano, cause daño una sola vez y se cancele si recibe un empujón, rueda o termina la ronda durante la preparación. También comprueba la dirección visual del puño y la transición entre caminar, pegar y detenerse. Termina con `RESULTADO ANIMACIÓN: 0 fallos`.

`torre_red.gd` usa cuatro instancias: un anfitrión y tres clientes. Ejecutar el comando del cliente en tres terminales; iniciar las cuatro instancias en menos de 20 segundos. No añadir `--auto`: la prueba espera a los cuatro y abre la partida.

```powershell
godot --headless --max-fps 60 --path . --script tests/torre_red.gd -- --host --puerto=17794
godot --headless --max-fps 60 --path . --script tests/torre_red.gd -- --join=127.0.0.1 --puerto=17794
```

Comprueba las acciones reales de salto/E, límite de tres contando la base, movimiento y salto compartidos, bajar desde cada nivel, caídas por golpe, rodada, sueño, muerte y desconexión, rechazo de órdenes ajenas y altura inicial de botellas. Verifica la relación de hombros en las cuatro pantallas. Termina con `RESULTADO TORRE: 0 fallos`. Para revisar su aspecto, quitar `--headless` del anfitrión y añadir `--captura` después de `--`; guarda `torre_revision.png` en la carpeta de datos del juego (`user://`).

También comprueba las posturas de base/intermedio/cima en los cuatro peers, caminar sujetando y puñetazos sentados. El crítico se prueba con entradas reales: tres golpes coordinados (60), dos en una torre de tres (20), golpes tardíos (30), un fallo al aire y una torre válida de dos (40). Daño y aviso deben coincidir en los clientes. `--captura` guarda además `torre_critico.png`. El bonus se aplica al último contacto; los puños individuales mantienen su impacto a los 0,08 s.

## Abejas y forcejeo

`abejas_red.gd` se ejecuta con dos peers ENet reales y `--auto`, ambos en el puerto 17912. Comprueba bajas individuales por entradas H de ambos jugadores, ausencia de bajas duplicadas, reaparición real a los ocho segundos, ambas ramas del sorteo con semillas deterministas, fusión previa al agarre, un solo encuentro activo, pulsación frente a botón mantenido, identidad y número de encuentro, bloqueo de otras acciones, victoria de anfitrión y cliente, derrota, límite de tiempo, torre, pieza transportada, caída, fin de ronda, segunda ronda limpia y desconexión. La semilla solo se fija en la prueba; la partida normal usa azar real.

```powershell
godot --headless --max-fps 60 --path . --script tests/abejas_red.gd -- --host --auto --puerto=17912
godot --headless --max-fps 60 --path . --script tests/abejas_red.gd -- --join=127.0.0.1 --auto --puerto=17912
```

Ejecutar cada comando en una terminal distinta. Debe finalizar con `RESULTADO ABEJAS: 0 fallos`, ambos procesos con salida 0 y sin errores. Con renderizador y `--captura` en el anfitrión guarda `user://abejas_*.png`.

Demo manual sin depender del sorteo: `godot --path . --script tests/vista_abejas.gd -- --host --puerto=17940`. Arranca solo, muestra la fusión, permite machacar **E** y prepara otro duelo dos segundos después de cada resultado. Solo en esta demo se restaura la vida y se fuerza la aparición. Con `--capturas` inspecciona ambos lados y varios cuadros, guarda `user://vista_abejas_*.png` y se cierra.
