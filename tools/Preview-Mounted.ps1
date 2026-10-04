$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'art/sprites/sprite-manifest.json') | ConvertFrom-Json
$atlas = @{}
foreach ($entry in $manifest.atlases) {
    $atlas[$entry.id] = @{ meta=$entry; bitmap=[System.Drawing.Bitmap]::new((Join-Path $root ('art/sprites/' + $entry.path))) }
}
$canvas = [System.Drawing.Bitmap]::new(960,640)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$font = [System.Drawing.Font]::new('Arial',16)
$graphics.Clear([System.Drawing.Color]::FromArgb(35,55,65))
$directions = @('down','up','left','right')
try {
    for ($phase=0; $phase -lt 2; $phase++) {
        for ($index=0; $index -lt 4; $index++) {
            $direction = $directions[$index]
            $originX = $index*240+60
            $originY = $phase*320+210
            $cell = 120
            $graphics.DrawRectangle([System.Drawing.Pens]::Gray,$originX,$originY,$cell,$cell)
            $graphics.DrawString(($direction+' / frame '+$phase),$font,[System.Drawing.Brushes]::White,($index*240+20),($phase*320+15))
            foreach ($kind in @('mounted')) {
                $sequence = $manifest.animationMap.mounted.walk.$direction
                $entry = $atlas[$sequence[0]]
                $frame = $entry.meta.frames[$sequence[1]*$entry.meta.columns+$sequence[2]+$phase]
                $scale = 0.0032*$cell
                $supportX = 0.5
                $supportY = 0.82
                if ($kind -eq 'hero') {
                    $supportY = 0.37
                    if ($direction -eq 'left') { $supportX = 0.58 }
                    if ($direction -eq 'right') { $supportX = 0.42 }
                }
                $w = $frame.rect[2]*$scale
                $h = $frame.rect[3]*$scale
                $left = $originX+$supportX*$cell-$frame.groundPivot[0]*$w
                $top = $originY+$supportY*$cell-$frame.groundPivot[1]*$h
                $dest = [System.Drawing.Rectangle]::new([int]$left,[int]$top,[int]$w,[int]$h)
                $graphics.DrawImage($entry.bitmap,$dest,$frame.rect[0],$frame.rect[1],$frame.rect[2],$frame.rect[3],[System.Drawing.GraphicsUnit]::Pixel)
            }
            $graphics.FillEllipse([System.Drawing.Brushes]::HotPink,($originX+58),($originY+96),4,4)
        }
    }
    $canvas.Save((Join-Path $root 'build/video-analysis/mounted-preview.png'))
} finally {
    $graphics.Dispose(); $canvas.Dispose(); $font.Dispose()
    foreach ($entry in $atlas.Values) { $entry.bitmap.Dispose() }
}
