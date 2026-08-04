<#
    run_sim.ps1

    Launches the cocotb / NVC simulation for the market-data header parser.

    Usage:
        powershell -ExecutionPolicy Bypass -File .\run_sim.ps1
        powershell -ExecutionPolicy Bypass -File .\run_sim.ps1 -Waves
        powershell -ExecutionPolicy Bypass -File .\run_sim.ps1 -Clean
        powershell -ExecutionPolicy Bypass -File .\run_sim.ps1 -Test test_vlan_tagged
#>

param(
    [switch] $Waves,                        # dump <toplevel>.fst
    [switch] $Clean,                        # wipe build dir first
    [string] $Test     = "",                # run only tests matching this regex
    [string] $Module   = "test_eth_parser", # python test module (no .py)
    [string] $Toplevel = "eth_parser"       # VHDL entity
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 1. Where are we
# ---------------------------------------------------------------------------
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

# VHDL sources, in compile order: package before entity.
# Looks in .\rtl first, then falls back to the script directory.
$RtlDir = if (Test-Path (Join-Path $Root "rtl")) { Join-Path $Root "rtl" } else { $Root }

$Sources = @(
    "eth_parser_pkg.vhd",
    "eth_parser.vhd"
) | ForEach-Object { Join-Path $RtlDir $_ }

foreach ($s in $Sources) {
    if (-not (Test-Path $s)) { throw "Missing VHDL source: $s" }
}

if (-not (Test-Path (Join-Path $Root "$Module.py"))) {
    throw "Missing test module: $(Join-Path $Root "$Module.py")"
}

$BuildDir = Join-Path $Root "sim_build"
$Results  = Join-Path $Root "results.xml"

# ---------------------------------------------------------------------------
# 2. Tools
# ---------------------------------------------------------------------------
$Nvc = (Get-Command nvc -ErrorAction SilentlyContinue).Source
if (-not $Nvc) { $Nvc = "C:\Program Files\NVC\bin\nvc.exe" }
if (-not (Test-Path $Nvc)) { throw "nvc not found. Add it to PATH or install to C:\Program Files\NVC." }

$Python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $Python) { throw "python not found on PATH." }

# cocotb ships a prebuilt VHPI plugin for NVC; ask it where.
$VhpiLib = (& $Python -m cocotb_tools.config --lib-name-path vhpi nvc 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $VhpiLib) {
    throw "Could not locate cocotb's NVC VHPI library. Is cocotb installed for $Python ?"
}
$VhpiLib = $VhpiLib.Trim()

# cocotb's VHPI plugin dynamically loads the Python runtime DLL. Auto-detection
# fails when python.exe is the WindowsApps alias stub, producing errors like
# "Unable to open lib hon313.dll". Resolve it explicitly instead.
$LibPython = (& $Python -m cocotb_tools.config --libpython 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $LibPython) {
    throw "Could not locate libpython. Try: pip install find_libpython"
}
$LibPython = $LibPython.Trim()
if (-not (Test-Path $LibPython)) {
    throw "libpython resolved to a path that does not exist: $LibPython"
}
$LibPythonDir = Split-Path $LibPython -Parent

# cocotb's GPI layer initialises the interpreter and needs the path to the
# actual python.exe. The WindowsApps alias stub does not work here, so prefer
# the real executable that sits next to the runtime DLL.
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
if ($Test) { Write-Host "filter   : $Test" }
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Clean
# ---------------------------------------------------------------------------
if ($Clean) {
    foreach ($p in @($BuildDir, (Join-Path $Root "__pycache__"))) {
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    Get-ChildItem $Root -Filter *.fst -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "cleaned`n"
}

# ALWAYS delete the previous results, clean build or not. Otherwise a filtered
# run leaves stale entries behind and the summary reports "pass" for tests that
# never executed.
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

# Absolute path to the Python runtime DLL, for the VHPI plugin's dynamic load.
$env:LIBPYTHON_LOC = $LibPython

# The embedded interpreter needs to know which python.exe it belongs to.
$env:PYGPI_PYTHON_BIN = $PyBin

# Test selection. COCOTB_TESTCASE is deprecated in cocotb 2.x; clear it so a
# leftover value in the shell cannot silently override the filter.
Remove-Item Env:\COCOTB_TESTCASE -ErrorAction SilentlyContinue
if ($Test) {
    $env:COCOTB_TEST_FILTER = $Test
} else {
    Remove-Item Env:\COCOTB_TEST_FILTER -ErrorAction SilentlyContinue
}

# Its directory must also be searchable so dependent DLLs resolve.
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
# NVC exits 0 even when a cocotb assertion fires, so the exit code alone is
# not trustworthy. Parse results.xml.
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
