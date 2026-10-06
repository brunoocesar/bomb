param(
    [ValidateSet('Capture','Command','Click','Hover','ScrollDown','Drag','HoldClick','RightClick','AssetId','Key','HoldKey','Chord','Paste','Resize','Inspect')][string]$Action,
    [string]$CommandFile,
    [string]$OutputPath = 'build/Studio-current.png',
    [int]$X,
    [int]$Y,
    [int]$EndX,
    [int]$EndY,
    [string]$Keys,
    [int]$Width,
    [int]$Height,
    [int]$DurationMs = 300
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class StudioDesktop {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr hwnd,uint flags);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd,out uint processId);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint first,uint second,bool attach);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd,int command);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hwnd,int x,int y,int width,int height,bool repaint);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr info);
    [DllImport("user32.dll")] public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr info);
}
'@
[StudioDesktop]::SetProcessDPIAware() | Out-Null
$window = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
    [System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition
) | Where-Object {
    $_.Current.ClassName -eq 'RBX::Studio::MainWindow' -and
    ($_.Current.Name.StartsWith('Bomb Your Way!') -or
        (Get-Process -Id $_.Current.ProcessId).MainWindowTitle.StartsWith('Bomb Your Way!'))
} | Select-Object -First 1
if (-not $window) { throw 'Bomb Your Way! Studio window not found. No other window was modified.' }
$handle = [StudioDesktop]::GetAncestor([IntPtr]$window.Current.NativeWindowHandle,2)
if ([StudioDesktop]::IsIconic($handle)) { [StudioDesktop]::ShowWindow($handle,9) | Out-Null }
$foreground = [StudioDesktop]::GetForegroundWindow()
$foregroundProcessId = [uint32]0
$foregroundThread = [StudioDesktop]::GetWindowThreadProcessId($foreground,[ref]$foregroundProcessId)
$currentThread = [StudioDesktop]::GetCurrentThreadId()
if ($foregroundProcessId -ne $window.Current.ProcessId) {
	$studioActivator=New-Object -ComObject WScript.Shell
	$studioActivator.AppActivate($window.Current.ProcessId) | Out-Null
	Start-Sleep -Milliseconds 100
	# Windows may deny foreground activation after a long task while VS Code is focused.
	[StudioDesktop]::keybd_event(18,0,0,[UIntPtr]::Zero)
	[StudioDesktop]::keybd_event(18,0,2,[UIntPtr]::Zero)
	[StudioDesktop]::ShowWindow($handle,9) | Out-Null
    [StudioDesktop]::AttachThreadInput($currentThread,$foregroundThread,$true) | Out-Null
    try { [StudioDesktop]::SetForegroundWindow($handle) | Out-Null }
    finally { [StudioDesktop]::AttachThreadInput($currentThread,$foregroundThread,$false) | Out-Null }
}
$focusedProcessId = [uint32]0
[StudioDesktop]::GetWindowThreadProcessId([StudioDesktop]::GetForegroundWindow(),[ref]$focusedProcessId) | Out-Null
if ($focusedProcessId -ne $window.Current.ProcessId) {
    throw 'Studio could not be focused; no mouse or keyboard action was sent.'
}
Start-Sleep -Milliseconds 300
function Click-Point([int]$pointX,[int]$pointY) {
    [StudioDesktop]::SetCursorPos($pointX,$pointY) | Out-Null
    [StudioDesktop]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    [StudioDesktop]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
switch ($Action) {
    'Drag' {
        if (-not $window.Current.BoundingRectangle.Contains($X,$Y) -or -not $window.Current.BoundingRectangle.Contains($EndX,$EndY)) { throw 'Drag target outside Studio.' }
        [StudioDesktop]::SetCursorPos($X,$Y) | Out-Null
        [StudioDesktop]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
        try {
            for ($step=1; $step -le 20; $step++) {
                [StudioDesktop]::SetCursorPos([int]($X+($EndX-$X)*$step/20),[int]($Y+($EndY-$Y)*$step/20)) | Out-Null
                Start-Sleep -Milliseconds 25
            }
        } finally { [StudioDesktop]::mouse_event(4,0,0,0,[UIntPtr]::Zero) }
        Start-Sleep -Milliseconds 500
    }
    'ScrollDown' {
        if (-not $window.Current.BoundingRectangle.Contains($X,$Y)) { throw 'Scroll target outside Studio.' }
        [StudioDesktop]::SetCursorPos($X,$Y) | Out-Null
        [StudioDesktop]::mouse_event(2048,0,0,4294966816,[UIntPtr]::Zero)
        Start-Sleep -Milliseconds 400
    }
    'Hover' { if (-not [StudioDesktop]::SetCursorPos($X,$Y)) { throw 'Windows denied cursor positioning.' }; Start-Sleep -Milliseconds 700 }
    'HoldClick' {
        if (-not $window.Current.BoundingRectangle.Contains($X,$Y)) { throw 'Click target outside Studio.' }
        [StudioDesktop]::SetCursorPos($X,$Y) | Out-Null
        [StudioDesktop]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
        try { Start-Sleep -Milliseconds 350 }
        finally { [StudioDesktop]::mouse_event(4,0,0,0,[UIntPtr]::Zero) }
    }
    'Resize' {
        if ($Width -lt 900 -or $Width -gt 1900 -or $Height -lt 700 -or $Height -gt 1000) { throw 'Invalid Studio preview window size.' }
        [StudioDesktop]::MoveWindow($handle,145,18,$Width,$Height,$true) | Out-Null
    }
    'Capture' {
        $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = [System.Drawing.Bitmap]::new($screen.Width,$screen.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($screen.X,$screen.Y,0,0,$bitmap.Size)
            $bitmap.Save([System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath)))
            Write-Output $OutputPath
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
    'Command' {
        $command = Get-Content -LiteralPath $CommandFile -Raw -Encoding UTF8
        $editor = $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,'commandBarScriptEditor'))
        if (-not $editor -or $editor.Current.BoundingRectangle.IsEmpty) { throw 'Visible Studio Command Bar not found.' }
        $bounds = $editor.Current.BoundingRectangle
        Click-Point ([int]($bounds.X+100)) ([int]($bounds.Y+$bounds.Height/2))
        [System.Windows.Forms.Clipboard]::SetText($command.Trim())
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        [System.Windows.Forms.SendKeys]::SendWait('^v')
        $run = $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,'multiLineRunButtonContainer.commandBarRunButton'))
        if (-not $run -or $run.Current.BoundingRectangle.IsEmpty) { throw 'Studio Command Bar Run button not found.' }
        $runBounds = $run.Current.BoundingRectangle
        Click-Point ([int]($runBounds.X+$runBounds.Width/2)) ([int]($runBounds.Y+$runBounds.Height/2))
        Write-Output 'Command submitted to Bomb Your Way! Studio. Inspect Studio output before relying on it.'
    }
    'Click' { Click-Point $X $Y }
    'RightClick' {
        [StudioDesktop]::SetCursorPos($X,$Y) | Out-Null
        [StudioDesktop]::mouse_event(8,0,0,0,[UIntPtr]::Zero)
        [StudioDesktop]::mouse_event(16,0,0,0,[UIntPtr]::Zero)
    }
    'AssetId' {
        $assetId = [System.Windows.Forms.Clipboard]::GetText().Trim()
        if ($assetId -notmatch '^\d+$') { throw 'Clipboard does not contain a numeric asset ID. Content was not printed.' }
        Write-Output $assetId
    }
    'Key' { [System.Windows.Forms.SendKeys]::SendWait($Keys) }
    'HoldKey' {
        if ($Keys -notmatch '^[WASD ]{1,4}$') { throw 'Only gameplay movement and bomb keys are supported.' }
        foreach ($gameKey in $Keys.ToCharArray()) {
            $virtualKey = [byte]$gameKey
            [StudioDesktop]::keybd_event($virtualKey,0,0,[UIntPtr]::Zero)
            try { Start-Sleep -Milliseconds 300 }
            finally { [StudioDesktop]::keybd_event($virtualKey,0,2,[UIntPtr]::Zero) }
        }
    }
    'Chord' {
        if ($Keys -notmatch '^[WASD ]{1,4}$' -or $DurationMs -lt 10 -or $DurationMs -gt 10000) {
            throw 'Only bounded gameplay key chords are supported.'
        }
        $pressed = @()
        try {
            foreach ($gameKey in $Keys.ToCharArray()) {
                $virtualKey = [byte]$gameKey
                [StudioDesktop]::keybd_event($virtualKey,0,0,[UIntPtr]::Zero)
                $pressed += $virtualKey
            }
            Start-Sleep -Milliseconds $DurationMs
        } finally {
            foreach ($virtualKey in $pressed) { [StudioDesktop]::keybd_event($virtualKey,0,2,[UIntPtr]::Zero) }
        }
    }
    'Paste' {
        if ($X -or $Y) { Click-Point $X $Y; [System.Windows.Forms.SendKeys]::SendWait('^a') }
        [System.Windows.Forms.Clipboard]::SetText((Get-Content -LiteralPath $CommandFile -Raw).Trim())
        [System.Windows.Forms.SendKeys]::SendWait('^v')
        if ($Keys) { [System.Windows.Forms.SendKeys]::SendWait($Keys) }
    }
    'Inspect' {
        $window.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { -not $_.Current.BoundingRectangle.IsEmpty -and ($_.Current.Name -ne '' -or $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::Edit) } |
            ForEach-Object { [pscustomobject]@{Name=$_.Current.Name;Type=$_.Current.ControlType.ProgrammaticName;Class=$_.Current.ClassName;AutomationId=$_.Current.AutomationId;Bounds=$_.Current.BoundingRectangle.ToString()} } |
            ConvertTo-Json
    }
}
