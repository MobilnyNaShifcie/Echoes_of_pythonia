param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'
$downloadRoot = Join-Path $toolsRoot 'downloads'
$version = '4.5.13'
$archiveName = "blender-$version-windows-x64.zip"
$releaseUrl = 'https://download.blender.org/release/Blender4.5'
$archivePath = Join-Path $downloadRoot $archiveName
$checksumPath = Join-Path $downloadRoot "blender-$version.sha256"
$installRoot = Join-Path $toolsRoot "blender-$version-windows-x64"
$executable = Join-Path $installRoot 'blender.exe'

New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null
Write-Output "Downloading official SHA256 list for Blender $version LTS."
Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/blender-$version.sha256" -OutFile $checksumPath -TimeoutSec 120
$checksumLines = @(Get-Content -LiteralPath $checksumPath | Where-Object {
    $_ -match ("^[a-fA-F0-9]{64}\s+\*?" + [regex]::Escape($archiveName) + '$')
})
if ($checksumLines.Count -ne 1) {
    throw "Official checksum list does not uniquely identify $archiveName."
}
$expectedHash = ($checksumLines[0] -split '\s+')[0].ToLowerInvariant()

if (-not (Test-Path -LiteralPath $archivePath)) {
    # A failed transfer leaves a separate partial file, not a usable archive.
    $partialPath = "$archivePath.part"
    if (Test-Path -LiteralPath $partialPath) {
        throw "An earlier partial download exists at $partialPath. Inspect it before retrying."
    }
    Write-Output "Downloading $archiveName from download.blender.org."
    Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/$archiveName" -OutFile $partialPath -TimeoutSec 1800
    $downloadHash = (Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($downloadHash -ne $expectedHash) {
        throw 'Downloaded archive SHA256 does not match the official checksum. Nothing extracted.'
    }
    Move-Item -LiteralPath $partialPath -Destination $archivePath
}

$actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) {
    throw 'Existing archive SHA256 does not match the official checksum. Nothing extracted.'
}
Write-Output "Verified SHA256: $actualHash"

if (-not (Test-Path -LiteralPath $executable)) {
    if (Test-Path -LiteralPath $installRoot) {
        throw "Incomplete installation exists at $installRoot. Refusing to overwrite it."
    }
    # Validate every archive target before extracting a downloaded ZIP.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $expectedPrefix = [System.IO.Path]::GetFullPath($installRoot) + [System.IO.Path]::DirectorySeparatorChar
        foreach ($entry in $zip.Entries) {
            $targetPath = [System.IO.Path]::GetFullPath((Join-Path $toolsRoot $entry.FullName))
            if ($targetPath -ne [System.IO.Path]::GetFullPath($installRoot) -and
                -not $targetPath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Unexpected path in Blender archive: $($entry.FullName)"
            }
        }
    }
    finally {
        $zip.Dispose()
    }
    Write-Output 'Extracting portable Blender into .tools (no system installation).'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $toolsRoot)
}

if (-not (Test-Path -LiteralPath $executable)) {
    throw 'Blender executable was not found after extraction.'
}
# Blender's portable profile lives beside the runtime; existing user settings stay untouched.
New-Item -ItemType Directory -Force -Path (Join-Path $installRoot '4.5/config') | Out-Null
Write-Output "Portable Blender ready: $executable"
& $executable --background --factory-startup --version
if ($LASTEXITCODE -ne 0) {
    throw "Blender version check failed with exit code $LASTEXITCODE."
}
