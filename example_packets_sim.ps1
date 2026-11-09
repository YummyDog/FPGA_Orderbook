<#
    example_packets_sim.ps1

    Runner for example_packets_sim.py: the packets from the live hardware
    test (order_book_test_packets.txt), replayed through the full chain.

        XGMII -> input_top -> fullparser -> book_input_stage
              -> order_fifo -> order_book -> price_storage
                                   |              |
                               ram_array     level_array

    Put this file and example_packets_sim.py beside market_data_sim.ps1.
    It uses the same sources, the same harness (md_harness.py, xgmii.py,
    asx_packets.py, book_model.py) and the same NVC / cocotb setup.


    ONE TEST

        test_live_gapped   the four packets one at a time, with idle
                           between them, checked after each packet

    It runs in its own elaboration, so it starts on an empty book - the
    memories have no reset and elaboration is the only thing that clears
    them. Its expected end state is therefore absolute.


    THIS TEST CHECKS

    example_packets_sim.py compares every step against a Python model of the
    book and fails if anything differs, so PASS / FAIL below means something.
    The full dumps are still printed - redirect them:

        powershell -ExecutionPolicy Bypass -File .\example_packets_sim.ps1 *> example_packets.log

    Usage:
        .\example_packets_sim.ps1
        .\example_packets_sim.ps1 -Waves     # writes example_packets.fst
        .\example_packets_sim.ps1 -Clean
#>

param(
    [switch] $Waves,
    [switch] $Clean
)

$ErrorActionPreference = "Stop"

$Module   = "example_packets_sim"
$Toplevel = "market_data_top"
$TestName = "test_live_gapped"

# ---------------------------------------------------------------------------
# 1. Layout - identical to market_data_sim.ps1
# ---------------------------------------------------------------------------
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

$ParserDir    = Join-Path $Root "Parser"
$EngineDir    = Join-Path $Root "Engine"
$InputDir     = Join-Path $Root "Input"
$TimestampDir = Join-Path $Root "Timestamping"
$OutputDir    = Join-Path $Root "Output"

foreach ($d in @($ParserDir, $EngineDir, $TimestampDir, $OutputDir)) {
    if (-not (Test-Path $d)) { throw "Missing source folder: $d" }
}

$SearchDirs = @($InputDir, $OutputDir, $TimestampDir, $EngineDir, $ParserDir, $Root) |
              Where-Object { Test-Path $_ }

function Find-Source {
    param([string] $Name)
    foreach ($d in $SearchDirs) {
        $p = Join-Path $d $Name
        if (Test-Path $p) { return $p }
    }
    throw ("Missing VHDL source: $Name`n" +
           "  looked in: " + ($SearchDirs -join ", "))
}

# Compile order as in market_data_sim.ps1: front end, parser, timestamping,
# engine, transmit side, toplevel.
$InputSources = @(
    "xgmii64_to_axis.vhd",
    "xgmii_crc32_rx64.vhd",
    "fcs_msg_extend_sync.vhd",
    "input_top.vhd"
) | ForEach-Object { Find-Source $_ }

$ParserSources = @(
    "eth_parser_pkg.vhd",
    "eth_parser.vhd",
    "ipv4_parser_pkg.vhd",
    "ipv4_parser.vhd",
    "udp_parser_pkg.vhd",
    "udp_parser.vhd",
    "mold_parser_pkg.vhd",
    "mold_parser.vhd",
    "itch_parser_pkg.vhd",
    "itch_parser.vhd",
    "fullparser.vhd"
) | ForEach-Object { Find-Source $_ }

$TimestampSources = @(
    "time_counter.vhd",
    "time_event_fifo.vhd"
) | ForEach-Object { Find-Source $_ }

$EngineSources = @(
    "ram_pkg.vhd",
    "ram_sdp.vhd",
    "ram_array.vhd",
    "hash65_pkg.vhd",
    "order_book_pkg.vhd",
    "order_book.vhd",
    "level_pkg.vhd",
    "level_array.vhd",
    "price_storage.vhd",
    "order_fifo.vhd",
    "book_input_stage.vhd",
    "order_book_engine_top.vhd"
) | ForEach-Object { Find-Source $_ }

$OutputSources = @(
    "order_tx_pkg.vhd",
    "order_tx_xgmii.vhd",
    "tx_top.vhd"
) | ForEach-Object { Find-Source $_ }

$Sources = $InputSources + $ParserSources + $TimestampSources +
           $EngineSources + $OutputSources + @(Find-Source "$Toplevel.vhd")

foreach ($p in @("$Module.py", "md_harness.py", "xgmii.py", "asx_packets.py",
                 "book_model.py")) {
    if (-not (Test-Path (Join-Path $Root $p))) {
        throw "Missing Python module: $(Join-Path $Root $p)"
    }
}

# Own build dir and results files, so nothing collides with market_data_sim.
$BuildDir = Join-Path $Root "sim_build_example_packets"
$Results  = Join-Path $Root "results_example_packets.xml"
$WaveFile = Join-Path $Root "example_packets.fst"

# ---------------------------------------------------------------------------
# 2. Tools - identical to market_data_sim.ps1
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
Write-Host "module   : $Module"
Write-Host "toplevel : $Toplevel  (XGMII in)"
Write-Host "test     : $TestName  (own elaboration - starts on empty memories)"
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Clean
# ---------------------------------------------------------------------------
if ($Clean) {
    foreach ($p in @($BuildDir, (Join-Path $Root "__pycache__"))) {
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    if (Test-Path $WaveFile) { Remove-Item $WaveFile -Force }
    Write-Host "cleaned`n"
}

if (Test-Path $Results) { Remove-Item $Results -Force }

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# ---------------------------------------------------------------------------
# 4. cocotb environment
# ---------------------------------------------------------------------------
$env:COCOTB_TEST_MODULES = $Module
$env:COCOTB_TOPLEVEL     = $Toplevel
$env:TOPLEVEL_LANG       = "vhdl"
$env:PYTHONPATH          = $Root
$env:LIBPYTHON_LOC       = $LibPython
$env:PYGPI_PYTHON_BIN    = $PyBin
$env:COCOTB_RESULTS_FILE = $Results
# Anchored at the end: cocotb matches against example_packets_sim.<test>.
$env:COCOTB_TEST_FILTER  = "$TestName`$"
Remove-Item Env:\COCOTB_TESTCASE -ErrorAction SilentlyContinue

if ($env:PATH -notlike "*$LibPythonDir*") {
    $env:PATH = "$LibPythonDir;$env:PATH"
}

$Global = @("--std=2008", "--work=work:$BuildDir\work", "-L", $BuildDir)

# ---------------------------------------------------------------------------
# 5. Analyse once
# ---------------------------------------------------------------------------
Write-Host "--- analyse ---"
& $Nvc @Global -a --preserve-case @Sources
if ($LASTEXITCODE -ne 0) { throw "Analysis failed." }

# ---------------------------------------------------------------------------
# 6. Elaborate + run
# ---------------------------------------------------------------------------
Write-Host "`n--- simulate: $TestName ---"
$RunArgs = @("-e", $Toplevel, "--no-save", "-r", "--load", $VhpiLib)
if ($Waves) { $RunArgs += @("--wave=$WaveFile", "--dump-arrays") }

& $Nvc @Global @RunArgs
$SimExit = $LASTEXITCODE

# ---------------------------------------------------------------------------
# 7. Verdict - from the results file, since NVC exits 0 on a cocotb failure
# ---------------------------------------------------------------------------
Write-Host "`n--- results ---"

$Failed = 0
$Total  = 0
if (Test-Path $Results) {
    [xml]$Xml = Get-Content $Results
    foreach ($c in $Xml.SelectNodes("//testcase")) {
        if ($c.SelectSingleNode("skipped")) { continue }
        $Total++
        if ($c.failure -or $c.error) {
            $Failed++
            Write-Host ("  FAIL  " + $c.name) -ForegroundColor Red
        } else {
            Write-Host ("  pass  " + $c.name) -ForegroundColor Green
        }
    }
    Write-Host "  $Total test(s) ran, $Failed failed"
    if ($Failed -gt 0) {
        Write-Host "  every mismatch is listed under VERDICT at the end of the log"
    }
} else {
    Write-Host "  results.xml not produced" -ForegroundColor Yellow
    $Failed = 1
}

if ($Waves -and (Test-Path $WaveFile)) {
    Write-Host "  waveform: $WaveFile"
}

Write-Host ""
if ($Failed -gt 0 -or $SimExit -ne 0) {
    Write-Host "FAIL" -ForegroundColor Red
    exit 1
}
Write-Host "PASS" -ForegroundColor Green
exit 0