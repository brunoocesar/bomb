$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$recordPath=Join-Path $root 'art/sprites/roblox-assets.json'
$record=Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
$record.imageIds | Add-Member -NotePropertyName mounted -NotePropertyValue '91298046318312' -Force
$record.assets=@($record.assets | Where-Object key -ne mounted)+@([pscustomobject]@{
    key='mounted';sourcePath='mounted/base/mounted-v1.png';sourceSize=@(1254,1254)
    deliveredSize=@(1024,1024);imageId='91298046318312';verifiedOwnerId='204998424'
    sha256=(Get-FileHash -LiteralPath (Join-Path $root 'art/sprites/mounted/base/mounted-v1.png') -Algorithm SHA256).Hash
    uploadMethod='Roblox Studio Import Queue';resolutionCheck='CreateEditableImageAsync'
    runtimeStatus='ImageLabel loaded; four directions and ground support verified in Studio Play'
})
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $recordPath -Encoding UTF8
$manifestPath=Join-Path $root 'art/sprites/sprite-manifest.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$manifest.robloxImageIds=$record.imageIds
$manifest.integrationStatus='Four atlases uploaded and linked; unified mounted rendering verified in Studio Play. See docs/CURVAS_E_PACK_MONTADO.md for test limits.'
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
('window.spriteManifest = '+($manifest | ConvertTo-Json -Depth 12 -Compress)+';') | Set-Content -LiteralPath (Join-Path $root 'art/sprites/sprite-manifest.js') -Encoding UTF8
Write-Output 'Registered mounted atlas; existing image IDs preserved.'
