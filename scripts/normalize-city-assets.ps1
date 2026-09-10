[CmdletBinding()]
param(
    [string]$SourceRoot = '',
    [string]$DestinationRoot = '',
    [switch]$RefreshSceneCharacters
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Join-Path $PSScriptRoot '..\build\art_review\stage_9e\approved_sources'
}
if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $DestinationRoot = Join-Path $PSScriptRoot '..\godot\assets\city\varenhold'
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
using System.IO;
using System.Runtime.InteropServices;

public static class CityAssetNormalizer
{
    public static void NormalizeAlpha(string sourcePath, string destinationPath)
    {
        using (var source = new Bitmap(sourcePath))
        using (var target = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(target))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            var rectangle = new Rectangle(0, 0, target.Width, target.Height);
            var data = target.LockBits(rectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            try
            {
                var stride = Math.Abs(data.Stride);
                var bytes = new byte[stride * target.Height];
                Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
                for (var y = 0; y < target.Height; y++)
                {
                    var row = y * stride;
                    for (var x = 0; x < target.Width; x++)
                    {
                        var offset = row + x * 4;
                        if (bytes[offset + 3] <= 3)
                        {
                            bytes[offset] = 0;
                            bytes[offset + 1] = 0;
                            bytes[offset + 2] = 0;
                            bytes[offset + 3] = 0;
                        }
                    }
                }
                Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
            }
            finally
            {
                target.UnlockBits(data);
            }

            var directory = Path.GetDirectoryName(destinationPath);
            Directory.CreateDirectory(directory);
            target.Save(destinationPath, ImageFormat.Png);
        }
    }

    public static void ExtractChroma(
        string sourcePath,
        string destinationPath,
        bool preserveInteriorGreen
    )
    {
        using (var source = new Bitmap(sourcePath))
        using (var target = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            var sourceRect = new Rectangle(0, 0, source.Width, source.Height);
            var sourceData = source.LockBits(sourceRect, ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
            var targetData = target.LockBits(sourceRect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            try
            {
                var sourceStride = Math.Abs(sourceData.Stride);
                var targetStride = Math.Abs(targetData.Stride);
                var sourceBytes = new byte[sourceStride * source.Height];
                var targetBytes = new byte[targetStride * target.Height];
                Marshal.Copy(sourceData.Scan0, sourceBytes, 0, sourceBytes.Length);

                var key = EstimateKeyColor(sourceBytes, sourceStride, source.Width, source.Height);
                var keyDominance = Math.Max(1.0, key.G - Math.Max(key.R, key.B));
                var keyGreenRange = Math.Max(1.0, key.G - 70.0);
                var strongKeyPixels = new bool[source.Width * source.Height];
                var strongKeyThreshold = preserveInteriorGreen ? 0.55 : 0.18;

                for (var y = 0; y < source.Height; y++)
                {
                    var sourceRow = y * sourceStride;
                    for (var x = 0; x < source.Width; x++)
                    {
                        var sourceOffset = sourceRow + x * 3;
                        var blue = sourceBytes[sourceOffset];
                        var green = sourceBytes[sourceOffset + 1];
                        var red = sourceBytes[sourceOffset + 2];
                        var dominance = green - Math.Max(red, blue);
                        var chromaAmount = Clamp(dominance / keyDominance);
                        var brightnessAmount = Clamp((green - 70.0) / keyGreenRange);
                        strongKeyPixels[y * source.Width + x] =
                            Math.Min(chromaAmount, brightnessAmount) >= strongKeyThreshold;
                    }
                }

                for (var y = 0; y < source.Height; y++)
                {
                    var sourceRow = y * sourceStride;
                    var targetRow = y * targetStride;
                    for (var x = 0; x < source.Width; x++)
                    {
                        var sourceOffset = sourceRow + x * 3;
                        var targetOffset = targetRow + x * 4;
                        var blue = sourceBytes[sourceOffset];
                        var green = sourceBytes[sourceOffset + 1];
                        var red = sourceBytes[sourceOffset + 2];

                        var dominance = green - Math.Max(red, blue);
                        var chromaAmount = Clamp(dominance / keyDominance);
                        var isStrongKey = strongKeyPixels[y * source.Width + x];
                        var isKeyEdge = !isStrongKey && HasStrongKeyNeighbor(
                            strongKeyPixels,
                            source.Width,
                            source.Height,
                            x,
                            y,
                            3
                        );
                        var keyAmount = isStrongKey
                            ? 1.0
                            : isKeyEdge && dominance >= 4
                                ? chromaAmount
                                : 0.0;

                        var alpha = (byte)Math.Round(255.0 * (1.0 - keyAmount));
                        if (alpha <= 3)
                        {
                            targetBytes[targetOffset] = 0;
                            targetBytes[targetOffset + 1] = 0;
                            targetBytes[targetOffset + 2] = 0;
                            targetBytes[targetOffset + 3] = 0;
                            continue;
                        }

                        var outputBlue = (double)blue;
                        var outputGreen = (double)green;
                        var outputRed = (double)red;
                        if (alpha < 252)
                        {
                            var foregroundShare = alpha / 255.0;
                            var backgroundShare = 1.0 - foregroundShare;
                            outputBlue = (blue - backgroundShare * key.B) / foregroundShare;
                            outputGreen = (green - backgroundShare * key.G) / foregroundShare;
                            outputRed = (red - backgroundShare * key.R) / foregroundShare;
                        }

                        targetBytes[targetOffset] = ToByte(outputBlue);
                        targetBytes[targetOffset + 1] = ToByte(outputGreen);
                        targetBytes[targetOffset + 2] = ToByte(outputRed);
                        targetBytes[targetOffset + 3] = alpha;
                    }
                }

                Marshal.Copy(targetBytes, 0, targetData.Scan0, targetBytes.Length);
            }
            finally
            {
                source.UnlockBits(sourceData);
                target.UnlockBits(targetData);
            }

            var directory = Path.GetDirectoryName(destinationPath);
            Directory.CreateDirectory(directory);
            target.Save(destinationPath, ImageFormat.Png);
        }
    }

    private static Color EstimateKeyColor(byte[] bytes, int stride, int width, int height)
    {
        long red = 0;
        long green = 0;
        long blue = 0;
        long count = 0;
        var sampleWidth = Math.Max(8, width / 32);
        var sampleHeight = Math.Max(8, height / 32);
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var inCorner =
                    (x < sampleWidth || x >= width - sampleWidth) &&
                    (y < sampleHeight || y >= height - sampleHeight);
                if (!inCorner)
                    continue;
                var offset = y * stride + x * 3;
                blue += bytes[offset];
                green += bytes[offset + 1];
                red += bytes[offset + 2];
                count++;
            }
        }
        return Color.FromArgb(
            (int)(red / count),
            (int)(green / count),
            (int)(blue / count)
        );
    }

    private static bool HasStrongKeyNeighbor(
        bool[] mask,
        int width,
        int height,
        int centerX,
        int centerY,
        int radius
    )
    {
        var left = Math.Max(0, centerX - radius);
        var top = Math.Max(0, centerY - radius);
        var right = Math.Min(width - 1, centerX + radius);
        var bottom = Math.Min(height - 1, centerY + radius);
        for (var y = top; y <= bottom; y++)
        {
            for (var x = left; x <= right; x++)
            {
                if (mask[y * width + x])
                    return true;
            }
        }
        return false;
    }

    private static double Clamp(double value)
    {
        return Math.Max(0.0, Math.Min(1.0, value));
    }

    private static byte ToByte(double value)
    {
        return (byte)Math.Round(Math.Max(0.0, Math.Min(255.0, value)));
    }
}
'@

$alphaAssets = @(
    @{ Source = 'npc_oren_source.png'; RelativePath = 'npcs\oren.png'; PreserveInteriorGreen = $true },
    @{ Source = 'npc_garran_source.png'; RelativePath = 'npcs\garran.png'; PreserveInteriorGreen = $true },
    @{ Source = 'npc_mirela_source.png'; RelativePath = 'npcs\mirela.png'; PreserveInteriorGreen = $true },
    @{ Source = 'npc_quartermaster_source.png'; RelativePath = 'npcs\quartermaster.png'; PreserveInteriorGreen = $true },
    @{ Source = 'guild_hall_module_source.png'; RelativePath = 'modules\guild_hall.png'; PreserveInteriorGreen = $false }
)

$opaqueAssets = @(
    @{ Source = 'guild_district_base_source.png'; RelativePath = 'backgrounds\guild_district_base.png' },
    @{ Source = 'guild_hall_interior_source.png'; RelativePath = 'interiors\guild_hall.png' }
)

$resolvedSourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$resolvedDestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)

if ($RefreshSceneCharacters) {
    $sceneAlphaAssets = @(
        @{ Source = 'npc_mirela_counter_alpha.png'; RelativePath = 'npcs\mirela_counter_v2.png'; Mode = 'alpha' },
        @{ Source = 'npc_oren_counter_v3_green.png'; RelativePath = 'npcs\oren_counter_v3.png'; Mode = 'chroma' },
        @{ Source = 'npc_garran_forging_v3_green.png'; RelativePath = 'npcs\garran_forging_v3.png'; Mode = 'chroma' },
        @{ Source = 'npc_oren_counter_v4_green.png'; RelativePath = 'npcs\oren_counter_v4.png'; Mode = 'chroma' },
        @{ Source = 'npc_garran_forging_v4_green.png'; RelativePath = 'npcs\garran_forging_v4.png'; Mode = 'chroma' },
        @{ Source = 'npc_oren_counter_v5_green.png'; RelativePath = 'npcs\oren_counter_v5.png'; Mode = 'chroma' },
        @{ Source = 'npc_garran_forging_v5_green.png'; RelativePath = 'npcs\garran_forging_v5.png'; Mode = 'chroma' },
        @{ Source = 'npc_guildmaster_desk_alpha.png'; RelativePath = 'npcs\guildmaster_desk_v2.png'; Mode = 'alpha' },
        @{ Source = 'npc_runa_innkeeper_v1_green.png'; RelativePath = 'npcs\runa_innkeeper_v1.png'; Mode = 'chroma' },
        @{ Source = 'npc_runa_polishing_v2_green.png'; RelativePath = 'npcs\runa_innkeeper_v2.png'; Mode = 'chroma'; PreserveInteriorGreen = $false },
        @{ Source = 'npc_runa_polishing_v3_green.png'; RelativePath = 'npcs\runa_innkeeper_v3.png'; Mode = 'chroma'; PreserveInteriorGreen = $false }
    )
    foreach ($spec in $sceneAlphaAssets) {
        $sourcePath = Join-Path $resolvedSourceRoot $spec.Source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing scene source asset: $sourcePath"
        }
        $destinationPath = Join-Path $resolvedDestinationRoot $spec.RelativePath
        if ($spec.Mode -eq 'alpha') {
            [CityAssetNormalizer]::NormalizeAlpha($sourcePath, $destinationPath)
        }
        else {
            $preserveInteriorGreen = if ($spec.ContainsKey('PreserveInteriorGreen')) {
                [bool]$spec.PreserveInteriorGreen
            }
            else {
                $true
            }
            [CityAssetNormalizer]::ExtractChroma(
                $sourcePath,
                $destinationPath,
                $preserveInteriorGreen
            )
        }
        Write-Host "Prepared scene character: $($spec.Source) -> $($spec.RelativePath)"
    }

    $hallSource = Join-Path $resolvedSourceRoot 'guild_hall_v2.png'
    if (-not (Test-Path -LiteralPath $hallSource)) {
        throw "Missing scene source asset: $hallSource"
    }
    $hallDestination = Join-Path $resolvedDestinationRoot 'interiors\guild_hall_v2.png'
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $hallDestination)) | Out-Null
    Copy-Item -LiteralPath $hallSource -Destination $hallDestination -Force
    Write-Host 'Copied scene background: guild_hall_v2.png -> interiors\guild_hall_v2.png'

    $tavernSource = Join-Path $resolvedSourceRoot 'inn_tavern_v1.png'
    if (-not (Test-Path -LiteralPath $tavernSource)) {
        throw "Missing scene source asset: $tavernSource"
    }
    $tavernDestination = Join-Path $resolvedDestinationRoot 'interiors\inn_tavern_v1.png'
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $tavernDestination)) | Out-Null
    Copy-Item -LiteralPath $tavernSource -Destination $tavernDestination -Force
    Write-Host 'Copied scene background: inn_tavern_v1.png -> interiors\inn_tavern_v1.png'

    $informantTavernSource = Join-Path $resolvedSourceRoot 'inn_tavern_informant_v1.png'
    if (-not (Test-Path -LiteralPath $informantTavernSource)) {
        throw "Missing scene source asset: $informantTavernSource"
    }
    $informantTavernDestination = Join-Path $resolvedDestinationRoot 'interiors\inn_tavern_informant_v1.png'
    Copy-Item -LiteralPath $informantTavernSource -Destination $informantTavernDestination -Force
    Write-Host 'Copied scene background: inn_tavern_informant_v1.png -> interiors\inn_tavern_informant_v1.png'
    return
}

foreach ($spec in $alphaAssets) {
    $sourcePath = Join-Path $resolvedSourceRoot $spec.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing approved source asset: $sourcePath"
    }
    $destinationPath = Join-Path $resolvedDestinationRoot $spec.RelativePath
    [CityAssetNormalizer]::ExtractChroma(
        $sourcePath,
        $destinationPath,
        [bool]$spec.PreserveInteriorGreen
    )
    Write-Host "Extracted chroma: $($spec.Source) -> $($spec.RelativePath)"
}

foreach ($spec in $opaqueAssets) {
    $sourcePath = Join-Path $resolvedSourceRoot $spec.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing approved source asset: $sourcePath"
    }
    $destinationPath = Join-Path $resolvedDestinationRoot $spec.RelativePath
    $destinationDirectory = Split-Path -Parent $destinationPath
    [System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    Write-Host "Copied opaque background: $($spec.Source) -> $($spec.RelativePath)"
}
