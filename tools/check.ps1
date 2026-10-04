param([string]$GodotPath = "godot")
$ErrorActionPreference = "Stop"
$projectPath = Split-Path -Parent $PSScriptRoot
Push-Location $projectPath
try {
    python tools/verify_stages.py --write
    if ($LASTEXITCODE -ne 0) { throw "Stage verifier failed" }
    & $GodotPath --headless --path $projectPath --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw "Godot import failed" }
    & $GodotPath --headless --debug --ignore-error-breaks --path $projectPath --script tests/check_project.gd
    if ($LASTEXITCODE -ne 0) { throw "Project parse/load check failed" }
    & $GodotPath --headless --debug --ignore-error-breaks --path $projectPath --script tests/run_tests.gd
    if ($LASTEXITCODE -ne 0) { throw "Gameplay tests failed" }
} finally { Pop-Location }
