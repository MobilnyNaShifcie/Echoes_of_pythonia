[CmdletBinding()]
param(
    [string]$AssetRoot = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AssetRoot)) {
    $AssetRoot = Join-Path $PSScriptRoot '..\godot\assets\items'
}

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @(
    'System.Drawing.Common',
    'System.Drawing.Primitives',
    'System.Private.Windows.GdiPlus',
    'System.Private.Windows.Core'
) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public sealed class ItemAssetReport
{
    public int Width;
    public int Height;
    public bool HasAlpha;
    public long VisiblePixels;
    public long BorderPixels;
    public long HiddenRgbPixels;
    public long LowAlphaPixels;
    public long BrightLowAlphaPixels;
    public int MinimumMargin;
}

public static class ItemAssetInspector
{
    public static ItemAssetReport Inspect(string path)
    {
        using (var bitmap = new Bitmap(path))
        {
            var report = new ItemAssetReport {
                Width = bitmap.Width,
                Height = bitmap.Height,
                HasAlpha = Image.IsAlphaPixelFormat(bitmap.PixelFormat),
                MinimumMargin = Math.Min(bitmap.Width, bitmap.Height)
            };
            var left = bitmap.Width;
            var top = bitmap.Height;
            var right = -1;
            var bottom = -1;
            for (var y = 0; y < bitmap.Height; y++)
            {
                for (var x = 0; x < bitmap.Width; x++)
                {
                    var color = bitmap.GetPixel(x, y);
                    if (color.A == 0)
                    {
                        if (color.R != 0 || color.G != 0 || color.B != 0)
                            report.HiddenRgbPixels++;
                        continue;
                    }
                    report.VisiblePixels++;
                    left = Math.Min(left, x);
                    top = Math.Min(top, y);
                    right = Math.Max(right, x);
                    bottom = Math.Max(bottom, y);
                    if (x == 0 || y == 0 || x == bitmap.Width - 1 || y == bitmap.Height - 1)
                        report.BorderPixels++;
                    if (color.A <= 96)
                    {
                        report.LowAlphaPixels++;
                        if (color.R >= 245 && color.G >= 245 && color.B >= 245)
                            report.BrightLowAlphaPixels++;
                    }
                }
            }
            if (right >= left)
            {
                report.MinimumMargin = Math.Min(
                    Math.Min(left, top),
                    Math.Min(bitmap.Width - 1 - right, bitmap.Height - 1 - bottom)
                );
            }
            return report;
        }
    }
}
'@

$assetSpecs = @(
    @{ RelativePath = 'equipment\starter_sword.png'; Width = 512; Height = 1024 },
    @{ RelativePath = 'equipment\training_shield.png'; Width = 512; Height = 1024 },
    @{ RelativePath = 'equipment\worn_leather_armor.png'; Width = 1024; Height = 1024 },
    @{ RelativePath = 'equipment\leather_hood.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'consumables\weak_healing_potion.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'materials\whetstone.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'materials\wolf_fur.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'materials\wolf_fang.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'materials\slime_gel.png'; Width = 512; Height = 512 },
    @{ RelativePath = 'books\mastery_strength_book.png'; Width = 512; Height = 512 }
)

$resolvedAssetRoot = [System.IO.Path]::GetFullPath($AssetRoot)
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($spec in $assetSpecs) {
    $path = Join-Path $resolvedAssetRoot $spec.RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing asset: $($spec.RelativePath)")
        continue
    }
    $report = [ItemAssetInspector]::Inspect($path)
    $brightEdgeRatio = if ($report.LowAlphaPixels -gt 0) {
        $report.BrightLowAlphaPixels / $report.LowAlphaPixels
    } else {
        0.0
    }
    Write-Host (
        '{0}: {1}x{2}, visible={3}, margin={4}px, hidden-rgb={5}, bright-edge={6:P2}' -f
        $spec.RelativePath,
        $report.Width,
        $report.Height,
        $report.VisiblePixels,
        $report.MinimumMargin,
        $report.HiddenRgbPixels,
        $brightEdgeRatio
    )
    if ($report.Width -ne $spec.Width -or $report.Height -ne $spec.Height) {
        $failures.Add("Invalid dimensions: $($spec.RelativePath)")
    }
    if (-not $report.HasAlpha) {
        $failures.Add("Missing alpha channel: $($spec.RelativePath)")
    }
    if ($report.VisiblePixels -eq 0) {
        $failures.Add("Asset is fully transparent: $($spec.RelativePath)")
    }
    if ($report.BorderPixels -gt 0 -or $report.MinimumMargin -lt 8) {
        $failures.Add("Artwork touches the safe edge: $($spec.RelativePath)")
    }
    if ($report.HiddenRgbPixels -gt 0) {
        $failures.Add("Transparent pixels contain hidden RGB: $($spec.RelativePath)")
    }
    if ($report.LowAlphaPixels -gt 32 -and $brightEdgeRatio -gt 0.25) {
        $failures.Add("Possible bright alpha fringe: $($spec.RelativePath)")
    }
}

if ($failures.Count -gt 0) {
    throw "Item asset validation failed:`n- $($failures -join "`n- ")"
}

Write-Host "Validated $($assetSpecs.Count) golden-slice item assets."
