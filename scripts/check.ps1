[CmdletBinding()]
param([switch]$Focused)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$toolRoot = $repositoryRoot
if ($env:ECHOES_TOOL_ROOT) { $toolRoot = (Resolve-Path -LiteralPath $env:ECHOES_TOOL_ROOT).Path }
$pythonExecutable = Join-Path $toolRoot '.venv\Scripts\python.exe'
$gdformatExecutable = Join-Path $toolRoot '.venv\Scripts\gdformat.exe'
$gdlintExecutable = Join-Path $toolRoot '.venv\Scripts\gdlint.exe'
$godotSourceDirectory = Join-Path $toolRoot '.tools\godot'
$godotConsoleName = 'Godot_v4.7.1-stable_win64_console.exe'
$godotGuiName = 'Godot_v4.7.1-stable_win64.exe'
$godotSourceExecutable = Join-Path $godotSourceDirectory $godotConsoleName
$godotSourceGui = Join-Path $godotSourceDirectory $godotGuiName
$godotDirectory = Join-Path $repositoryRoot 'godot'
$validationRoot = Join-Path $repositoryRoot 'build\validation-runtime'
$isolatedGodotDirectory = Join-Path $validationRoot 'godot'
$validationProfile = Join-Path $validationRoot 'profile'
$gdscriptPaths = @(
    (Join-Path $godotDirectory 'core'),
    (Join-Path $godotDirectory 'scenes'),
    (Join-Path $godotDirectory 'tests'),
    (Join-Path $godotDirectory 'ui')
)

foreach ($requiredExecutable in @(
    $pythonExecutable,
    $gdformatExecutable,
    $gdlintExecutable,
    $godotSourceExecutable,
    $godotSourceGui
)) {
    if (-not (Test-Path -LiteralPath $requiredExecutable)) {
        throw "Required development tool was not found: $requiredExecutable"
    }
}

New-Item -ItemType Directory -Path $isolatedGodotDirectory, $validationProfile -Force | Out-Null
foreach ($sourceExecutable in @($godotSourceExecutable, $godotSourceGui)) {
    $destinationExecutable = Join-Path $isolatedGodotDirectory (Split-Path $sourceExecutable -Leaf)
    if (
        -not (Test-Path -LiteralPath $destinationExecutable) -or
        (Get-Item -LiteralPath $destinationExecutable).Length -ne
            (Get-Item -LiteralPath $sourceExecutable).Length
    ) {
        Copy-Item -LiteralPath $sourceExecutable -Destination $destinationExecutable -Force
    }
}
$godotExecutable = Join-Path $isolatedGodotDirectory $godotConsoleName
$validationAppData = Join-Path $validationProfile 'AppData\Roaming'
$validationLocalAppData = Join-Path $validationProfile 'AppData\Local'
$gdtoolkitProfileName = 'echoes-of-pythonia-gdtoolkit-{0}' -f [guid]::NewGuid().ToString('N')
$gdtoolkitLocalAppData = Join-Path ([System.IO.Path]::GetTempPath()) $gdtoolkitProfileName
$env:APPDATA = $validationAppData
$env:LOCALAPPDATA = $gdtoolkitLocalAppData
New-Item -ItemType Directory -Path @(
    $validationAppData,
    $validationLocalAppData,
    $gdtoolkitLocalAppData
) -Force | Out-Null

Write-Host 'Validating golden-slice item assets...'
& (Join-Path $PSScriptRoot 'check-item-assets.ps1')

Write-Host 'Validating golden-slice skill-card assets...'
& (Join-Path $PSScriptRoot 'check-skill-card-assets.ps1')

Write-Host 'Validating modular Varenhold assets...'
& (Join-Path $PSScriptRoot 'check-city-assets.ps1')

Write-Host 'Checking GDScript formatting...'
& $gdformatExecutable --check @gdscriptPaths
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Linting project-owned GDScript...'
& $gdlintExecutable @gdscriptPaths
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Focused) {
    Write-Host 'AUTOPILOT_FOCUSED_ONLY: assets, format and lint; full validation required before final approval.'
    exit 0
}

$env:LOCALAPPDATA = $validationLocalAppData

Write-Host 'Running the legacy Python regression suite...'
# Avoid the shared pytest directory: another sandbox or account may own its ACL.
# Each validation run owns a fresh scratch directory inside the project.
$pytestTempRoot = Join-Path $validationRoot ('pytest-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $pytestTempRoot -Force | Out-Null
$env:PYTEST_DEBUG_TEMPROOT = $pytestTempRoot
$pytestOutput = Join-Path $repositoryRoot 'output'
$pytestBuild = Join-Path $repositoryRoot 'build'
& $pythonExecutable -m pytest -q -p no:cacheprovider --ignore $pytestOutput --ignore $pytestBuild $repositoryRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Starting the Godot bootstrap scene headlessly...'
& $godotExecutable --headless --audio-driver Dummy --rendering-method gl_compatibility `
    --path $godotDirectory --quit-after 3
if ($LASTEXITCODE -ne 0) {
    Write-Host 'AUTOPILOT_STAGE boot FAIL'
    exit $LASTEXITCODE
}

Write-Host 'Running GUT tests...'
Write-Host 'AUTOPILOT_STAGE boot PASS'
& $godotExecutable --headless --audio-driver Dummy --rendering-method gl_compatibility `
    --path $godotDirectory `
    -s 'res://addons/gut/gut_cmdln.gd' `
    -gdir='res://tests' `
    -ginclude_subdirs `
    -gexit
if ($LASTEXITCODE -eq 0) { Write-Host 'AUTOPILOT_STAGE gut PASS' }
else { Write-Host 'AUTOPILOT_STAGE gut FAIL' }
exit $LASTEXITCODE
