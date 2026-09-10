[CmdletBinding()]
param(
    [string]$AssetRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AssetRoot)) {
    $AssetRoot = Join-Path $PSScriptRoot '..\godot\assets\city\varenhold'
}

Add-Type -AssemblyName System.Drawing
$systemDrawingAssembly = [System.Drawing.Bitmap].Assembly.Location
Add-Type -ReferencedAssemblies @(
    $systemDrawingAssembly
) -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CityAssetInspector
{
    public static string Inspect(string path, bool allowInteriorGreen)
    {
        using (var bitmap = new Bitmap(path))
        {
            var rectangle = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var data = bitmap.LockBits(rectangle, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try
            {
                var stride = Math.Abs(data.Stride);
                var bytes = new byte[stride * bitmap.Height];
                Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
                long transparent = 0;
                long visible = 0;
                long hiddenRgb = 0;
                long brightLowAlpha = 0;
                long visibleChroma = 0;
                for (var y = 0; y < bitmap.Height; y++)
                {
                    var row = y * stride;
                    for (var x = 0; x < bitmap.Width; x++)
                    {
                        var offset = row + x * 4;
                        var blue = bytes[offset];
                        var green = bytes[offset + 1];
                        var red = bytes[offset + 2];
                        var alpha = bytes[offset + 3];
                        if (alpha == 0)
                        {
                            transparent++;
                            if (red != 0 || green != 0 || blue != 0)
                                hiddenRgb++;
                            continue;
                        }
                        visible++;
                        var dominance = green - Math.Max(red, blue);
                        var chromaLike = green > 110 && dominance > 35;
                        if (alpha <= 64 && chromaLike)
                            brightLowAlpha++;
                        if (!allowInteriorGreen && alpha > 32 && chromaLike)
                            visibleChroma++;
                    }
                }

                var failures = new List<string>();
                var total = (long)bitmap.Width * bitmap.Height;
                if (transparent < total / 20)
                    failures.Add("insufficient transparent area");
                if (visible < total / 20)
                    failures.Add("insufficient visible subject area");
                if (hiddenRgb != 0)
                    failures.Add("hidden RGB in " + hiddenRgb + " transparent pixels");
                if (brightLowAlpha != 0)
                    failures.Add("bright chroma fringe in " + brightLowAlpha + " low-alpha pixels");
                if (visibleChroma != 0)
                    failures.Add("visible chroma remnants in " + visibleChroma + " pixels");
                return string.Join("; ", failures);
            }
            finally
            {
                bitmap.UnlockBits(data);
            }
        }
    }
}
'@

$alphaAssets = @(
    @{ RelativePath = 'npcs\oren.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\garran.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\mirela.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\quartermaster.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\oren_counter_v3.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\garran_forging_v3.png'; Width = 1536; Height = 1024; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\oren_counter_v4.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\garran_forging_v4.png'; Width = 1254; Height = 1254; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\oren_counter_v6.png'; Width = 1161; Height = 1355; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\garran_forging_v5.png'; Width = 1189; Height = 1323; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\mirela_counter_v3.png'; Width = 1180; Height = 1333; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\guildmaster_desk_v2.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\runa_innkeeper_v1.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $true },
    @{ RelativePath = 'npcs\runa_innkeeper_v2.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $false },
    @{ RelativePath = 'npcs\runa_innkeeper_v3.png'; Width = 1024; Height = 1536; AllowInteriorGreen = $false },
    @{ RelativePath = 'modules\guild_hall.png'; Width = 1672; Height = 941; AllowInteriorGreen = $false }
)

$opaqueAssets = @(
    @{ RelativePath = 'backgrounds\guild_district_base.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'backgrounds\varenhold_city_plan.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'backgrounds\varenhold_main_menu.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\guild_hall.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\guild_hall_v2.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\garran_forge.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\garran_forge_v2.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\inn_tavern_v1.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\inn_tavern_informant_v1.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\mirela_workshop.png'; Width = 1672; Height = 941 },
    @{ RelativePath = 'interiors\oren_stall.png'; Width = 1672; Height = 941 }
)

$resolvedAssetRoot = [System.IO.Path]::GetFullPath($AssetRoot)
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($spec in $alphaAssets) {
    $path = Join-Path $resolvedAssetRoot $spec.RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing asset: $($spec.RelativePath)")
        continue
    }
    $image = [System.Drawing.Bitmap]::new($path)
    try {
        if ($image.Width -ne $spec.Width -or $image.Height -ne $spec.Height) {
            $failures.Add("Unexpected dimensions: $($spec.RelativePath) ($($image.Width)x$($image.Height))")
        }
        if (($image.PixelFormat -band [System.Drawing.Imaging.PixelFormat]::Alpha) -eq 0) {
            $failures.Add("Missing alpha channel: $($spec.RelativePath)")
        }
        $corners = @(
            $image.GetPixel(0, 0),
            $image.GetPixel($image.Width - 1, 0),
            $image.GetPixel(0, $image.Height - 1),
            $image.GetPixel($image.Width - 1, $image.Height - 1)
        )
        if (($corners | Where-Object { $_.A -ne 0 }).Count -gt 0) {
            $failures.Add("Opaque corner after chroma extraction: $($spec.RelativePath)")
        }
        $inspection = [CityAssetInspector]::Inspect($path, [bool]$spec.AllowInteriorGreen)
        if ($inspection) {
            $failures.Add("Alpha quality failure: $($spec.RelativePath) ($inspection)")
        }
    }
    finally {
        $image.Dispose()
    }
}

foreach ($spec in $opaqueAssets) {
    $path = Join-Path $resolvedAssetRoot $spec.RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing asset: $($spec.RelativePath)")
        continue
    }
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $spec.Width -or $image.Height -ne $spec.Height) {
            $failures.Add("Unexpected dimensions: $($spec.RelativePath) ($($image.Width)x$($image.Height))")
        }
    }
    finally {
        $image.Dispose()
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "City asset gate passed: $($alphaAssets.Count) alpha assets and $($opaqueAssets.Count) opaque backgrounds."
