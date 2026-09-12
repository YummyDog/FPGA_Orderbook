<#
    market_data_sim.ps1

    Runner for the full-chain testbench: parser and engine together, driven
    by real ASX frames.

        s_axis_* -> fullparser -> book_input_stage
                 -> order_fifo -> order_book -> price_storage
                                      |              |
                                  ram_array     level_array

    Sources come from two folders. market_data_top.vhd sits beside this
    script; everything else is in Parser\ or Engine\.


    MEMORIES ARE NOT CLEARED BETWEEN TESTS

    One analyse, one elaborate, one run - all selected tests share a single
    simulation. Neither ram_sdp nor level_array resets its array (real block
    RAM has no reset on its contents), so elaboration is the only thing that
    clears them, and there is one of those.

    That means test 2 starts on top of test 1's resting orders, and so on.
    The intended end states in README_tests.md are written for a test running
    on empty memories, so to compare against them run ONE test at a time:

        .\market_data_sim.ps1 -Test test_price_ladder *> ladder.log

    Running everything in one go is still useful as a smoke test - it proves
    nothing crashes - but with 12 tests adding orders into a 64-slot table
    the later ones will be working against a table that is well past a
    sensible load factor, and cuckoo inserts may fail for that reason alone.


    THE LOG IS THE DELIVERABLE

    test_market_data.py asserts nothing. It prints both memories after every
    step, so a run is thousands of lines. Redirect it:

        powershell -ExecutionPolicy Bypass -File .\market_data_sim.ps1 *> run.log

    A green result means the run reached the end without the simulator
    falling over. It says nothing about whether the design is correct - that
    comes from comparing the dumps against README_tests.md.

    Usage:
        .\market_data_sim.ps1
        .\market_data_sim.ps1 -Test test_filtering
        .\market_data_sim.ps1 -Waves
        .\market_data_sim.ps1 -Clean
#>

param(
    [switch] $Waves,
    [switch] $Clean,
    [string] $Test = ""
)

$ErrorActionPreference = "Stop"

$Module   = "test_market_data"
$Toplevel = "market_data_top"

# ---------------------------------------------------------------------------
# 1. Layout
# ---------------------------------------------------------------------------
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

$ParserDir = Join-Path $Root "Parser"
$EngineDir = Join-Path $Root "Engine"

foreach ($d in @($ParserDir, $EngineDir)) {
    if (-not (Test-Path $d)) { throw "Missing source folder: $d" }
}

# Compile order matters: package before the entity that uses it.
#
# Parser first, then the engine, then the toplevel. itch_parser_pkg MUST come
# before the engine - book_input_stage takes msg_fields directly, so
# order_book_engine_top depends on C_MSG_FIELDS_W.
#
# level_pkg.vhd holds THREE packages in one file - level_cfg_pkg, then
# level_band_pkg, then level_pkg - because a package cannot call its own
# body's function to build its own header constants. Compiling the file once
# gets all three, in order.
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
) | ForEach-Object { Join-Path $ParserDir $_ }

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
) | ForEach-Object { Join-Path $EngineDir $_ }

$Sources = $ParserSources + $EngineSources + @(Join-Path $Root "$Toplevel.vhd")

foreach ($s in $Sources) {
    if (-not (Test-Path $s)) { throw "Missing VHDL source: $s" }
}

foreach ($p in @("$Module.py", "md_harness.py", "asx_packets.py",
                 "book_model.py")) {
    if (-not (Test-Path (Join-Path $Root $p))) {
        throw "Missing Python module: $(Join-Path $Root $p)"
    }
}

# Separate build dir and results file, so this cannot collide with any other
# per-module run in the same folder.
$BuildDir = Join-Path $Root "sim_build_market_data"
$Results  = Join-Path $Root "results_market_data.xml"

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
Write-Host "toplevel : $Toplevel"
if ($Test) {
    Write-Host "filter   : $Test  (memories clear - single test, single elaboration)"
} else {
    Write-Host "filter   : none - ALL tests share one elaboration, so memories" -ForegroundColor Yellow
    Write-Host "           carry over between them and the end states in" -ForegroundColor Yellow
    Write-Host "           README_tests.md will not match. Use -Test to compare." -ForegroundColor Yellow
}
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
#
# level_array prints its geometry as an elaboration-time assertion note, so
# the first useful line arrives before any cocotb test starts. If the depth
# or address width there disagrees with the constants at the top of
# md_harness.py, the harness and the design are addressing different things
# and the level dumps will not make sense.
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
#
# cocotb writes a <testcase> for EVERY test in the module, marking the ones a
# filter excluded as <skipped>. Those are not passes.
#
# test_market_data.py asserts NOTHING. It is a dump, not a check.
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
