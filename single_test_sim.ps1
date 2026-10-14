<#
    single_test_sim.ps1

    Runner for single_test.py: one hand-written frame through market_data_top.

    A separate simulation from market_data_sim.ps1. Same sources, same folder
    layout, same harness - but its own build folder, results file and
    waveform, so the two can be run one after the other without either
    touching the other's output.

    market_data_top.vhd sits beside this script; everything else is in
    Input\, Parser\, Engine\, Timestamping\ or Output\.

    The transmit side in Output\ is compiled because market_data_top
    instantiates it. The test does not look at it.


    BOOK ID

    The frame's add order carries order book id 0, and book_input_stage drops
    anything that is not G_ORDER_BOOK_ID. So this runner elaborates with
    G_ORDER_BOOK_ID = 0 by default and the add reaches the book. Pass
    -BookId 85603 (the design's default) to watch the filter drop it.


    THE LOG IS THE DELIVERABLE

    single_test.py asserts nothing. It prints the frame's fields, the XGMII
    beats, the per-cycle trace and both memories. Redirect it:

        powershell -ExecutionPolicy Bypass -File .\single_test_sim.ps1 *> single.log

    One test, one elaboration, so both memories start empty.

    Usage:
        .\single_test_sim.ps1
        .\single_test_sim.ps1 -BookId 85603
        .\single_test_sim.ps1 -Waves
        .\single_test_sim.ps1 -Clean
#>

param(
    [switch] $Waves,
    [switch] $Clean,
    [int]    $BookId = 0
)

$ErrorActionPreference = "Stop"

$Module   = "single_test"
$Toplevel = "market_data_top"

# ---------------------------------------------------------------------------
# 1. Layout
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

# Compile order is identical to market_data_sim.ps1: input, parser,
# timestamping, engine, transmit side, then the toplevel. See that script for
# why each group sits where it does.
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

# Own build dir, results file and waveform - nothing shared with
# market_data_sim.ps1's output.
$BuildDir = Join-Path $Root "sim_build_single_test"
$Results  = Join-Path $Root "results_single_test.xml"
$WaveFile = "$Module.fst"

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
Write-Host "parser   : $ParserDir"
Write-Host "engine   : $EngineDir"
Write-Host "input    : $(Split-Path $InputSources[0] -Parent)"
Write-Host "timestamp: $(Split-Path $TimestampSources[0] -Parent)"
Write-Host "output   : $(Split-Path $OutputSources[0] -Parent)  (compiled, not tested)"
Write-Host "toplevel : $Toplevel  (XGMII in)"
Write-Host "test     : $Module  (one frame, empty memories)"
if ($BookId -eq 0) {
    Write-Host "book id  : 0 - matches the frame, so the add reaches the book"
} else {
    Write-Host "book id  : $BookId - the frame carries book 0, so expect the add to be filtered" -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Clean
# ---------------------------------------------------------------------------
if ($Clean) {
    foreach ($p in @($BuildDir, (Join-Path $Root "__pycache__"))) {
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    if (Test-Path (Join-Path $Root $WaveFile)) {
        Remove-Item (Join-Path $Root $WaveFile) -Force
    }
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
$env:COCOTB_RESULTS_FILE = $Results
$env:PYTHONPATH          = $Root
$env:LIBPYTHON_LOC       = $LibPython
$env:PYGPI_PYTHON_BIN    = $PyBin
$env:SINGLE_TEST_BOOK_ID = "$BookId"

Remove-Item Env:\COCOTB_TESTCASE    -ErrorAction SilentlyContinue
Remove-Item Env:\COCOTB_TEST_FILTER -ErrorAction SilentlyContinue

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
# One invocation, as in market_data_sim.ps1. The only difference is the
# generic override, which has to sit ahead of the toplevel name.
# ---------------------------------------------------------------------------
Write-Host "`n--- simulate ---"
$RunArgs = @("-e", "-gG_ORDER_BOOK_ID=$BookId", $Toplevel,
             "--no-save", "-r", "--load", $VhpiLib)
if ($Waves) { $RunArgs += @("--wave=$WaveFile", "--dump-arrays") }

& $Nvc @Global @RunArgs
$SimExit = $LASTEXITCODE

# ---------------------------------------------------------------------------
# 7. Verdict
#
# NVC exits 0 even when a cocotb assertion fires, so parse results.xml.
# single_test.py asserts NOTHING - a pass means the run completed.
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
} else {
    Write-Host "  results.xml not produced" -ForegroundColor Yellow
    $Failed = 1
}

if ($Waves -and (Test-Path (Join-Path $Root $WaveFile))) {
    Write-Host "  waveform: $(Join-Path $Root $WaveFile)"
}

Write-Host ""
if ($Failed -gt 0 -or $SimExit -ne 0) {
    Write-Host "FAIL" -ForegroundColor Red
    exit 1
}
Write-Host "PASS" -ForegroundColor Green
exit 0
