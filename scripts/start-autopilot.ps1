[CmdletBinding()]
param(
    [switch]$Doctor,
    [switch]$Audit,
    [switch]$Capture,
    [switch]$Test,
    [string]$Task = ''
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$python = Join-Path $repositoryRoot '.venv\Scripts\python.exe'
$pythonWindowless = Join-Path $repositoryRoot '.venv\Scripts\pythonw.exe'
$entrypoint = Join-Path $repositoryRoot 'tools\echoes_autopilot_desktop\autopilot.py'
if (-not (Test-Path -LiteralPath $python)) {
    throw 'Brak .venv\Scripts\python.exe. Narzędzie wymaga Python 3.12 z Tkinter.'
}
if ($Doctor -or $Audit -or $Capture -or $Test -or $Task) {
    $arguments = @($entrypoint)
    if ($Doctor) { $arguments += '--doctor' }
    elseif ($Audit) { $arguments += '--audit' }
    elseif ($Capture) { $arguments += '--capture' }
    elseif ($Test) { $arguments += '--test' }
    if ($Task) { $arguments += $Task }
    & $python @arguments
    exit $LASTEXITCODE
}
if (-not (Test-Path -LiteralPath $pythonWindowless)) { $pythonWindowless = $python }
# Start-Process receives a quoted script path; no task text is interpolated into a shell.
$argumentLine = '"' + $entrypoint + '" --gui'
$logDirectory = Join-Path $repositoryRoot 'output\ai-team'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
Start-Process -FilePath $pythonWindowless -ArgumentList $argumentLine `
    -WorkingDirectory $repositoryRoot -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logDirectory 'panel.stdout.log') `
    -RedirectStandardError (Join-Path $logDirectory 'panel.stderr.log') | Out-Null
