[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$pythonExecutable = Join-Path $repositoryRoot '.venv\Scripts\python.exe'
$gdformatExecutable = Join-Path $repositoryRoot '.venv\Scripts\gdformat.exe'
$gdlintExecutable = Join-Path $repositoryRoot '.venv\Scripts\gdlint.exe'
$godotExecutable = Join-Path $repositoryRoot '.tools\godot\Godot_v4.7.1-stable_win64_console.exe'
$godotDirectory = Join-Path $repositoryRoot 'godot'
$gdscriptPaths = @(
    (Join-Path $godotDirectory 'scenes'),
    (Join-Path $godotDirectory 'tests')
)

foreach ($requiredExecutable in @($pythonExecutable, $gdformatExecutable, $gdlintExecutable, $godotExecutable)) {
    if (-not (Test-Path -LiteralPath $requiredExecutable)) {
        throw "Required development tool was not found: $requiredExecutable"
    }
}

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
& $godotExecutable --headless --path $godotDirectory --quit-after 3
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Running GUT tests...'
& $godotExecutable --headless --path $godotDirectory `
    -s 'res://addons/gut/gut_cmdln.gd' `
    -gdir='res://tests' `
    -ginclude_subdirs `
    -gexit
exit $LASTEXITCODE
