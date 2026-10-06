param([string]$Pdf = 'Mundos_Fases_Etapas_Bomb_Your_Way (1).pdf', [int[]]$Pages = @(5, 6))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Pdf.PdfPageRenderOptions, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
$taskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
function Await-Result($Operation, [Type]$ResultType) {
    $pending = $taskMethod.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $pending.Wait()
    return $pending.Result
}
$source = (Resolve-Path -LiteralPath $Pdf).Path
$file = Await-Result ([Windows.Storage.StorageFile]::GetFileFromPathAsync($source)) ([Windows.Storage.StorageFile])
$document = Await-Result ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
foreach ($number in $Pages) {
    $page = $document.GetPage($number - 1)
    $memory = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
    $options = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $options.DestinationWidth = 1400
    $operation = $page.RenderToStreamAsync($memory, $options)
    $actionMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1
    } | Select-Object -First 1
    $actionMethod.Invoke($null, @($operation)).Wait()
    $memory.Seek(0)
    $stream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($memory)
    $destination = Join-Path (Get-Location) "build/phase1-pdf-page-$number.png"
    $output = [IO.File]::Create($destination)
    try { $stream.CopyTo($output) } finally { $output.Dispose(); $stream.Dispose(); $page.Dispose() }
    Write-Output $destination
}
