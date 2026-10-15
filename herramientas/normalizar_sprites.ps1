# Deja todos los cuadros de una animacion en un lienzo de 96x96 con las patas
# del primer cuadro apoyadas en la misma linea y el cuerpo centrado, para que
# el personaje no "brinque" al cambiar de una animacion a otra.
#
# Uso (desde la raiz del proyecto), una o varias carpetas con 0.png, 1.png...:
#   powershell -File herramientas\normalizar_sprites.ps1 arte\mama_osa\fase1\caminar
#
# Por defecto se alinea con el primer cuadro. Si la animacion empieza tirada y
# termina de pie (levantarse), usar -Referencia -1 para alinear con el ultimo.
[CmdletBinding(PositionalBinding = $false)]
param(
    [int]$Referencia = 0,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Carpetas
)

Add-Type -AssemblyName System.Drawing
$LIENZO = 96
$PISO = 80   # fila donde quedan apoyadas las patas

foreach ($carpeta in $Carpetas) {
    $n = 0
    while (Test-Path -LiteralPath (Join-Path $carpeta "$n.png")) { $n++ }
    if ($n -eq 0) { Write-Output "$carpeta : sin cuadros"; continue }

    $cuadros = @()
    for ($i = 0; $i -lt $n; $i++) {
        $archivo = New-Object Drawing.Bitmap (Resolve-Path -LiteralPath (Join-Path $carpeta "$i.png")).Path
        $cuadros += New-Object Drawing.Bitmap $archivo   # copia en memoria
        $archivo.Dispose()
    }
    if ($cuadros[0].Width -eq $LIENZO -and $cuadros[0].Height -eq $LIENZO) {
        Write-Output "$carpeta : ya estaba normalizada"; continue
    }

    # Caja que ocupa el dibujo en el cuadro de referencia.
    $ref = $cuadros[$(if ($Referencia -lt 0) { $n + $Referencia } else { $Referencia })]
    $izq = 9999; $der = -1; $abajo = -1
    for ($y = 0; $y -lt $ref.Height; $y++) {
        for ($x = 0; $x -lt $ref.Width; $x++) {
            if ($ref.GetPixel($x, $y).A -gt 20) {
                if ($x -lt $izq) { $izq = $x }
                if ($x -gt $der) { $der = $x }
                if ($y -gt $abajo) { $abajo = $y }
            }
        }
    }
    $dx = [int][Math]::Round($LIENZO / 2 - ($izq + $der + 1) / 2)
    $dy = $PISO - ($abajo + 1)

    for ($i = 0; $i -lt $n; $i++) {
        $nuevo = New-Object Drawing.Bitmap $LIENZO, $LIENZO
        $g = [Drawing.Graphics]::FromImage($nuevo)
        $g.DrawImage($cuadros[$i], $dx, $dy, $cuadros[$i].Width, $cuadros[$i].Height)
        $g.Dispose()
        $nuevo.Save((Join-Path (Resolve-Path -LiteralPath $carpeta).Path "$i.png"), [Drawing.Imaging.ImageFormat]::Png)
        $nuevo.Dispose(); $cuadros[$i].Dispose()
    }
    Write-Output "$carpeta : $n cuadros normalizados"
}
