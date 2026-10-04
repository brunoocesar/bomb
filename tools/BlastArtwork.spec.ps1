$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'art/maps/map-manifest.json') | ConvertFrom-Json
$atlas = [System.Drawing.Bitmap]::new((Join-Path $root 'art/maps/tutorial/objects-v1.png'))
$checks = 0
function Check($condition, $message) {
    $script:checks++
    if (-not $condition) { throw $message }
}
try {
    # White-hot centerlines must reach both ends of interior connectors.
    foreach ($name in @('blastJoinHorizontal','blastJoinVertical')) {
        $crop = $manifest.frames.$name
        $horizontal = $name -eq 'blastJoinHorizontal'
        $length = if ($horizontal) { $crop[2] } else { $crop[3] }
        for ($index=0; $index -lt $length; $index++) {
            $x = $crop[0] + $(if ($horizontal) { $index } else { [int][Math]::Floor($crop[2]/2) })
            $y = $crop[1] + $(if ($horizontal) { [int][Math]::Floor($crop[3]/2) } else { $index })
            $pixel = $atlas.GetPixel($x,$y)
            Check ($pixel.A -ge 180) "$name has a transparent gap along its centerline at $index"
            Check ($pixel.R -gt 220 -and $pixel.G -gt 190) "$name loses its bright centerline at $index"
        }
    }
    # Inner edge of each cap joins the connector; the outer edge stays in its cell.
    foreach ($name in @('blastTipLeft','blastTipRight','blastTipUp','blastTipDown')) {
        $crop=$manifest.frames.$name
        $x=$crop[0]+[int][Math]::Floor($crop[2]/2)
        $y=$crop[1]+[int][Math]::Floor($crop[3]/2)
        switch ($name) {
            'blastTipLeft' { $x=$crop[0]+$crop[2]-1 }
            'blastTipRight' { $x=$crop[0] }
            'blastTipUp' { $y=$crop[1]+$crop[3]-1 }
            'blastTipDown' { $y=$crop[1] }
        }
        Check ($atlas.GetPixel($x,$y).A -ge 180) "$name has a gap at its connecting edge"
    }
} finally { $atlas.Dispose() }
Write-Output "Blast artwork passed: $checks alpha/color checks. Source raster only; Roblox sampling pending."
