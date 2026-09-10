param([switch]$SkipBlender)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$blender = Join-Path $projectRoot '.tools/blender-4.5.13-windows-x64/blender.exe'
$godot = Join-Path $projectRoot 'build/validation-runtime/godot/Godot_v4.7.1-stable_win64_console.exe'
$testProject = Join-Path $projectRoot 'tools/character_3d_smoke'
$profile = Join-Path $projectRoot 'build/validation-runtime/character-3d-profile'
foreach ($executable in @($blender, $godot)) {
    if (-not (Test-Path -LiteralPath $executable)) {
        throw "Missing runtime: $executable"
    }
}
$previousEnvironment = @{}
foreach ($variable in @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')) {
    $previousEnvironment[$variable] = [Environment]::GetEnvironmentVariable($variable, 'Process')
}
try {
    $env:APPDATA = Join-Path $profile 'AppData/Roaming'
    $env:LOCALAPPDATA = Join-Path $profile 'AppData/Local'
    $env:TEMP = Join-Path $profile 'temp'
    $env:TMP = $env:TEMP
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
    if (-not $SkipBlender) {
        & $blender --background --factory-startup --python-exit-code 1 --python (Join-Path $PSScriptRoot 'blender_pipeline_smoke.py')
        if ($LASTEXITCODE -ne 0) { throw "Blender probe failed: $LASTEXITCODE" }
    }
    & $godot --headless --audio-driver Dummy --path $testProject --editor --import
    if ($LASTEXITCODE -ne 0) { throw "Godot asset import failed: $LASTEXITCODE" }
    & $godot --headless --audio-driver Dummy --path $testProject --script res://validate.gd
    if ($LASTEXITCODE -ne 0) { throw "Godot rig/animation validation failed: $LASTEXITCODE" }
}
finally {
    foreach ($variable in $previousEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($variable, $previousEnvironment[$variable], 'Process')
    }
}
