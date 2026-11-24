# Reduce las fotos normales de assets/ (no toca panorámicas 360° ni el mapa).
# - JPG: máximo 1600 px de ancho, calidad 82.
# - PNG de fotos: máximo 1600 px de ancho (se queda en PNG para no cambiar rutas).
# - logoapp.png: máximo 512 px.
# Solo reemplaza el archivo si el resultado pesa menos.
# Uso: powershell -ExecutionPolicy Bypass -File tool/compress_photos.ps1
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $root 'assets'

# Panorámicas 360° y mapa base: se dejan intactos (necesitan resolución).
$skip = @('mapa_base.jpg', 'moviles.jpg', 'pano_electronica.jpg', 'pano_telematica.jpg') +
        (1..3 | ForEach-Object { "E$_.jpg" }) + (1..4 | ForEach-Object { "P$_.jpg" }) + (1..3 | ForEach-Object { "S$_.jpg" })

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$params = New-Object System.Drawing.Imaging.EncoderParameters 1
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]82)

$before = 0; $after = 0
Get-ChildItem $assets -File | Where-Object { $_.Extension -in '.jpg', '.png' -and $skip -notcontains $_.Name } | ForEach-Object {
    $file = $_
    $max = if ($file.Name -eq 'logoapp.png' -or $file.Name -eq 'logo.png') { 512 } else { 1600 }
    $img = [System.Drawing.Image]::FromFile($file.FullName)
    $w = $img.Width; $h = $img.Height
    $scale = [Math]::Min(1.0, $max / $w)
    $nw = [int]($w * $scale); $nh = [int]($h * $scale)
    $bmp = New-Object System.Drawing.Bitmap $nw, $nh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $nw, $nh)
    $g.Dispose(); $img.Dispose()
    $tmp = "$($file.FullName).tmp"
    if ($file.Extension -eq '.jpg') { $bmp.Save($tmp, $jpegCodec, $params) } else { $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png) }
    $bmp.Dispose()
    $old = $file.Length; $new = (Get-Item $tmp).Length
    $before += $old
    if ($new -lt $old) { Move-Item -Force $tmp $file.FullName; $after += $new; $note = '' } else { Remove-Item $tmp; $after += $old; $note = '(sin cambio)' }
    '{0,-22} {1,5}x{2,-5} {3,7:N0} KB -> {4,7:N0} KB {5}' -f $file.Name, $w, $h, ($old / 1KB), ([Math]::Min($new, $old) / 1KB), $note
}
'TOTAL fotos: {0:N1} MB -> {1:N1} MB' -f ($before / 1MB), ($after / 1MB)
