param([string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not ('SpriteBounds' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class SpriteBounds {
    public static int[] Find(Bitmap image, int x, int y, int width, int height) {
        int left=width, top=height, right=-1, bottom=-1;
        for(int py=0;py<height;py++) for(int px=0;px<width;px++) {
            if(image.GetPixel(x+px,y+py).A<200) continue;
            left=Math.Min(left,px); top=Math.Min(top,py);
            right=Math.Max(right,px); bottom=Math.Max(bottom,py);
        }
        if(right<0) throw new Exception("Empty sprite rectangle");
        return new int[]{left,top,right-left+1,bottom-top+1};
    }
}
'@
}
$definitions = @(
    @{ id='hero'; path='hero/base/hero-v1.png'; bands=@(0,.132,.262,.394,.528,.674,.812,1) },
    @{ id='heroMovement'; path='hero/base/hero-movement-v1.png'; bands=@(0,.132,.262,.394,.530,.674,.814,1) },
    @{ id='frog'; path='frog/base/frog-clean-v1.png'; bands=@(0,.125,.25,.375,.5,.625,.75,.875,1) },
    # Measured gutters: uniform quarters would clip rear flames into right-facing frames.
    @{ id='mounted'; path='mounted/base/mounted-v1.png'; columns=4; bands=@(0,.248,.49,.731,1) }
)
foreach ($variant in @('cream','scarf')) {
    foreach ($form in @('hero','heroMovement','mounted')) {
        $source = $definitions | Where-Object { $_.id -eq $form } | Select-Object -First 1
        $fileName = if ($form -eq 'heroMovement') { "hero-movement-$variant-v1.png" } else { "$form-$variant-v1.png" }
        $family = if ($form -eq 'mounted') { 'mounted' } else { 'hero' }
        $relative = "$family/$variant/$fileName"
        if (Test-Path -LiteralPath (Join-Path $ProjectRoot "art/sprites/$relative")) {
            $entry = @{ id=($form + ($variant.Substring(0,1).ToUpper() + $variant.Substring(1))); path=$relative; bands=$source.bands }
            if ($source.columns) { $entry.columns = $source.columns }
            $definitions += $entry
        }
    }
}
$atlases = @()
$frogCrops = Get-Content -Raw -Encoding UTF8 (Join-Path $ProjectRoot 'art/sprites/frog/frame-crops.json') | ConvertFrom-Json
foreach ($definition in $definitions) {
    $imagePath = Join-Path $ProjectRoot ('art/sprites/' + $definition.path)
    $bitmap = [System.Drawing.Bitmap]::new($imagePath)
    try {
        if (-not [System.Drawing.Image]::IsAlphaPixelFormat($bitmap.PixelFormat)) { throw 'Missing alpha channel' }
        $frames = @()
        $columns = if ($definition.columns) { $definition.columns } else { 8 }
        for ($row=0; $row -lt $definition.bands.Count-1; $row++) {
            for ($column=0; $column -lt $columns; $column++) {
                $x=[int][Math]::Round($column*$bitmap.Width/$columns)
                $y=[int][Math]::Round($definition.bands[$row]*$bitmap.Height)
                $width=[int][Math]::Round(($column+1)*$bitmap.Width/$columns)-$x
                $height=[int][Math]::Round($definition.bands[$row+1]*$bitmap.Height)-$y
                $annotation = $null
                if ($definition.id -eq 'frog') {
                    $annotation = $frogCrops.frames.('frog_r{0}_c{1}' -f $row,$column)
                    $x,$y,$width,$height = $annotation.rect
                }
                $bounds=[SpriteBounds]::Find($bitmap,$x,$y,$width,$height)
                $groundY = if ($annotation -and $annotation.groundY) { $annotation.groundY-$y } else { $bounds[1]+$bounds[3] }
                $frames += [ordered]@{
                    id=('{0}_r{1}_c{2}' -f $definition.id,$row,$column)
                    row=$row; column=$column
                    rect=@($x,$y,$width,$height)
                    opaqueBounds=$bounds
                    groundPivot=@([Math]::Round(($bounds[0]+$bounds[2]/2)/$width,4),[Math]::Round($groundY/$height,4))
                }
            }
        }
        $atlases += [ordered]@{id=$definition.id;path=$definition.path;imageSize=@($bitmap.Width,$bitmap.Height);columns=$columns;rows=($definition.bands.Count-1);frames=$frames}
    } finally { $bitmap.Dispose() }
}
$uploadedRecordPath = Join-Path $ProjectRoot 'art/sprites/roblox-assets.json'
$uploadedIds = @{hero=$null;heroMovement=$null;frog=$null}
$integrationStatus = 'art only; upload and runtime validation pending'
if (Test-Path -LiteralPath $uploadedRecordPath) {
    $uploadedRecord = Get-Content -LiteralPath $uploadedRecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $uploadedIds = $uploadedRecord.imageIds
    $integrationStatus = 'uploaded and linked; runtime validation recorded in docs/CURVAS_E_PACK_MONTADO.md'
}
$manifest=[ordered]@{
    schemaVersion=1
    coordinateConvention='zero-based top-left pixel rectangles; normalized pivots within each rectangle'
    robloxImageIds=$uploadedIds
    integrationStatus=$integrationStatus
    atlases=$atlases
    animationMap=[ordered]@{
        hero=[ordered]@{
            walk=@{down=@('hero',0,0,7);left=@('hero',1,0,7);right=@('hero',2,0,7);up=@('heroMovement',3,0,7)}
            idle=@{down=@('hero',3,0,0);left=@('hero',1,0,0);right=@('hero',2,0,0);up=@('heroMovement',3,0,0)}
            blink=@{down=@('hero',3,2,2)}
            placeBomb=@{down=@('hero',4,0,0);up=@('hero',6,0,0)}
            damage=@{down=@('hero',4,1,1);up=@('hero',6,1,1)}
            victory=@{down=@('hero',4,2,2);up=@('hero',6,2,2)}
            mount=@{down=@('hero',4,3,4);up=@('hero',6,3,4)}
            dismount=@{down=@('hero',4,5,6);up=@('hero',6,5,6)}
            mounted=@{down=@('hero',5,0,1);left=@('hero',5,2,3);right=@('hero',5,4,5);up=@('hero',5,6,7)}
        }
        frog=[ordered]@{
            walk=@{down=@('frog',0,0,7);left=@('frog',1,0,7);right=@('frog',2,0,7);up=@('frog',3,0,7)}
            idle=@{down=@('frog',4,0,0);left=@('frog',1,0,0);right=@('frog',2,0,0);up=@('frog',3,0,0)}
            blink=@{down=@('frog',4,2,2)}
            jump=@{down=@('frog',5,0,7)}
            protect=@{down=@('frog',6,0,3)}
            disappear=@{down=@('frog',6,4,7)}
            celebrate=@{down=@('frog',7,0,7)}
        }
        mounted=[ordered]@{
            walk=@{down=@('mounted',0,0,3);left=@('mounted',1,0,3);right=@('mounted',2,0,3);up=@('mounted',3,0,3)}
            idle=@{down=@('mounted',0,0,0);left=@('mounted',1,0,0);right=@('mounted',2,0,0);up=@('mounted',3,0,0)}
        }
    }
    animationMapConvention='[atlasId, zeroBasedRow, firstColumn, lastColumnInclusive]; only listed directions are authored'
    skinContract=@{
        heroSlots=@('body','head','face','outfit','bomb')
        frogSlots=@('body')
        equipUnit='complete skin pack: hero, heroMovement, frog, mounted'
        independentEntities=$false
        mountedIsUnifiedSprite=$true
        preserveFrameOrder=$true
        preserveGameplayBounds=$true
        overlayFramesMustMatchBody=$true
        fuseMustRemainVisible=$true
    }
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $ProjectRoot 'art/sprites/sprite-manifest.json') -Encoding UTF8
$previewData = 'window.spriteManifest = ' + ($manifest | ConvertTo-Json -Depth 12 -Compress) + ';'
$previewData | Set-Content (Join-Path $ProjectRoot 'art/sprites/sprite-manifest.js') -Encoding UTF8
Write-Output ('Measured {0} atlases with {1} nonempty frames.' -f $atlases.Count, ($atlases | ForEach-Object {$_.frames.Count} | Measure-Object -Sum).Sum)
