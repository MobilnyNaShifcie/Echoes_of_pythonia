[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$godotExecutable = Join-Path $repositoryRoot '.tools\godot\Godot_v4.7.1-stable_win64_console.exe'
$godotDirectory = Join-Path $repositoryRoot 'godot'
$outputDirectory = Join-Path $repositoryRoot 'build\windows'
$outputPath = Join-Path $outputDirectory 'Echoes_of_Pythonia_v0.25.0.exe'
$packagePath = [System.IO.Path]::ChangeExtension($outputPath, '.pck')

if (-not (Test-Path -LiteralPath $godotExecutable)) {
    throw "Godot 4.7.1 was not found at: $godotExecutable"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$arguments = @(
    '--headless'
    '--path'
    ('"{0}"' -f $godotDirectory)
    '--export-debug'
    '"Windows Desktop"'
    ('"{0}"' -f $outputPath)
)
$exportStartedAt = [DateTime]::UtcNow
$process = Start-Process `
    -FilePath $godotExecutable `
    -ArgumentList $arguments `
    -Wait `
    -PassThru `
    -WindowStyle Hidden
if ($process.ExitCode -ne 0) { exit $process.ExitCode }

if (-not (Test-Path -LiteralPath $outputPath)) {
    throw "Godot reported success but the Windows build was not created."
}
if (-not (Test-Path -LiteralPath $packagePath)) {
    throw "Godot reported success but the Windows resource package was not created."
}
if ((Get-Item -LiteralPath $outputPath).LastWriteTimeUtc -lt $exportStartedAt) {
    throw "Godot did not refresh the Windows executable during this export."
}
if ((Get-Item -LiteralPath $packagePath).LastWriteTimeUtc -lt $exportStartedAt) {
    throw "Godot did not refresh the Windows resource package during this export."
}

Write-Host "Windows build created and verified: $outputPath"
