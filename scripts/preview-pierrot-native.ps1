[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$nativeRepository = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$nativeExecutable = Join-Path $nativeRepository 'build/validation-runtime/godot/Godot_v4.7.1-stable_win64_console.exe'
$nativeProject = Join-Path $nativeRepository 'godot'
if (-not (Test-Path -LiteralPath $nativeExecutable -PathType Leaf)) {
    throw 'Nie znaleziono lokalnego Godota. Otwórz res://tools/pierrot_native/portrait_lab.tscn w edytorze i naciśnij F6.'
}

$previousRoaming = $env:APPDATA
$previousLocal = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $nativeRepository 'build/validation-runtime/native-portrait-profile/AppData/Roaming'
    $env:LOCALAPPDATA = Join-Path $nativeRepository 'build/validation-runtime/native-portrait-profile/AppData/Local'
    New-Item -ItemType Directory -Path $env:APPDATA, $env:LOCALAPPDATA -Force | Out-Null
    # Intentionally interactive when the user runs this preview script.
    # This scene does not instantiate the game session or any save service.
    & $nativeExecutable --path $nativeProject --resolution 1440x900 'res://tools/pierrot_native/portrait_lab.tscn'
} finally {
    $env:APPDATA = $previousRoaming
    $env:LOCALAPPDATA = $previousLocal
}
