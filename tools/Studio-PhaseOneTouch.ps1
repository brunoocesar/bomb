# Native touch-emulator input. Uses the guarded Bomb Your Way! window only.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Studio-Desktop.ps1" -Action Capture -OutputPath build/Studio-phase1-touch-before.png
function Touch-Control([int]$pointX, [int]$pointY, [int]$holdMs) {
    if (-not $window.Current.BoundingRectangle.Contains($pointX,$pointY)) { throw 'Control outside guarded Studio window.' }
    [StudioDesktop]::SetCursorPos($pointX,$pointY) | Out-Null
    [StudioDesktop]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    try { Start-Sleep -Milliseconds $holdMs }
    finally { [StudioDesktop]::mouse_event(4,0,0,0,[UIntPtr]::Zero) }
    Start-Sleep -Milliseconds 80
}
# Coordinates measured in the current 896x414 iPhone XR landscape viewport.
Touch-Control 495 669 240
Touch-Control 940 595 50
Touch-Control 443 616 240
Touch-Control 392 669 480
Write-Output 'Native right, bomb, up and left input sent. Inspect authoritative state.'
