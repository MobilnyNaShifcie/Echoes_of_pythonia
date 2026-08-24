[CmdletBinding()]
param(
    [string]$AssetRoot = (Join-Path $PSScriptRoot '..\godot\assets\skills')
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$assetSpecs = @(
    @{
        RelativePath = 'warrior\power_slash.png'
        Sha256 = 'b95c856796b41a82fd7471ed3afbaf414385f858e063ae73d53f62e2827b6bc9'
    },
    @{
        RelativePath = 'hunter\precise_shot.png'
        Sha256 = 'a1f51d63e0f810236944f02006083f881eaf531e4acb5b9b79138a088546455b'
    },
    @{
        RelativePath = 'mage\fire_bolt.png'
        Sha256 = 'edbd82018f0c721d3b2c80cb7b598b0175e7005cdc9bf2bd75747df850355d5c'
    },
    @{
        RelativePath = 'pierrot\fate_thrust.png'
        Sha256 = '78510bc39a48f59e6d4902b17e0da1c75e500b4164658ed9ae0768db52e72add'
    }
)

$resolvedAssetRoot = [System.IO.Path]::GetFullPath($AssetRoot)
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($spec in $assetSpecs) {
    $path = Join-Path $resolvedAssetRoot $spec.RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing skill-card asset: $($spec.RelativePath)")
        continue
    }
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        $width = $image.Width
        $height = $image.Height
    } finally {
        $image.Dispose()
    }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    Write-Host "$($spec.RelativePath): ${width}x${height}, sha256=$hash"
    if ($width -ne 1086 -or $height -ne 1448) {
        $failures.Add("Invalid 3:4 source dimensions: $($spec.RelativePath)")
    }
    if ($hash -ne $spec.Sha256) {
        $failures.Add("Approved snapshot changed: $($spec.RelativePath)")
    }
}

if ($failures.Count -gt 0) {
    throw "Skill-card asset validation failed:`n- $($failures -join "`n- ")"
}

Write-Host "Validated $($assetSpecs.Count) approved Stage 9D skill-card assets."
