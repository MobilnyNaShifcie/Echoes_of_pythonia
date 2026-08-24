[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$pythonExecutable = Join-Path $repositoryRoot '.venv\Scripts\python.exe'
$gdformatExecutable = Join-Path $repositoryRoot '.venv\Scripts\gdformat.exe'
$gdlintExecutable = Join-Path $repositoryRoot '.venv\Scripts\gdlint.exe'
$godotSourceDirectory = Join-Path $repositoryRoot '.tools\godot'
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
$env:APPDATA = Join-Path $validationProfile 'AppData\Roaming'
$env:LOCALAPPDATA = Join-Path $validationProfile 'AppData\Local'
New-Item -ItemType Directory -Path $env:APPDATA, $env:LOCALAPPDATA -Force | Out-Null

Write-Host 'Validating golden-slice item assets...'
& powershell -NoProfile -ExecutionPolicy Bypass -File `
    (Join-Path $PSScriptRoot 'check-item-assets.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Validating golden-slice skill-card assets...'
& powershell -NoProfile -ExecutionPolicy Bypass -File `
    (Join-Path $PSScriptRoot 'check-skill-card-assets.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Checking GDScript formatting...'
& $gdformatExecutable --check @gdscriptPaths
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Linting project-owned GDScript...'
& $gdlintExecutable @gdscriptPaths
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Running the legacy Python regression suite...'
& $pythonExecutable -m pytest -q -p no:cacheprovider $repositoryRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Starting the Godot bootstrap scene headlessly...'
& $godotExecutable --headless --audio-driver Dummy --rendering-method gl_compatibility `
    --path $godotDirectory --quit-after 3
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Running GUT tests...'
& $godotExecutable --headless --audio-driver Dummy --rendering-method gl_compatibility `
    --path $godotDirectory `
    -s 'res://addons/gut/gut_cmdln.gd' `
    -gdir='res://tests' `
    -ginclude_subdirs `
    -gexit
exit $LASTEXITCODE
