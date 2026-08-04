<#
    udp_sim.ps1

    Self-contained runner for the UDP parser testbench. Does not depend on
    any other script and does not touch existing files.

    Compiles only what udp_parser needs:
        eth_parser_pkg.vhd    (package only - eth_parser is NOT instantiated)
        ipv4_parser_pkg.vhd   (package only - ipv4_parser is NOT instantiated)
        udp_parser_pkg.vhd
        udp_parser.vhd

    Usage:
        powershell -ExecutionPolicy Bypass -File .\udp_sim.ps1
        powershell -ExecutionPolicy Bypass -File .\udp_sim.ps1 -Waves
        powershell -ExecutionPolicy Bypass -File .\udp_sim.ps1 -Clean
#>

param(
    [switch] $Waves,
    [switch] $Clean,
    [string] $Test = ""
)

$ErrorActionPreference = "Stop"

$Module   = "test_udp_parser"
$Toplevel = "udp_parser"

# ---------------------------------------------------------------------------
# 1. Layout
# ---------------------------------------------------------------------------
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

$RtlDir = if (Test-Path (Join-Path $Root "rtl")) { Join-Path $Root "rtl" } else { $Root }

# Compile order matters: packages before the entity that uses them.
$Sources = @(
    "eth_parser_pkg.vhd",
    "ipv4_parser_pkg.vhd",
    "udp_parser_pkg.vhd",
    "udp_parser.vhd"
) | ForEach-Object { Join-Path $RtlDir $_ }

foreach ($s in $Sources) {
    if (-not (Test-Path $s)) { throw "Missing VHDL source: $s" }
}
if (-not (Test-Path (Join-Path $Root "$Module.py"))) {
    throw "Missing test module: $(Join-Path $Root "$Module.py")"
}

# Separate build dir and results file, so this cannot collide with the other
# per-module runs in the same folder.
$BuildDir = Join-Path $Root "sim_build_udp"
$Results  = Join-Path $Root "results_udp.xml"

# ---------------------------------------------------------------------------
# 2. Tools
# ---------------------------------------------------------------------------
$Nvc = (Get-Command nvc -ErrorAction SilentlyContinue).Source
if (-not $Nvc) { $Nvc = "C:\Program Files\NVC\bin\nvc.exe" }
if (-not (Test-Path $Nvc)) { throw "nvc not found. Add it to PATH or install to C:\Program Files\NVC." }

$Python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $Python) { throw "python not found on PATH." }

$VhpiLib = (& $Python -m cocotb_tools.config --lib-name-path vhpi nvc 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $VhpiLib) {
    throw "Could not locate cocotb's NVC VHPI library. Is cocotb installed for $Python ?"
}
$VhpiLib = $VhpiLib.Trim()

# Auto-detection fails when python.exe is the WindowsApps alias stub, giving
# errors like "Unable to open lib hon313.dll". Resolve explicitly.
$LibPython = (& $Python -m cocotb_tools.config --libpython 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $LibPython) {
    throw "Could not locate libpython. Try: pip install find_libpython"
}
$LibPython = $LibPython.Trim()
if (-not (Test-Path $LibPython)) {
    throw "libpython resolved to a path that does not exist: $LibPython"
}
$LibPythonDir = Split-Path $LibPython -Parent

$PyBin = (& $Python -m cocotb_tools.config --python-bin 2>$null)
if ($PyBin) { $PyBin = $PyBin.Trim() }
$RealPy = Join-Path $LibPythonDir "python.exe"
if ((-not $PyBin) -or (-not (Test-Path $PyBin)) -or ($PyBin -like "*WindowsApps*")) {
    if (Test-Path $RealPy) { $PyBin = $RealPy } else { $PyBin = $Python }
}
if (-not (Test-Path $PyBin)) { throw "Could not resolve a usable python.exe (tried '$PyBin')." }

Write-Host "nvc      : $Nvc"
Write-Host "python   : $Python"
Write-Host "pygpi bin: $PyBin"
Write-Host "libpython: $LibPython"
Write-Host "vhpi     : $VhpiLib"
Write-Host "toplevel : $Toplevel  (standalone, s_fields driven by the testbench)"
if ($Test) { Write-Host "filter   : $Test" }
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Clean
# ---------------------------------------------------------------------------
if ($Clean) {
    foreach ($p in @($BuildDir, (Join-Path $Root "__pycache__"))) {
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    if (Test-Path (Join-Path $Root "$Toplevel.fst")) {
        Remove-Item (Join-Path $Root "$Toplevel.fst") -Force
    }
    Write-Host "cleaned`n"
}

# Always drop previous results, otherwise a filtered run leaves stale entries
# and the summary reports "pass" for tests that never executed.
if (Test-Path $Results) { Remove-Item $Results -Force }

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# ---------------------------------------------------------------------------
# 4. cocotb environment
# ---------------------------------------------------------------------------
$env:COCOTB_TEST_MODULES = $Module
$env:COCOTB_TOPLEVEL     = $Toplevel
$env:TOPLEVEL_LANG       = "vhdl"
$env:COCOTB_RESULTS_FILE = $Results
$env:PYTHONPATH          = $Root
$env:LIBPYTHON_LOC       = $LibPython
$env:PYGPI_PYTHON_BIN    = $PyBin

Remove-Item Env:\COCOTB_TESTCASE -ErrorAction SilentlyContinue
if ($Test) {
    $env:COCOTB_TEST_FILTER = $Test
} else {
    Remove-Item Env:\COCOTB_TEST_FILTER -ErrorAction SilentlyContinue
}

if ($env:PATH -notlike "*$LibPythonDir*") {
    $env:PATH = "$LibPythonDir;$env:PATH"
}

# NVC global options must come BEFORE the sub-command (-a / -e / -r)
$Global = @("--std=2008", "--work=work:$BuildDir\work", "-L", $BuildDir)

# ---------------------------------------------------------------------------
# 5. Analyse
# ---------------------------------------------------------------------------
Write-Host "--- analyse ---"
& $Nvc @Global -a --preserve-case @Sources
if ($LASTEXITCODE -ne 0) { throw "Analysis failed." }

# ---------------------------------------------------------------------------
# 6. Elaborate + run
#
# One invocation. --no-save keeps the elaborated design in memory only, so a
# separate '-r' call would fail with "WORK.<TOPLEVEL> not elaborated".
# ---------------------------------------------------------------------------
Write-Host "`n--- simulate ---"
$RunArgs = @("-e", $Toplevel, "--no-save", "-r", "--load", $VhpiLib)
if ($Waves) { $RunArgs += @("--wave=$Toplevel.fst", "--dump-arrays") }

& $Nvc @Global @RunArgs
$SimExit = $LASTEXITCODE

# ---------------------------------------------------------------------------
# 7. Verdict
#
# NVC exits 0 even when a cocotb assertion fires, so parse results.xml.
# ---------------------------------------------------------------------------
Write-Host "`n--- results ---"

$Failed = 0
$Total  = 0

if (Test-Path $Results) {
    [xml]$Xml = Get-Content $Results
    $Cases = @($Xml.SelectNodes("//testcase"))
    $Total = $Cases.Count
    foreach ($c in $Cases) {
        if ($c.failure -or $c.error) {
            $Failed++
            Write-Host ("  FAIL  " + $c.name) -ForegroundColor Red
        } else {
            Write-Host ("  pass  " + $c.name) -ForegroundColor Green
        }
    }
    Write-Host "  $Total test(s), $Failed failed"
} else {
    Write-Host "  results.xml not produced" -ForegroundColor Yellow
    $Failed = 1
}

if ($Waves -and (Test-Path (Join-Path $Root "$Toplevel.fst"))) {
    Write-Host "  waveform: $(Join-Path $Root "$Toplevel.fst")"
}

Write-Host ""
if ($Failed -gt 0 -or $SimExit -ne 0) {
    Write-Host "FAIL" -ForegroundColor Red
    exit 1
}
Write-Host "PASS" -ForegroundColor Green
exit 0
