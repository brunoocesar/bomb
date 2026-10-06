$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$names = @('hay','energy','chestClosed','chestOpen','slug_down','slug_up','slug_left','slug_right',
    'beetle_down','beetle_up','beetle_left','beetle_right','sunKey','blueFlowers','goldRibbon','sunStatue')
# Measured whitespace bands in the actual generated image, not the ideal prompt grid.
$bands = @(0,350,645,935,1254)
$bitmap = [Drawing.Bitmap]::new((Join-Path $root 'art/maps/world1/phase1-objects-v1.png'))
try {
    if ($bitmap.Width -ne 1254 -or $bitmap.Height -ne 1254) { throw 'Inspect row bands again for a different source size.' }
    if (-not [Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) { throw 'Atlas requires transparency.' }
    $frames = [ordered]@{}
    for ($index = 0; $index -lt $names.Count; $index++) {
        $column = $index % 4
        $row = [int][Math]::Floor($index / 4)
        $cellLeft = [int][Math]::Round($column * $bitmap.Width / 4)
        $cellRight = [int][Math]::Round(($column + 1) * $bitmap.Width / 4)
        $left = $cellRight; $right = -1; $top = $bands[$row + 1]; $bottom = -1
        for ($y = $bands[$row]; $y -lt $bands[$row + 1]; $y++) {
            for ($x = $cellLeft; $x -lt $cellRight; $x++) {
                if ($bitmap.GetPixel($x, $y).A -lt 180) { continue }
                $left = [Math]::Min($left, $x); $right = [Math]::Max($right, $x)
                $top = [Math]::Min($top, $y); $bottom = [Math]::Max($bottom, $y)
            }
        }
        if ($right -lt 0) { throw "Empty sprite $($names[$index])" }
        $left = [Math]::Max($cellLeft, $left - 2); $right = [Math]::Min($cellRight - 1, $right + 2)
        $top = [Math]::Max($bands[$row], $top - 2); $bottom = [Math]::Min($bands[$row + 1] - 1, $bottom + 2)
        $frames[$names[$index]] = @($left, $top, ($right - $left + 1), ($bottom - $top + 1))
    }
    $manifest = [ordered]@{ source='world1/phase1-objects-v1.png'; imageSize=@(1254,1254); frames=$frames }
    [IO.File]::WriteAllText((Join-Path $root 'art/maps/world1/phase1-art-manifest.json'),
        ($manifest | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
    Write-Output ($manifest | ConvertTo-Json -Depth 6 -Compress)
} finally { $bitmap.Dispose() }
