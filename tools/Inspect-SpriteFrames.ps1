param([string]$Atlas = 'frog')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content (Join-Path $root 'art/sprites/sprite-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$meta = $manifest.atlases | Where-Object id -eq $Atlas
$image = [Drawing.Bitmap]::new((Join-Path $root ('art/sprites/' + $meta.path)))
$sheet = [Drawing.Bitmap]::new(($meta.columns * 205),($meta.rows * 230))
$g = [Drawing.Graphics]::FromImage($sheet)
$font = [Drawing.Font]::new('Arial',10)
$g.Clear([Drawing.Color]::FromArgb(230,235,239))
try {
 foreach ($frame in $meta.frames) {
  $sx=1.05; $w=$frame.rect[2]*$sx; $h=$frame.rect[3]*$sx
  $anchorX=$frame.column*205+102; $anchorY=$frame.row*230+207
  $x=$anchorX-$frame.groundPivot[0]*$w; $y=$anchorY-$frame.groundPivot[1]*$h
  $g.DrawImage($image,[Drawing.RectangleF]::new($x,$y,$w,$h),[Drawing.RectangleF]::new($frame.rect[0],$frame.rect[1],$frame.rect[2],$frame.rect[3]),[Drawing.GraphicsUnit]::Pixel)
  $g.DrawRectangle([Drawing.Pens]::DodgerBlue,[float]$x,[float]$y,[float]$w,[float]$h)
  $g.DrawLine([Drawing.Pens]::Gray,($frame.column*205),$anchorY,($frame.column*205+205),$anchorY)
  $g.FillEllipse([Drawing.Brushes]::DeepPink,($anchorX-3),($anchorY-3),6,6)
  $g.DrawString($frame.id,$font,[Drawing.Brushes]::Black,($frame.column*205+4),($frame.row*230+4))
 }
 $sheet.Save((Join-Path $root ('build/'+$Atlas+'-frame-inspection.png')))
} finally { $font.Dispose(); $g.Dispose(); $sheet.Dispose(); $image.Dispose() }
