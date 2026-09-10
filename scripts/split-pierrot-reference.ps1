param(
    [string]$ReferenceDirectory = (Join-Path $PSScriptRoot '../art_drafts/pierrot_3d_reference_02')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Technical, lossless crops explicitly approved by the user. No generation,
# resampling, mirroring, color adjustment, background removal or model upload.
Add-Type -ReferencedAssemblies @(
    [System.Drawing.Bitmap].Assembly.Location,
    [System.Drawing.Rectangle].Assembly.Location
) -TypeDefinition @'
using System;
using System.Drawing;
public static class PierrotCropVerifier {
    public static void Verify(Bitmap source, Bitmap crop, Rectangle box) {
        if (crop.Width != box.Width || crop.Height != box.Height)
            throw new InvalidOperationException("Unexpected crop dimensions.");
        for (int y = 0; y < box.Height; ++y)
            for (int x = 0; x < box.Width; ++x)
                if (source.GetPixel(box.X + x, box.Y + y).ToArgb() != crop.GetPixel(x, y).ToArgb())
                    throw new InvalidOperationException("Crop pixels differ from the approved source.");
    }
}
'@

$referencePath = (Resolve-Path -LiteralPath $ReferenceDirectory).Path
$sourcePath = Join-Path $referencePath 'pierrot_turnaround_v2.png'
$outputPath = Join-Path $referencePath 'tripo_multiview_v2'
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$views = @(
    @{ Name = 'pierrot_front_v2.png'; X = 0; Width = 548; View = 'front' },
    @{ Name = 'pierrot_back_v2.png'; X = 548; Width = 506; View = 'back' },
    @{ Name = 'pierrot_profile_facing_right_v2.png'; X = 1054; Width = 482; View = 'profile_facing_right' }
)

# All views retain source rows 0..955, keeping head/heel alignment and scale.
# Boundaries pass through the gaps between the long cloth tails, not through
# equal-width thirds (which would cut the front figure's right-hand cloth).
foreach ($view in $views) {
    $destination = Join-Path $outputPath $view.Name
    if (Test-Path -LiteralPath $destination) {
        throw "Refusing to overwrite existing reference: $destination"
    }
}
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$source = [System.Drawing.Bitmap]::new($sourcePath)
$results = @()
try {
    if ($source.Width -ne 1536 -or $source.Height -ne 1024) {
        throw 'Source dimensions changed; crop boundaries require a new visual review.'
    }
    foreach ($view in $views) {
        $box = [System.Drawing.Rectangle]::new($view.X, 0, $view.Width, 956)
        $destination = Join-Path $outputPath $view.Name
        $crop = $source.Clone($box, $source.PixelFormat)
        try {
            [PierrotCropVerifier]::Verify($source, $crop, $box)
            $crop.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $crop.Dispose()
        }
        $saved = [System.Drawing.Bitmap]::new($destination)
        try {
            [PierrotCropVerifier]::Verify($source, $saved, $box)
        } finally {
            $saved.Dispose()
        }
        $results += [ordered]@{
            file = $view.Name
            view = $view.View
            source_box_xywh = @($view.X, 0, $view.Width, 956)
            sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            pixel_equality = $true
        }
    }
} finally {
    $source.Dispose()
}
if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $sourceHash) {
    throw 'Source file changed during extraction.'
}
[ordered]@{
    source = $sourcePath
    source_sha256 = $sourceHash
    source_unchanged = $true
    method = 'System.Drawing rectangular PNG crops; exact pixel comparison before and after PNG encoding'
    output_directory = $outputPath
    views = $results
} | ConvertTo-Json -Depth 6
