# Pruebas del combate y la supervivencia

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

`cerveza_recorrido.gd` se ejecuta con los mismos comandos sustituyendo el nombre del script. Parte con el inventario vacío y el medidor en cero; usa las acciones E/Q para recoger seis botellas, beber cuatro, pasar por los tres niveles de borrachera, vomitar y reponer el inventario. No asigna cerveza ni borrachera artificialmente; solo acorta el recorrido entre botellas. Comprueba los valores en anfitrión y cliente y termina con `RESULTADO RECORRIDO: 0 fallos`.
