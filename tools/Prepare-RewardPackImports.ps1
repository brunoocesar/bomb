$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$folder = Join-Path $root 'art/sprites/rewards/import'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$records = @()
foreach ($variant in @('cream', 'scarf')) {
    foreach ($form in @('hero', 'hero-movement', 'mounted')) {
        $family = if ($form -eq 'mounted') { 'mounted' } else { 'hero' }
        $source = Join-Path $root "art/sprites/$family/$variant/$form-$variant-v1.png"
        $original = [Drawing.Bitmap]::new($source)
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
                $name = "BombYourWay-$form-$variant-v1.png"
                $target = Join-Path $folder $name
                $result.Save($target, [Drawing.Imaging.ImageFormat]::Png)
                $records += [ordered]@{file=$name; source=$source; size=@($width,$height); sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash}
            } finally { $graphics.Dispose(); $result.Dispose() }
        } finally { $original.Dispose() }
    }
}
[IO.File]::WriteAllText((Join-Path (Split-Path $folder -Parent) 'import-manifest.json'), ($records | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
$records | ConvertTo-Json -Depth 6
