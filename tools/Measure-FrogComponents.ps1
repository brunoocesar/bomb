$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Collections.Generic;
public static class FrogComponents {
 public static int[][] Find(Bitmap image) {
  int w=image.Width,h=image.Height; bool[] seen=new bool[w*h];
  bool[] opaque=new bool[w*h];
  for(int y=0;y<h;y++) for(int x=0;x<w;x++) opaque[y*w+x]=image.GetPixel(x,y).A>=64;
  var result=new List<int[]>(); var queue=new Queue<int>();
  for(int i=0;i<w*h;i++) {
   if(seen[i]||!opaque[i]) continue;
   int minx=w,miny=h,maxx=0,maxy=0,count=0; seen[i]=true;queue.Enqueue(i);
   while(queue.Count>0) {
    int p=queue.Dequeue(), x=p%w,y=p/w; count++;
    minx=Math.Min(minx,x); miny=Math.Min(miny,y);maxx=Math.Max(maxx,x);maxy=Math.Max(maxy,y);
    for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
     int nx=x+dx,ny=y+dy;
     if(nx<0||ny<0||nx>=w||ny>=h) continue;
     int n=ny*w+nx; if(!seen[n]&&opaque[n]) {seen[n]=true;queue.Enqueue(n);}
    }
   }
   if(count>300) result.Add(new int[]{minx,miny,maxx-minx+1,maxy-miny+1,count});
  }
  return result.ToArray();
 }
}
'@
$root=Split-Path $PSScriptRoot -Parent
$image=[Drawing.Bitmap]::new((Join-Path $root 'art/sprites/frog/base/frog-clean-v1.png'))
try {
 $components=[FrogComponents]::Find($image)
 $components | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $root 'build/frog-components.json') -Encoding UTF8
 Write-Output ('Measured '+$components.Count+' primary components; original PNG untouched.')
} finally { $image.Dispose() }
