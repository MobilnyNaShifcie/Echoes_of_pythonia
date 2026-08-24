[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$godotExecutable = Join-Path $repositoryRoot '.tools\godot\Godot_v4.7.1-stable_win64.exe'
$projectDirectory = Join-Path $repositoryRoot 'godot'

if (-not (Test-Path -LiteralPath $godotExecutable)) {
    throw "Godot 4.7.1 was not found at: $godotExecutable"
}

& $godotExecutable --editor --path $projectDirectory
exit $LASTEXITCODE
