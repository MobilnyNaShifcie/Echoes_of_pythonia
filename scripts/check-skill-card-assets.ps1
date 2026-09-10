[CmdletBinding()]
param(
    [string]$AssetRoot = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AssetRoot)) {
    $AssetRoot = Join-Path $PSScriptRoot '..\godot\assets\skills'
}

Add-Type -AssemblyName System.Drawing

$assetSpecs = @(
    @{
        RelativePath = 'warrior\power_slash.png'
        Sha256 = 'b95c856796b41a82fd7471ed3afbaf414385f858e063ae73d53f62e2827b6bc9'
    },
    @{
        RelativePath = 'warrior\armor_break.png'
        Sha256 = '6793fa0bf5bd68165dbd7f070748bbf858d69f95e2acfc601a86b4069235a932'
    },
    @{
        RelativePath = 'warrior\defensive_stance.png'
        Sha256 = 'b250e08bb893ddc6a87723cd927f1f87e4592e4687c0168a7d4c526e70e2411c'
    },
    @{
        RelativePath = 'warrior\blood_strike.png'
        Sha256 = 'f5297ef0e2a61b54097988cf30e29aee6328fd27a97ad8ffb80d084765dc132d'
    },
    @{
        RelativePath = 'warrior\shield_bash.png'
        Sha256 = '214816da33dda3e52789d332dd080d0091af893d731f9fcb69a8f1e26c756336'
    },
    @{
        RelativePath = 'warrior\provoke.png'
        Sha256 = 'b5181474ef37a3a4b31707766a99196aea5afc3765a30e963dee88241d492e9c'
    },
    @{
        RelativePath = 'hunter\precise_shot.png'
        Sha256 = 'a1f51d63e0f810236944f02006083f881eaf531e4acb5b9b79138a088546455b'
    },
    @{
        RelativePath = 'hunter\bleeding_shot.png'
        Sha256 = '7a528bdb87c0725a963fb1c4da338a2aba71b5fb07dc8015780b1d7a3e58512c'
    },
    @{
        RelativePath = 'hunter\shadow_step.png'
        Sha256 = '9c64116fb761915fa9ae9801662370a0eab723a978b02b26acc74aafbc778e2a'
    },
    @{
        RelativePath = 'hunter\double_shot.png'
        Sha256 = '4a8b132ece0cf8216c37b86ce5ae9fb0fb5e3a84a0d3be213e9c1e097af870a0'
    },
    @{
        RelativePath = 'hunter\piercing_arrow.png'
        Sha256 = 'd7f8805b0a3f07857e50b58562c04b5ec5fcd2982d30bceaea3d7a0e7a53bf36'
    },
    @{
        RelativePath = 'hunter\frost_arrow.png'
        Sha256 = '2873e79fb404a13fb804be0bc6e668bf7c12be8bdc39d248a9dd0b7a972c4d70'
    },
    @{
        RelativePath = 'hunter\explosive_arrow.png'
        Sha256 = '170a7588d3f030bb64e1d767a606119f1192fa9cb58bc5f704583f1d8d4748bf'
    },
    @{
        RelativePath = 'hunter\phantom_arrow.png'
        Sha256 = '2fd0f8195225a5292077b0f93dc1326ed5fdefd034bcb6091d58e1b6a9b16c18'
    },
    @{
        RelativePath = 'hunter\rain_of_arrows.png'
        Sha256 = 'b5568d237c582495a25758de0704c181be033cdd634834bfa5ad3b6e9d2ea9a0'
    },
    @{
        RelativePath = 'hunter\splitting_arrow.png'
        Sha256 = '08ad193486d1f3a3ac222d0cd8eae1518f07adc7ae3d6d14aa3cf4b294f4ddf8'
    },
    @{
        RelativePath = 'hunter\thousand_arrows.png'
        Sha256 = '13ae202c33e7297c739ef69e2d54d4f1c03ee34d9aa31b18fe63934fdd983a55'
    },
    @{
        RelativePath = 'mage\fire_bolt.png'
        Sha256 = 'edbd82018f0c721d3b2c80cb7b598b0175e7005cdc9bf2bd75747df850355d5c'
    },
    @{
        RelativePath = 'mage\frost_lance.png'
        Sha256 = 'f07aee5af76cc4e0e99116cd3ee2ca4f0bc6ce7714466a655df6a56f143017bb'
    },
    @{
        RelativePath = 'mage\lightning.png'
        Sha256 = '42191d66fd925b119605df08c3f5d5f73a78a47c9d97a453ef84fa776552456a'
    },
    @{
        RelativePath = 'mage\mana_burst.png'
        Sha256 = '451046b168053ab98335b18a61e0a02cd8637a8b0122d4d85e7c57dda23b223f'
    },
    @{
        RelativePath = 'pierrot\fate_thrust.png'
        Sha256 = '78510bc39a48f59e6d4902b17e0da1c75e500b4164658ed9ae0768db52e72add'
    },
    @{
        RelativePath = 'pierrot\double_roll.png'
        Sha256 = 'd8a622092a80bc109686fb0451c873922dab80333c4cd9b64a9594422af34084'
    },
    @{
        RelativePath = 'pierrot\fate_feint.png'
        Sha256 = '663fd2ec6db3acce19b2bcbf77c1d421d81a18e5517d2f05d0587b8213e9c19e'
    },
    @{
        RelativePath = 'pierrot\grand_gamble.png'
        Sha256 = 'ee5c60af06601cececf202165b9e03529dedc0244dc2db5dece6bf7735c1c822'
    },
    @{
        RelativePath = 'pierrot\va_banque.png'
        Sha256 = '191dd5703e9216bf53ccd381a7db2b5695caf2929aff0414cd2d1ae6ff10185f'
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
