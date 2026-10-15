# Pruebas del combate y la supervivencia

`bots_torre.gd` prueba los bots reales en tres procesos: anfitrión con `--script tests/bots_torre.gd -- --host --puerto=17850`, dos clientes con `-- --join=127.0.0.1 --auto --bot-torre --bot-ayuda --bot-turno=1 --puerto=17850` (el segundo usa `--bot-turno=2`). Comprueba que suben solos, esperan el puñetazo del anfitrión, generan un único crítico por pulsación hacia ambos lados, bajan con E y vuelven a subir. El modo `--demo` del anfitrión, con ventana y sin clientes manuales, lanza los dos bots y deja a Mamá Osa inmóvil con 5000 de vida para practicar; no cambia su balance en las partidas normales.

Los dos bots de ayuda del menú usan ahora el modo torre. Para restaurar los bots de misión, desactivar `probar_torre_con_bots` en Main; `bot_de_ayuda = false` continúa desactivándolos por completo.

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

Prueba manual de balance: recoger una botella con E/Y, beber con Q/RB, rodar con Shift/K/B y mantener E/Y junto a un compañero caído. Verificar en dos computadoras la latencia y la dificultad real del Lago; las pruebas locales no sustituyen esa sesión.

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
