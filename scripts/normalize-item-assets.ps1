[CmdletBinding()]
param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\build\art_review\stage_9c\items'),
    [string]$DestinationRoot = (Join-Path $PSScriptRoot '..\godot\assets\items')
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @(
    'System.Drawing.Common',
    'System.Drawing.Primitives',
    'System.Private.Windows.GdiPlus',
    'System.Private.Windows.Core'
) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ItemAssetNormalizer
{
    public static void Normalize(string sourcePath, string destinationPath, int width, int height)
    {
        using (var source = new Bitmap(sourcePath))
        {
            var bounds = AlphaBounds(source, 3);
            if (bounds.Width <= 0 || bounds.Height <= 0)
                throw new InvalidOperationException("Asset has no visible pixels: " + sourcePath);

            using (var target = new Bitmap(width, height, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(target))
            using (var attributes = new ImageAttributes())
            {
                graphics.Clear(Color.Transparent);
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.CompositingQuality = CompositingQuality.HighQuality;
                graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                graphics.SmoothingMode = SmoothingMode.HighQuality;
                attributes.SetWrapMode(WrapMode.TileFlipXY);

                const double safeArea = 0.84;
                var scale = Math.Min(
                    width * safeArea / bounds.Width,
                    height * safeArea / bounds.Height
                );
                var drawWidth = Math.Max(1, (int)Math.Round(bounds.Width * scale));
                var drawHeight = Math.Max(1, (int)Math.Round(bounds.Height * scale));
                var destination = new Rectangle(
                    (width - drawWidth) / 2,
                    (height - drawHeight) / 2,
                    drawWidth,
                    drawHeight
                );
                graphics.DrawImage(
                    source,
                    destination,
                    bounds.X,
                    bounds.Y,
                    bounds.Width,
                    bounds.Height,
                    GraphicsUnit.Pixel,
                    attributes
                );

                ClearInvisibleRgb(target, 3);
                var directory = System.IO.Path.GetDirectoryName(destinationPath);
                System.IO.Directory.CreateDirectory(directory);
                target.Save(destinationPath, ImageFormat.Png);
            }
        }
    }

    private static Rectangle AlphaBounds(Bitmap bitmap, byte threshold)
    {
        var left = bitmap.Width;
        var top = bitmap.Height;
        var right = -1;
        var bottom = -1;
        for (var y = 0; y < bitmap.Height; y++)
        {
            for (var x = 0; x < bitmap.Width; x++)
            {
                if (bitmap.GetPixel(x, y).A <= threshold)
                    continue;
                left = Math.Min(left, x);
                top = Math.Min(top, y);
                right = Math.Max(right, x);
                bottom = Math.Max(bottom, y);
            }
        }
        return right < left ? Rectangle.Empty : Rectangle.FromLTRB(left, top, right + 1, bottom + 1);
    }

    private static void ClearInvisibleRgb(Bitmap bitmap, byte threshold)
    {
        var rectangle = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
        var data = bitmap.LockBits(rectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        try
        {
            var bytes = new byte[Math.Abs(data.Stride) * bitmap.Height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
            for (var y = 0; y < bitmap.Height; y++)
            {
                var row = y * Math.Abs(data.Stride);
                for (var x = 0; x < bitmap.Width; x++)
                {
                    var offset = row + x * 4;
                    if (bytes[offset + 3] > threshold)
                        continue;
                    bytes[offset] = 0;
                    bytes[offset + 1] = 0;
                    bytes[offset + 2] = 0;
                    bytes[offset + 3] = 0;
                }
            }
            Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
        }
        finally
        {
            bitmap.UnlockBits(data);
        }
    }
}
'@

$assetSpecs = @(
    @{ Source = 'starter_sword_v01.png'; RelativePath = 'equipment\starter_sword.png'; Width = 512; Height = 1024 },
    @{ Source = 'training_shield_v01.png'; RelativePath = 'equipment\training_shield.png'; Width = 512; Height = 1024 },
    @{ Source = 'worn_leather_armor_v01.png'; RelativePath = 'equipment\worn_leather_armor.png'; Width = 1024; Height = 1024 },
    @{ Source = 'leather_hood_v01.png'; RelativePath = 'equipment\leather_hood.png'; Width = 512; Height = 512 },
    @{ Source = 'weak_healing_potion_v01.png'; RelativePath = 'consumables\weak_healing_potion.png'; Width = 512; Height = 512 },
    @{ Source = 'whetstone_v01.png'; RelativePath = 'materials\whetstone.png'; Width = 512; Height = 512 },
    @{ Source = 'wolf_fur_v02.png'; RelativePath = 'materials\wolf_fur.png'; Width = 512; Height = 512 },
    @{ Source = 'wolf_fang_v01.png'; RelativePath = 'materials\wolf_fang.png'; Width = 512; Height = 512 },
    @{ Source = 'slime_gel_v01.png'; RelativePath = 'materials\slime_gel.png'; Width = 512; Height = 512 },
    @{ Source = 'mastery_strength_book_v01.png'; RelativePath = 'books\mastery_strength_book.png'; Width = 512; Height = 512 }
)

$resolvedSourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$resolvedDestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)

foreach ($spec in $assetSpecs) {
    $sourcePath = Join-Path $resolvedSourceRoot $spec.Source
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing approved source asset: $sourcePath"
    }
    $destinationPath = Join-Path $resolvedDestinationRoot $spec.RelativePath
    [ItemAssetNormalizer]::Normalize(
        $sourcePath,
        $destinationPath,
        [int]$spec.Width,
        [int]$spec.Height
    )
    Write-Host "Normalized $($spec.Source) -> $($spec.RelativePath) ($($spec.Width)x$($spec.Height))"
}
