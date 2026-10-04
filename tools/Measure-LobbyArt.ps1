$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Collections.Generic;
public static class LobbyArtBounds {
    public static int[][] Rows(Bitmap b) {
        var runs=new List<int[]>(); int start=-1;
        for(int y=0;y<b.Height;y++) {
            bool found=false;
            for(int x=0;x<b.Width;x++) if(b.GetPixel(x,y).A>=200) {found=true;break;}
            if(found && start<0) start=y;
            if(!found && start>=0) {runs.Add(new int[]{start,y-1});start=-1;}
        }
        if(start>=0) runs.Add(new int[]{start,b.Height-1});
        return runs.ToArray();
    }
}
'@
$root=Split-Path $PSScriptRoot -Parent
$bitmap=[System.Drawing.Bitmap]::new((Join-Path $root 'art/lobby/menu-icons-v1.png'))
try {
    $runs=[LobbyArtBounds]::Rows($bitmap)
    $groups=@()
    foreach($run in $runs) {
        if($groups.Count -and $run[0]-$groups[-1][1] -lt 8) {$groups[-1][1]=$run[1]}
        else {$groups+=,@($run[0],$run[1])}
    }
    if($groups.Count -ne 3) {throw ('Expected three isolated icon rows; found '+$groups.Count)}
    $bands=@(0,[int][Math]::Floor(($groups[0][1]+$groups[1][0])/2),[int][Math]::Floor(($groups[1][1]+$groups[2][0])/2),$bitmap.Height)
    $frames=@()
    for($row=0;$row -lt 3;$row++) {for($col=0;$col -lt 4;$col++) {
        $x=[int][Math]::Round($col*$bitmap.Width/4)
        $right=[int][Math]::Round(($col+1)*$bitmap.Width/4)
        $frames+=,@($x,$bands[$row],($right-$x),($bands[$row+1]-$bands[$row]))
    }}
    $manifest=@{sourceSize=@($bitmap.Width,$bitmap.Height);rowBands=$bands;frames=$frames;icons=@('adventure','hero','frog','shop','coins','settings','profile','missions','gift','trophy','back','rotate')}
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'art/lobby/art-manifest.json') -Encoding UTF8
    $lua='return { sourceSize={'+($manifest.sourceSize -join ',')+'}, frames={'
    foreach($frame in $frames) {$lua+='{'+($frame -join ',')+'},'}
    $lua+='} }'
    [System.IO.File]::WriteAllText((Join-Path $root 'game/Shared/LobbyArt.lua'),$lua,[System.Text.UTF8Encoding]::new($false))
    Write-Output ('Lobby icons '+$bitmap.Width+'x'+$bitmap.Height+'; measured row bands '+($bands -join ','))
} finally {$bitmap.Dispose()}
