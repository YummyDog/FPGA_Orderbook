<#
    book_PLS_sim.ps1

    Self-contained runner for the price level storage testbench.

    order_book_sim.ps1 stops at the engine. This one carries on into the
    aggregation stage:

        s_*  ->  order_book  ->  m_*  ->  price_storage  ->  tob_*
                     |                         |
                 ram_array              lvl_* to Python

    Compiles:
        ram_pkg.vhd         geometry, slot layout, accessors, t_book_op
        ram_sdp.vhd         one table
        ram_array.vhd       the four order tables
        hash65_pkg.vhd      XOR-tree hashes, 65-bit key (depends on ram_pkg)
        order_book_pkg.vhd  the command bus types
        order_book.vhd
        level_pkg.vhd       level_cfg_pkg + level_band_pkg + level_pkg
        price_storage.vhd
        book_PLS_top.vhd    wires them together

    level_array.vhd IS NOT COMPILED. The level memory is a Python model -
    level_ram_model.py - sitting on price_storage's level bus, which
    book_PLS_top brings out to its pins. level_pkg.vhd is still needed:
    price_storage takes t_level and t_level_set from it and calls px_index.

    level_pkg.vhd holds THREE packages in one file - level_cfg_pkg, then
    level_band_pkg, then level_pkg. That split exists because a package cannot
    call its own body's function to build its own header constants, so the
    derived band map has to live one package downstream of the function that
    builds it. Compiling the file once gets all three, in order.

    Toplevel is book_PLS_top. Neither order_book nor price_storage owns its
    memory. The toplevel supplies a real ram_array for the order table, which
    the testbench reads through the hierarchy; the level table is modelled in
    Python instead.

    Runs alongside order_book_sim.ps1 rather than replacing it - separate
    build directory, separate results file, nothing shared. Neither script
    touches the other's outputs.


    EXPECT NO LEVEL WRITES

    price_storage gates its input capture on its own m_tvalid, which nothing
    in that architecture assigns, so it holds '0' and lvl_we never rises. A
    clean run with zero level writes is the current correct result. What the
    testbench can check today is the concurrent path - the price-to-index map
    on lvl_raddr and the side select on lvl_wsel - which is live.

    Undriven outputs of price_storage show as 'U': s_tready, busy, oor,
    m_tvalid, and the four top-of-book data buses.


    ONE THING THAT WILL BITE

    price_storage.vhd line 113:

        index <= px_index(s_price);

    index is 32 bits wide, px_index returns C_LVL_ADDR_W = 14. The statement
    sits inside the m_tvalid branch, so it never executes and the simulation
    runs clean. The first time m_tvalid is driven high, the run will stop with
    a bound check failure on that line. Not fixed here - this script does not
    modify any existing source.


    ELABORATION IS BACK TO order_book_sim SPEED

    The 2 x 16384 x 65 bits of level RAM used to be elaborated element by
    element by ram_sdp's simulation initialiser, and it dominated startup.
    With level_array gone that cost has gone with it - the model allocates
    nothing until something is written to it.

    The same applies to -Waves: --dump-arrays no longer has the level tables
    to dump, only the order tables' 4 x 16 x 132 bits.

    THE LOG IS THE DELIVERABLE

    test_book_PLS.py prints both memories after every one of its 42 messages,
    so a full run is several thousand lines. Redirect it:

        powershell -ExecutionPolicy Bypass -File .\book_PLS_sim.ps1 *> run.log

    There is one test in that file, test_single_level_traffic, so -Test has
    nothing to select between and is left in only for consistency with
    order_book_sim.ps1.

    Usage:
        powershell -ExecutionPolicy Bypass -File .\book_PLS_sim.ps1
        powershell -ExecutionPolicy Bypass -File .\book_PLS_sim.ps1 -Waves
        powershell -ExecutionPolicy Bypass -File .\book_PLS_sim.ps1 -Clean
#>

param(
    [switch] $Waves,
    [switch] $Clean,
    [string] $Test = ""
)

$ErrorActionPreference = "Stop"

$Module   = "test_book_PLS"
$Toplevel = "book_PLS_top"

# ---------------------------------------------------------------------------
# 1. Layout
# ---------------------------------------------------------------------------
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

$RtlDir = if (Test-Path (Join-Path $Root "rtl")) { Join-Path $Root "rtl" } else { $Root }

# Compile order matters: package before the entity that uses it.
#
# level_pkg.vhd must precede price_storage.vhd, and book_PLS_top.vhd comes
# last because it instantiates the other entities and reads constants out of
# the level packages. level_array.vhd is deliberately absent - see the header.
$Sources = @(
    "ram_pkg.vhd",
    "ram_sdp.vhd",
    "ram_array.vhd",
    "hash65_pkg.vhd",
    "order_book_pkg.vhd",
    "order_book.vhd",
    "level_pkg.vhd",
    "price_storage.vhd",
    "book_PLS_top.vhd"
) | ForEach-Object { Join-Path $RtlDir $_ }

foreach ($s in $Sources) {
    if (-not (Test-Path $s)) { throw "Missing VHDL source: $s" }
}
if (-not (Test-Path (Join-Path $Root "$Module.py"))) {
    throw "Missing test module: $(Join-Path $Root "$Module.py")"
}

# Separate build dir and results file, so this cannot collide with
# order_book_sim.ps1 or any other per-module run in the same folder.
$BuildDir = Join-Path $Root "sim_build_book_PLS"
$Results  = Join-Path $Root "results_book_PLS.xml"

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
Write-Host "toplevel : $Toplevel  (order_book + ram_array + price_storage; level RAM modelled in Python)"
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
#
# book_PLS_top prints the level geometry as an elaboration-time assertion
# note, so the first useful line arrives before any cocotb test starts. If the
# depth or address width there disagrees with the constants at the top of
# level_ram_model.py, the model and the design are addressing different things
# and nothing downstream will make sense.
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
# test_book_PLS.py asserts NOTHING. It is a dump, not a check. A green result
# here means the run reached the end without the simulator falling over - it
# says nothing at all about whether the design is correct. That judgement
# comes from reading the tables in the log.
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
