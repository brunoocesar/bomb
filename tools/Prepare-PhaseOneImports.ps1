$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$folder = Join-Path $root 'art/maps/world1/import'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$files = @{
    'phase1-objects-v1.png' = 'BombYourWay-Phase1Objects-v1.png'
    'entrance-ground-v1.png' = 'BombYourWay-Phase1Entrance-v1.png'
    'sun-courtyard-ground-v1.png' = 'BombYourWay-Phase1Courtyard-v1.png'
}
$records = @()
foreach ($source in $files.Keys) {
    $original = [Drawing.Bitmap]::new((Join-Path $root "art/maps/world1/$source"))
    try {
        $scale = [Math]::Min(1.0, 1024.0 / [Math]::Max($original.Width, $original.Height))
        $width = [int][Math]::Round($original.Width * $scale)
        $height = [int][Math]::Round($original.Height * $scale)
        $result = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [Drawing.Graphics]::FromImage($result)
        try {
            $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($original, 0, 0, $width, $height)
            $target = Join-Path $folder $files[$source]
            $result.Save($target, [Drawing.Imaging.ImageFormat]::Png)
            $records += [ordered]@{file=$files[$source];size=@($width,$height);sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash}
        } finally { $graphics.Dispose(); $result.Dispose() }
    } finally { $original.Dispose() }
}
[IO.File]::WriteAllText((Join-Path $folder 'manifest.json'), ($records | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
$records | ConvertTo-Json -Depth 6
