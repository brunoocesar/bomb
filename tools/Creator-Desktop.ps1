param(
    [ValidateSet('Capture','Click','Paste','Key','Inspect')][string]$Action,
    [string]$OutputPath='build/Creator-current.png',
    [string]$TextFile,
    [int]$X,
    [int]$Y,
    [string]$Keys
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class CreatorDesktop {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr info);
}
'@
[CreatorDesktop]::SetProcessDPIAware()|Out-Null
$root=[System.Windows.Automation.AutomationElement]::RootElement
$windows=$root.FindAll([System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition)
$target=$null
foreach($window in $windows){
 if($window.Current.ClassName -ne 'Chrome_WidgetWin_1'){continue}
 $address=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ClassNameProperty,'OmniboxViewViews'))
 if(-not $address){continue}
 $pattern=$null
 if($address.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern,[ref]$pattern)){
  if($pattern.Current.Value -match '^(https://)?create\.roblox\.com/dashboard(/|\?|$)'){$target=$window;break}
 }
}
if(-not $target){throw 'Verified Creator Dashboard window not found. No other page modified.'}
$handle=[IntPtr]$target.Current.NativeWindowHandle
$activator=New-Object -ComObject WScript.Shell
$activator.AppActivate($target.Current.ProcessId)|Out-Null
[CreatorDesktop]::SetForegroundWindow($handle)|Out-Null
Start-Sleep -Milliseconds 400
$foregroundPid=[uint32]0
[CreatorDesktop]::GetWindowThreadProcessId([CreatorDesktop]::GetForegroundWindow(),[ref]$foregroundPid)|Out-Null
if($foregroundPid -ne $target.Current.ProcessId){throw 'Creator Dashboard could not be focused. No input sent.'}
function Click-CreatorPoint {
 if(-not $target.Current.BoundingRectangle.Contains($X,$Y)){throw 'Click outside Creator Dashboard.'}
 [CreatorDesktop]::SetCursorPos($X,$Y)|Out-Null
 [CreatorDesktop]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
 Start-Sleep -Milliseconds 150
 [CreatorDesktop]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
switch($Action){
 'Click'{Click-CreatorPoint}
 'Paste'{if($X -or $Y){Click-CreatorPoint;[System.Windows.Forms.SendKeys]::SendWait('^a')};[System.Windows.Forms.Clipboard]::SetText([IO.File]::ReadAllText((Resolve-Path -LiteralPath $TextFile)).Trim());[System.Windows.Forms.SendKeys]::SendWait('^v')}
 'Key'{[System.Windows.Forms.SendKeys]::SendWait($Keys)}
 'Inspect'{$target.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)|Where-Object{-not $_.Current.BoundingRectangle.IsEmpty -and $_.Current.Name -ne ''}|ForEach-Object{[pscustomobject]@{Name=$_.Current.Name;Type=$_.Current.ControlType.ProgrammaticName;Bounds=$_.Current.BoundingRectangle.ToString()}}|ConvertTo-Json}
 'Capture'{
  $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bitmap=[System.Drawing.Bitmap]::new($bounds.Width,$bounds.Height)
  $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size)
  $bitmap.Save((Join-Path $PWD $OutputPath),[System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose();$bitmap.Dispose();Write-Output $OutputPath
 }
}
