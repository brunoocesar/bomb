param([string]$OutputDirectory = 'build/video-analysis')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'art/maps/map-manifest.json') | ConvertFrom-Json
$scenarios = Get-Content -Raw (Join-Path $root 'build/video-analysis/blast-preview-data.json') | ConvertFrom-Json
$normal = Get-Content -Raw (Join-Path $root 'game/Assets/TutorialUI.model.json') | ConvertFrom-Json
$wide = Get-Content -Raw (Join-Path $root 'game/Assets/TutorialCompactUI.model.json') | ConvertFrom-Json
$atlas = [System.Drawing.Bitmap]::new((Join-Path $root 'art/maps/tutorial/objects-v1.png'))
$ground = [System.Drawing.Bitmap]::new((Join-Path $root 'art/maps/tutorial/garden-ground-v1.png'))
$font = [System.Drawing.Font]::new('Arial',12,[System.Drawing.FontStyle]::Bold)
$format = [System.Drawing.StringFormat]::new()
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
function Rect($node, $parentRect) {
    $p=$node.Properties; $s=$p.Size.UDim2; $o=$p.Position.UDim2
    return [System.Drawing.RectangleF]::new(
        ($parentRect.X+$parentRect.Width*$o[0][0]+$o[0][1]),
        ($parentRect.Y+$parentRect.Height*$o[1][0]+$o[1][1]),
        ($parentRect.Width*$s[0][0]+$s[0][1]),($parentRect.Height*$s[1][0]+$s[1][1]))
}
function Sprite($graphics, $name, $dest) {
    $crop=$manifest.frames.$name
    $source=[System.Drawing.RectangleF]::new($crop[0],$crop[1],$crop[2],$crop[3])
    $graphics.DrawImage($atlas,$dest,$source,[System.Drawing.GraphicsUnit]::Pixel)
}
function Board($graphics, $scenario, $box, $blastTemplate) {
    $graphics.DrawImage($ground,$box)
    $cellSize=$box.Width/13
    foreach ($tile in $scenario.tiles.PSObject.Properties) {
        $coordinates=$tile.Name.Split(':'); $x=[int]$coordinates[0]; $y=[int]$coordinates[1]
        $name=switch ($tile.Value) { '#' {'wall'} 'E' {'energy'} default {'wood'} }
        Sprite $graphics $name ([System.Drawing.RectangleF]::new(($box.X+($x-1)*$cellSize),($box.Y+($y-1)*$cellSize),$cellSize,$cellSize))
    }
    foreach ($entry in $scenario.cells.PSObject.Properties) {
        $cell=$entry.Value
        $cellBox=[System.Drawing.RectangleF]::new(($box.X+($cell.x-1)*$cellSize),($box.Y+($cell.y-1)*$cellSize),$cellSize,$cellSize)
        foreach ($part in $blastTemplate.Children) {
            $name=$cell.parts.($part.Name)
            if ($name) { Sprite $graphics $name (Rect $part $cellBox) }
        }
    }
    $graphics.DrawRectangle([System.Drawing.Pens]::LightGray,$box.X,$box.Y,$box.Width,$box.Height)
}
try {
    $boardNode=($normal.Children | Where-Object Name -eq 'PlayArea').Children | Where-Object Name -eq 'Board'
    $blastTemplate=($boardNode.Children | Where-Object Name -eq 'Cell_1_1').Children | Where-Object Name -eq 'Blast'
    # Full-size examples of the authored responsive geometry, not Studio captures.
    foreach ($viewport in @(@(1280,680),@(812,330),@(375,600))) {
        $width=$viewport[0]; $height=$viewport[1]
        $layout=if ($width -gt $height*1.4) { $wide } else { $normal }
        $nodes=@{}; foreach ($node in $layout.Children) { $nodes[$node.Name]=$node }
        $canvas=[System.Drawing.Bitmap]::new($width,$height)
        $graphics=[System.Drawing.Graphics]::FromImage($canvas)
        try {
            $graphics.Clear([System.Drawing.Color]::FromArgb(21,43,42))
            $parentRect=[System.Drawing.RectangleF]::new(0,0,$width,$height)
            $headerBox=Rect $nodes.Header $parentRect
            $graphics.FillRectangle([System.Drawing.Brushes]::DarkSlateGray,$headerBox)
            $texts=@{ Stage='FIRST SPARK'; Energy="ENERGY`n0/2"; Stats="BOMBS READY: 1/1`nRANGE: 3 tiles"; Pause='II' }
            foreach ($child in $nodes.Header.Children) {
                if ($texts.ContainsKey($child.Name)) { $graphics.DrawString($texts[$child.Name],$font,[System.Drawing.Brushes]::White,(Rect $child $headerBox),$format) }
            }
            $graphics.DrawString('Destroy the energy crates to open the exit.',$font,[System.Drawing.Brushes]::White,(Rect $nodes.Hint $parentRect),$format)
            $statusBox=Rect $nodes.Status $parentRect
            foreach ($child in $nodes.Status.Children) {
                if ($child.Name -in @('Mount','Coins')) {
                    $graphics.DrawString($child.Properties.Text,$font,[System.Drawing.Brushes]::White,(Rect $child $statusBox),$format)
                }
            }
            $area=Rect $nodes.PlayArea $parentRect
            $boardWidth=[Math]::Min($area.Width,$area.Height*13/9); $boardHeight=$boardWidth*9/13
            $box=[System.Drawing.RectangleF]::new(($area.X+($area.Width-$boardWidth)/2),($area.Y+($area.Height-$boardHeight)/2),$boardWidth,$boardHeight)
            Board $graphics $scenarios.Blocked $box $blastTemplate
            $controlsBox=Rect $nodes.Controls $parentRect
            foreach ($button in $nodes.Controls.Children) {
                $buttonBox=Rect $button $controlsBox
                $brush=if ($button.Name -eq 'Bomb') { [System.Drawing.Brushes]::Orange } else { [System.Drawing.Brushes]::PaleGreen }
                $graphics.FillRectangle($brush,$buttonBox)
                $graphics.DrawString($button.Properties.Text,$font,[System.Drawing.Brushes]::DarkSlateGray,$buttonBox,$format)
            }
            $canvas.Save((Join-Path $root "$OutputDirectory/layout-$width-$height.png"))
        } finally { $graphics.Dispose(); $canvas.Dispose() }
    }
    $canvas=[System.Drawing.Bitmap]::new(1170,850)
    $graphics=[System.Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(21,43,42))
        $index=0
        foreach ($name in @('Open','Blocked','Chain')) {
            $box=[System.Drawing.RectangleF]::new(($index*390+10),70,370,(370*9/13))
            Board $graphics $scenarios.$name $box $blastTemplate
            $graphics.DrawString($name,$font,[System.Drawing.Brushes]::White,($index*390+10),20)
            $index++
        }
        # Enlarged view to inspect the exact joins and caps.
        Board $graphics $scenarios.Open ([System.Drawing.RectangleF]::new(235,365,700,(700*9/13))) $blastTemplate
        $canvas.Save((Join-Path $root "$OutputDirectory/blast-preview.png"))
    } finally { $graphics.Dispose(); $canvas.Dispose() }
} finally {
    $atlas.Dispose(); $ground.Dispose(); $font.Dispose(); $format.Dispose()
}
