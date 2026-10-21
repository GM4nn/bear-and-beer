"""Compone la música (chiptune con aire de mariachi) y los efectos del juego.

Todo es original y sintetizado aquí: trompetas en terceras (onda cuadrada con
vibrato), vihuela rasgueada en los contratiempos y guitarrón en el bajo.
Genera WAV en arte/audio/musica y arte/audio/efectos.

Uso (desde la raíz del proyecto):  python herramientas/componer_audio.py
Si pones un .ogg o .mp3 con el mismo nombre en esas carpetas, el juego usa
ese en lugar del WAV (ver scripts/audio.gd).
"""
import os
import wave
import numpy as np

SR = 22050  # chiptune: 22 kHz alcanza y pesa la mitad
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arte", "audio")
rng = np.random.default_rng(7)

NOTAS = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
         "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def hz(nota):
    """'A4' -> 440. Acepta sostenidos/bemoles ('F#4', 'Bb3')."""
    nombre, octava = nota[:-1], int(nota[-1])
    n = NOTAS[nombre] + (octava + 1) * 12
    return 440.0 * 2 ** ((n - 69) / 12)


def t(dur):
    return np.arange(int(SR * dur)) / SR


def envolvente(n, ataque=0.01, caida=0.1, sostiene=0.7, suelta=0.05):
    a, d, r = int(SR * ataque), int(SR * caida), int(SR * suelta)
    s = max(n - a - d - r, 0)
    env = np.concatenate([np.linspace(0, 1, max(a, 1)), np.linspace(1, sostiene, max(d, 1)),
                          np.full(s, sostiene), np.linspace(sostiene, 0, max(r, 1))])
    return env[:n] if len(env) >= n else np.pad(env, (0, n - len(env)))


def cuadrada(f, dur, ciclo=0.5, vibrato=0.0, vel_vib=5.5):
    x = t(dur)
    fase = 2 * np.pi * f * x + (vibrato * f / vel_vib) * np.sin(2 * np.pi * vel_vib * x) / f * 6
    return np.where((fase / (2 * np.pi)) % 1.0 < ciclo, 1.0, -1.0)


def triangular(f, dur):
    x = t(dur)
    return 2 * np.abs(2 * ((f * x) % 1.0) - 1) - 1


def sierra(f, dur):
    x = t(dur)
    return 2 * ((f * x) % 1.0) - 1


def ruido(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def pasa_bajos(senal, corte):
    """Filtro de un polo, suficiente para suavizar el ruido."""
    a = np.exp(-2 * np.pi * corte / SR)
    salida = np.empty_like(senal)
    acum = 0.0
    for i, v in enumerate(senal):
        acum = (1 - a) * v + a * acum
        salida[i] = acum
    return salida


def mezclar(pista, sonido, inicio):
    i = int(SR * inicio)
    fin = min(i + len(sonido), len(pista))
    if fin > i:
        pista[i:fin] += sonido[:fin - i]


def guardar(senal, carpeta, nombre, volumen=0.9):
    senal = senal / max(np.max(np.abs(senal)), 1e-6) * volumen
    datos = (senal * 32767).astype(np.int16)
    ruta = os.path.join(RAIZ, carpeta)
    os.makedirs(ruta, exist_ok=True)
    with wave.open(os.path.join(ruta, nombre + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(datos.tobytes())
    print(f"{carpeta}/{nombre}.wav  {len(senal) / SR:.1f} s")


# --- Instrumentos -------------------------------------------------------------

def trompeta(nota, dur):
    f = hz(nota)
    s = cuadrada(f, dur, ciclo=0.3, vibrato=0.6) * 0.55 + cuadrada(f * 2, dur, ciclo=0.5) * 0.12
    return s * envolvente(len(s), 0.025, 0.08, 0.75, min(0.06, dur * 0.3))


def vihuela(acorde, dur=0.16):
    """Rasgueo: las notas del acorde casi juntas, cortitas y brillantes."""
    s = np.zeros(int(SR * (dur + 0.03)))
    for k, nota in enumerate(acorde):
        f = hz(nota)
        tono = cuadrada(f, dur, ciclo=0.5) * np.exp(-t(dur) * 18)
        mezclar(s, tono * 0.16, k * 0.008)
    return s


def guitarron(nota, dur):
    f = hz(nota)
    s = triangular(f, dur) * 0.8 + cuadrada(f, dur, 0.5) * 0.12
    return s * np.exp(-t(dur) * 3.2) * envolvente(len(s), 0.005, 0.05, 1.0, 0.03)


def maraca(dur=0.06):
    return pasa_bajos(ruido(dur), 6000) * np.exp(-t(dur) * 60) * 0.18


ACORDES = {
    "D": ["D4", "F#4", "A4"], "A7": ["C#4", "E4", "G4", "A4"], "G": ["D4", "G4", "B4"],
    "Am": ["E4", "A4", "C5"], "E7": ["D4", "E4", "G#4", "B4"], "Dm": ["D4", "F4", "A4"],
    "F": ["F4", "A4", "C5"], "C": ["E4", "G4", "C5"], "B7": ["D#4", "F#4", "A4", "B4"],
    "Em": ["E4", "G4", "B4"],
}
BAJOS = {"D": ("D2", "A2"), "A7": ("A2", "E2"), "G": ("G2", "D2"), "Am": ("A2", "E2"),
         "E7": ("E2", "B2"), "Dm": ("D2", "A2"), "F": ("F2", "C3"), "C": ("C2", "G2"),
         "B7": ("B2", "F#2"), "Em": ("E2", "B2")}


def tercera_abajo(nota, tonalidad):
    """Segunda trompeta: la nota de la escala dos grados abajo (terceras paralelas)."""
    escala = tonalidad
    nombre, octava = nota[:-1], int(nota[-1])
    if nombre not in escala:
        # Nota de paso fuera de la escala: tercera menor exacta (3 semitonos abajo).
        n = NOTAS[nombre] + octava * 12 - 3
        nombres = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return f"{nombres[n % 12]}{n // 12}"
    i = escala.index(nombre)
    j = i - 2
    if j < 0:
        j += len(escala)
        octava -= 1
    return f"{escala[j]}{octava}"


def pieza(compases, melodia, tonalidad, bpm, tiempos, armonia=True, maracas=True):
    """compases: acordes (uno por compás). melodia: lista de (nota|None, pulsos)."""
    pulso = 60.0 / bpm
    dur = len(compases) * tiempos * pulso
    pista = np.zeros(int(SR * (dur + 1.0)))
    # Acompañamiento: guitarrón en el 1 (y el 3 si hay), vihuela en los demás pulsos.
    for c, acorde in enumerate(compases):
        inicio = c * tiempos * pulso
        raiz, quinta = BAJOS[acorde]
        mezclar(pista, guitarron(raiz, pulso * 0.95), inicio)
        if tiempos == 4:
            mezclar(pista, guitarron(quinta, pulso * 0.95), inicio + 2 * pulso)
        elif tiempos == 2:
            mezclar(pista, guitarron(quinta, pulso * 0.95), inicio + pulso) if c % 2 else None
        for p in range(tiempos):
            if tiempos == 2:
                mezclar(pista, vihuela(ACORDES[acorde]), inicio + p * pulso + pulso / 2)
            elif p > 0:
                mezclar(pista, vihuela(ACORDES[acorde]), inicio + p * pulso)
            if maracas:
                mezclar(pista, maraca(), inicio + p * pulso + pulso / 2)
    # Trompetas.
    pos = 0.0
    for nota, pulsos in melodia:
        d = pulsos * pulso
        if nota:
            mezclar(pista, trompeta(nota, d * 0.92), pos)
            if armonia:
                mezclar(pista, trompeta(tercera_abajo(nota, tonalidad), d * 0.92) * 0.6, pos)
        pos += d
    return pista[:int(SR * dur)]


ESC_D = ["D", "E", "F#", "G", "A", "B", "C#"]
ESC_G = ["G", "A", "B", "C", "D", "E", "F#"]
ESC_AM = ["A", "B", "C", "D", "E", "F", "G#"]


def m(texto):
    """'A4:2 B4:1 -:1' -> [('A4', 2), ('B4', 1), (None, 1)]"""
    salida = []
    for parte in texto.split():
        nota, pulsos = parte.split(":")
        salida.append((None if nota == "-" else nota, float(pulsos)))
    return salida


def musica_menu():
    # Vals ranchero en Sol, tranquilo: 16 compases x 2 vueltas.
    compases = ["G", "G", "D", "D", "D", "D", "G", "G", "C", "C", "G", "G", "D", "D", "G", "G"]
    mel = m("D5:2 B4:1 | G4:2 B4:1 A4:3 -:3 A4:2 F#4:1 D4:2 F#4:1 A4:2 C5:1 B4:3 "
            "D5:2 B4:1 G4:2 B4:1 E5:2 D5:1 C5:3 E5:2 C5:1 B4:2 D5:1 A4:2 F#4:1 G4:3 -:3".replace("| ", ""))
    una = pieza(compases, mel, ESC_G, 104, 3)
    return np.concatenate([una, una])


def musica_bosque():
    # Polka/corrido en Re, alegre: 16 compases de 2/4 x 2.
    compases = ["D", "D", "A7", "A7", "A7", "A7", "D", "D", "G", "G", "D", "D", "A7", "A7", "D", "D"]
    mel = m("A4:0.5 F#4:0.5 A4:0.5 D5:0.5 C#5:0.5 B4:0.5 A4:1 G4:0.5 B4:0.5 E5:0.5 C#5:0.5 A4:1 -:1 "
            "E4:0.5 G4:0.5 C#5:0.5 E5:0.5 D5:0.5 C#5:0.5 B4:0.5 C#5:0.5 D5:1 A4:1 F#4:1 -:1 "
            "B4:0.5 D5:0.5 G5:0.5 D5:0.5 B4:1 G4:1 A4:0.5 F#4:0.5 D5:0.5 F#5:0.5 E5:1 D5:1 "
            "E5:0.5 C#5:0.5 A4:0.5 C#5:0.5 E5:0.5 G5:0.5 F#5:0.5 E5:0.5 D5:1 A4:0.5 F#4:0.5 D4:1 -:1")
    una = pieza(compases, mel, ESC_D, 132, 2)
    return np.concatenate([una, una])


def musica_jefe():
    # Pelea con Mamá Osa: La menor, rápido y tenso, 16 compases de 2/4 x 2.
    compases = ["Am", "Am", "E7", "E7", "Am", "Am", "Dm", "E7", "F", "C", "Dm", "Am", "E7", "E7", "Am", "E7"]
    mel = m("E5:0.5 E5:0.5 A5:0.5 E5:0.5 C5:0.5 A4:0.5 E4:1 G#4:0.5 B4:0.5 E5:0.5 B4:0.5 G#5:1 E5:1 "
            "A4:0.5 C5:0.5 E5:0.5 A5:0.5 G#5:0.5 E5:0.5 C5:1 D5:0.5 F5:0.5 A5:0.5 F5:0.5 E5:0.5 D5:0.5 B4:1 "
            "C5:0.5 F5:0.5 A5:0.5 F5:0.5 E5:0.5 G5:0.5 C5:1 D5:0.5 A4:0.5 F5:0.5 D5:0.5 C5:0.5 E5:0.5 A4:1 "
            "B4:0.5 G#4:0.5 E4:0.5 G#4:0.5 B4:0.5 E5:0.5 G#5:1 A5:1 E5:0.5 C5:0.5 B4:1 G#4:1")
    una = pieza(compases, mel, ESC_AM, 168, 2)
    return np.concatenate([una, una])


def jingle_victoria():
    mel = m("D5:0.5 D5:0.5 D5:0.5 F#5:1.5 A5:2 F#5:0.5 A5:2.5")
    return pieza(["D", "D", "A7", "D"], mel, ESC_D, 150, 2, maracas=False)


def jingle_derrota():
    # "Wah wah waaah" de trompeta bajando, con el guitarrón.
    s = np.zeros(int(SR * 3.4))
    for k, nota in enumerate(["G4", "F#4", "F4"]):
        mezclar(s, trompeta(nota, 0.5), k * 0.55)
    largo = trompeta("E4", 1.6) * (1 + 0.3 * np.sin(2 * np.pi * 6 * t(1.6)))
    mezclar(s, largo, 1.65)
    mezclar(s, guitarron("E2", 1.6), 1.65)
    return s


# --- Efectos -------------------------------------------------------------------

def caida_tono(f0, f1, dur, onda=cuadrada):
    x = t(dur)
    f = np.geomspace(f0, f1, len(x))
    fase = 2 * np.pi * np.cumsum(f) / SR
    return np.where(onda is cuadrada, np.sign(np.sin(fase)), np.sin(fase))


def efectos():
    e = {}
    golpe = pasa_bajos(ruido(0.12), 1800) * np.exp(-t(0.12) * 35) * 1.4
    golpe += np.sin(2 * np.pi * np.cumsum(np.geomspace(160, 55, len(golpe))) / SR) * np.exp(-t(0.12) * 25)
    e["golpe"] = golpe
    critico = pasa_bajos(ruido(0.3), 2500) * np.exp(-t(0.3) * 14) * 1.3
    critico += np.sin(2 * np.pi * np.cumsum(np.geomspace(220, 40, len(critico))) / SR) * np.exp(-t(0.3) * 9)
    critico[:len(t(0.15))] += cuadrada(880, 0.15, 0.25) * np.exp(-t(0.15) * 20) * 0.35
    e["golpe_critico"] = critico
    clang = sum(np.sin(2 * np.pi * f * t(0.5)) * a for f, a in [(1200, 1), (1730, 0.6), (2650, 0.4), (3500, 0.25)])
    e["parada"] = clang * np.exp(-t(0.5) * 9) + pasa_bajos(ruido(0.5), 5000) * np.exp(-t(0.5) * 40) * 0.5
    sopla = ruido(0.28)
    e["lanzar"] = pasa_bajos(sopla, 2500) * np.sin(np.pi * np.linspace(0, 1, len(sopla))) * 1.2
    vidrio = ruido(0.6) * np.exp(-t(0.6) * 12) * 0.6
    for _ in range(9):
        f = rng.uniform(2200, 5200)
        ping = np.sin(2 * np.pi * f * t(0.35)) * np.exp(-t(0.35) * rng.uniform(10, 25)) * 0.5
        mezclar(vidrio, ping, rng.uniform(0, 0.12))
    e["botella_rompe"] = vidrio
    trago = np.zeros(int(SR * 0.9))
    for k in range(3):
        burbuja = np.sin(2 * np.pi * np.cumsum(np.geomspace(140, 320, len(t(0.14)))) / SR) * np.exp(-t(0.14) * 12)
        mezclar(trago, burbuja, k * 0.27)
    e["tomar"] = trago
    eructo = sierra(70, 0.7) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t(0.7)))
    e["eructo"] = pasa_bajos(eructo, 700) * envolvente(len(eructo), 0.03, 0.2, 0.7, 0.2) * 1.6
    vomito = pasa_bajos(ruido(1.2), 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t(1.2)))
    vomito += sierra(110, 1.2) * np.linspace(1, 0.3, len(vomito)) * 0.5
    e["vomito"] = vomito * envolvente(len(vomito), 0.05, 0.2, 0.8, 0.3)
    chapo = pasa_bajos(ruido(0.8), 3000) * np.exp(-t(0.8) * 6)
    e["chapuzon"] = chapo + np.sin(2 * np.pi * np.cumsum(np.geomspace(500, 150, len(chapo))) / SR) * np.exp(-t(0.8) * 10) * 0.4
    zumbido = sierra(230, 1.0) * (0.7 + 0.3 * np.sin(2 * np.pi * 28 * t(1.0))) + sierra(237, 1.0) * 0.5
    e["abejas"] = pasa_bajos(zumbido, 1600) * envolvente(int(SR * 1.0), 0.1, 0.1, 1.0, 0.2)
    rugido = pasa_bajos(ruido(1.4), 500) * 1.5 + sierra(75, 1.4) * (0.7 + 0.3 * np.sin(2 * np.pi * 7 * t(1.4)))
    e["rugido"] = pasa_bajos(rugido, 900) * envolvente(len(rugido), 0.08, 0.3, 0.8, 0.5)
    zarpazo = pasa_bajos(ruido(0.35), 4000) * np.sin(np.pi * np.linspace(0, 1, int(SR * 0.35))) ** 2
    e["zarpazo"] = zarpazo * 1.3
    e["caer"] = np.sin(2 * np.pi * np.cumsum(np.geomspace(420, 90, len(t(0.6)))) / SR) * np.exp(-t(0.6) * 3)
    recoger = np.zeros(int(SR * 0.25))
    for k, nota in enumerate(["E5", "A5", "C#6"]):
        mezclar(recoger, cuadrada(hz(nota), 0.07, 0.25) * np.exp(-t(0.07) * 20) * 0.6, k * 0.06)
    e["recoger"] = recoger
    e["click"] = cuadrada(hz("A5"), 0.05, 0.25) * np.exp(-t(0.05) * 60)
    e["torre_critico"] = trompeta("A5", 0.25) + np.pad(trompeta("D6", 0.4), (int(SR * 0.12), 0))[:int(SR * 0.25)]
    fanf = np.zeros(int(SR * 0.7))
    mezclar(fanf, trompeta("A5", 0.15), 0)
    mezclar(fanf, trompeta("D6", 0.45), 0.15)
    e["torre_critico"] = fanf
    return e


if __name__ == "__main__":
    guardar(musica_menu(), "musica", "menu", 0.8)
    guardar(musica_bosque(), "musica", "bosque", 0.8)
    guardar(musica_jefe(), "musica", "jefe", 0.8)
    guardar(jingle_victoria(), "musica", "victoria", 0.85)
    guardar(jingle_derrota(), "musica", "derrota", 0.85)
    for nombre, senal in efectos().items():
        guardar(senal, "efectos", nombre)
