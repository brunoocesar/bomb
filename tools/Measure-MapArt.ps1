param([string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$names = @('wall','wood','energy','capacityCrate','rangeCrate','secretCrate','coinCrate','exitClosed','exitOpen','capacity','range','coins','frog','secret','bomb','enemy','blastCore','blastHorizontal','blastVertical','sparkle')
# Measured row boundaries of this generated atlas, not an assumed uniform grid.
$rowBands = @(0,264,510,774,996,1254)
$atlasPath = Join-Path $ProjectRoot 'art/maps/tutorial/objects-v1.png'
$bitmap = [System.Drawing.Bitmap]::new($atlasPath)
try {
    if (-not [System.Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) { throw 'Map atlas needs alpha.' }
    $frames = [ordered]@{}
    for ($index=0; $index -lt $names.Count; $index++) {
        $column = $index % 4
        $row = [Math]::Floor($index/4)
        $cellLeft = [int][Math]::Round($column*$bitmap.Width/4)
        $cellRight = [int][Math]::Round(($column+1)*$bitmap.Width/4)
        $cellTop = $rowBands[$row]
        $cellBottom = $rowBands[$row+1]
        $left=$cellRight; $right=-1; $top=$cellBottom; $bottom=-1
        for ($py=$cellTop; $py -lt $cellBottom; $py++) {
            for ($px=$cellLeft; $px -lt $cellRight; $px++) {
                if ($bitmap.GetPixel($px,$py).A -lt 180) { continue }
                $left=[Math]::Min($left,$px); $right=[Math]::Max($right,$px)
                $top=[Math]::Min($top,$py); $bottom=[Math]::Max($bottom,$py)
            }
        }
        if ($right -lt 0) { throw ('Empty map sprite: '+$names[$index]) }
        $left=[Math]::Max($cellLeft,$left-3); $top=[Math]::Max($cellTop,$top-3)
        $right=[Math]::Min($cellRight-1,$right+3); $bottom=[Math]::Min($cellBottom-1,$bottom+3)
        $frames[$names[$index]] = @($left,$top,($right-$left+1),($bottom-$top+1))
    }
    # Deliberate interior cuts preserve white-hot connections and rounded outer caps.
    $frames.blastJoinHorizontal = @(464,1080,16,104)
    $frames.blastJoinVertical = @(720,1108,132,16)
    $frames.blastTipLeft = @(339,1080,131,104)
    $frames.blastTipRight = @(470,1080,132,104)
    $frames.blastTipUp = @(720,999,132,117)
    $frames.blastTipDown = @(720,1116,132,117)
    $manifest=[ordered]@{schemaVersion=1;atlasPath='tutorial/objects-v1.png';imageSize=@($bitmap.Width,$bitmap.Height);columns=4;rows=5;frames=$frames;blastCropNotes='Connection strips and end caps cropped from original blastHorizontal/blastVertical; no new raster or upload.'}
    $manifest | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $ProjectRoot 'art/maps/map-manifest.json') -Encoding UTF8
} finally { $bitmap.Dispose() }
Write-Output ('Measured {0} image sprites.' -f $frames.Count)
