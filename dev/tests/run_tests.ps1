# rune test suite (Windows).
#
# Usage: powershell -ExecutionPolicy Bypass -File run_tests.ps1 [rune-path] [torvc-path]
#   Defaults to `rune` / `torvc` on PATH.
#
# rune ships from its own repository with its own version line, so it is tested here
# rather than inside Torvik's suite - a rune regression should be catchable without
# building the compiler.

param(
    [string]$Rune  = "rune",
    [string]$Torvc = "torvc"
)

$ErrorActionPreference = "Continue"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Work = Join-Path $Here "rune-test-work"
$Log  = Join-Path $Work "results.log"

if (Test-Path $Work) { Remove-Item -Recurse -Force $Work }
New-Item -ItemType Directory -Force -Path $Work | Out-Null
New-Item -ItemType File -Force -Path $Log | Out-Null

$script:Pass = 0
$script:Fail = 0
$script:Failed = @()

function Note([string]$m) { Write-Host $m; Add-Content $Log $m }

function Get-Cmd([string]$n) {
    $c = Get-Command $n -ErrorAction SilentlyContinue
    if (-not $c) { Write-Host "$n not found"; exit 1 }
    return $c.Source
}
$RuneExe  = Get-Cmd $Rune
$TorvcExe = Get-Cmd $Torvc

Note "== rune:  $(& $RuneExe version 2>&1 | Select-Object -First 1) =="
Note "== torvc: $(& $TorvcExe --version 2>&1 | Select-Object -First 1) =="
Note ""
Note "== PROJECT CASES =="

function Case([string]$name, [scriptblock]$body) {
    $d = Join-Path $Work $name
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Push-Location $d
    $ok = $false
    try { $ok = (& $body) } catch { $ok = $false }
    Pop-Location
    if ($ok) { $script:Pass++; Note "ok    rune/$name" }
    else     { $script:Fail++; $script:Failed += "rune/$name"; Note "FAIL  rune/$name" }
}

Case "new_build_run" {
    & $RuneExe new demo *> new.log
    if (-not (Test-Path "demo\torvik.rune")) { return $false }
    Push-Location demo
    & $RuneExe build *> b.log
    $built = (Test-Path "build\demo.exe") -or (Test-Path "build\demo")
    $out = (& $RuneExe run 2>$null | Select-Object -Last 1)
    Pop-Location
    return ($built -and $out -match "Hello")
}

Case "missing_entry" {
    & $RuneExe new noentry *> n.log
    Push-Location noentry
    Remove-Item "src\main.tv" -Force -ErrorAction SilentlyContinue
    & $RuneExe build *> b.log 2>&1
    $code = $LASTEXITCODE
    $txt = Get-Content b.log -Raw -ErrorAction SilentlyContinue
    Pop-Location
    return (($code -ne 0) -and ($txt -notmatch "TVC-"))
}

Case "bad_name" {
    # rune rejects a path separator and an empty name. Spaces are legal, so testing
    # "bad name here" asserted something rune never promised.
    & $RuneExe new "bad/name" *> bn.log 2>&1
    if ($LASTEXITCODE -eq 0) { return $false }
    & $RuneExe new "" *> bn2.log 2>&1
    return ($LASTEXITCODE -ne 0)
}

Case "clean_list_version" {
    & $RuneExe new lv *> n.log
    Push-Location lv
    & $RuneExe build *> b.log
    & $RuneExe clean *> c.log
    $cleaned = -not (Test-Path "build")
    & $RuneExe list *> l.log
    $listed = (Get-Content l.log -Raw) -match "lv"
    Pop-Location
    return ($cleaned -and $listed)
}

Case "incremental" {
    & $RuneExe new capp *> n.log
    Push-Location capp
    & $RuneExe run *> first.log
    & $RuneExe run *> second.log
    $second = Get-Content second.log -Raw
    Pop-Location
    # A second run must either say it reused the build, or not report compiling again.
    return (($second -match "cache|up.to.date|unchanged") -or ($second -notmatch "compil"))
}

Case "exit_propagation" {
    & $RuneExe new eapp *> n.log
    Push-Location eapp
    @'
df main() -> void {
    exit(4);
}
'@ | Set-Content -Encoding ASCII src\main.tv
    & $RuneExe run *> r.log
    $code = $LASTEXITCODE
    Pop-Location
    return ($code -eq 4)
}

Case "min_version_gate" {
    & $RuneExe new vapp *> n.log
    Push-Location vapp
    # Demand an impossibly new toolchain: the build must refuse and say so.
    $m = Get-Content torvik.rune -Raw
    if ($m -match '(?m)^torvik\s*=') { $m = $m -replace '(?m)^torvik\s*=.*', 'torvik = "99.0.0"' }
    else { $m += "`ntorvik = `"99.0.0`"" }
    Set-Content -Path torvik.rune -Value $m -Encoding ASCII
    & $RuneExe build *> b.log 2>&1
    $failed = ($LASTEXITCODE -ne 0)
    $txt = Get-Content b.log -Raw
    Pop-Location
    return ($failed -and ($txt -match "update|version"))
}

Case "final_build" {
    & $RuneExe new fapp *> n.log
    Push-Location fapp
    & $RuneExe build --final *> b.log
    $exe = if (Test-Path "build\fapp.exe") { "build\fapp.exe" } else { "build\fapp" }
    $ok = Test-Path $exe
    $out = if ($ok) { (& ".\$exe" 2>&1 | Out-String) } else { "" }
    Pop-Location
    return ($ok -and ($out -match "Hello"))
}

Case "std_version_gate" {
    & $RuneExe new sapp *> n.log
    Push-Location sapp
    # Demand an impossibly new standard library: the build must refuse and say so.
    Add-Content torvik.rune "`nstd = `"99.0.0`""
    & $RuneExe build *> b.log 2>&1
    $failed = ($LASTEXITCODE -ne 0)
    $txt = Get-Content b.log -Raw
    Pop-Location
    return ($failed -and ($txt -match "standard library"))
}

Note ""
Note "== v1.5.0 CASES =="

Case "run_single_file" {
    @'
df main() -> void {
    fixed n: i64 = args();
    check n >= 2 { echo!(args_get(1)); } fallback { echo!("noargs"); }
}
'@ | Set-Content -Encoding ASCII prog.tv
    $out = (& $RuneExe run prog.tv 2>&1 | Out-String)
    # Keep the output: if this ever fails again, the log says why instead of leaving
    # an empty directory to guess from.
    Set-Content -Path "run.log" -Value $out -Encoding ASCII
    return ($out -match "noargs")
}

Case "run_file_args" {
    @'
df main() -> void {
    fixed n: i64 = args();
    check n >= 2 { echo!(args_get(1)); } fallback { echo!("noargs"); }
}
'@ | Set-Content -Encoding ASCII prog.tv
    $out = (& $RuneExe run prog.tv HELLO 2>&1 | Out-String)
    Set-Content -Path "run.log" -Value $out -Encoding ASCII
    return ($out -match "HELLO")
}

Case "run_file_no_binary" {
    @'
df main() -> void { echo!("x"); }
'@ | Set-Content -Encoding ASCII prog.tv
    & $RuneExe run prog.tv *> r.log
    return (-not ((Test-Path "prog.exe") -or (Test-Path "prog")))
}

Case "run_missing_file" {
    & $RuneExe run nonexistent-file.tv *> m.log 2>&1
    return ((Get-Content m.log -Raw) -match "no such file")
}

Case "build_bare_elf" {
    & $RuneExe new bproj *> n.log
    Push-Location bproj
    Add-Content torvik.rune "`n[build]`ntarget = bare"
    @'
df main() -> void {
    unsafe set v: varda<u16> = from_addr(753664);
    unsafe store_vol(v, 65);
    whilst true { unsafe hlt(); }
}
'@ | Set-Content -Encoding ASCII src\main.tv
    & $RuneExe build *> b.log 2>&1
    $ok = Test-Path "build\bproj.elf"
    Pop-Location
    return $ok
}

Case "bare_run_no_runner" {
    & $RuneExe new bproj2 *> n.log
    Push-Location bproj2
    Add-Content torvik.rune "`n[build]`ntarget = bare"
    @'
df main() -> void {
    unsafe set v: varda<u16> = from_addr(753664);
    unsafe store_vol(v, 65);
    whilst true { unsafe hlt(); }
}
'@ | Set-Content -Encoding ASCII src\main.tv
    & $RuneExe run *> r.log 2>&1
    $txt = Get-Content r.log -Raw
    Pop-Location
    return ($txt -match "nothing on this machine to run it")
}

Case "build_missing_linkscript" {
    & $RuneExe new bproj3 *> n.log
    Push-Location bproj3
    Add-Content torvik.rune "`n[build]`ntarget = bare`nlink-script = nope.ld"
    & $RuneExe build *> b.log 2>&1
    $txt = Get-Content b.log -Raw
    Pop-Location
    return ($txt -match "doesn't exist")
}

Case "silence_major_nothing_to_silence" {
    & $RuneExe update --silence-major *> s.log 2>&1
    $txt = Get-Content s.log -Raw
    return (($txt -match "no new Torvik major to silence") -or ($txt -match "couldn't reach"))
}

Case "silence_std_nothing_to_silence" {
    & $RuneExe update --silence-std-major *> s.log 2>&1
    $txt = Get-Content s.log -Raw
    return (($txt -match "no new standard-library major") -or ($txt -match "couldn't reach"))
}

Case "update_bad_version" {
    & $RuneExe update vABC *> u.log 2>&1
    return ((Get-Content u.log -Raw) -match "not a valid version")
}

Note ""
Note "== SUMMARY: $($script:Pass) passed, $($script:Fail) failed =="
if ($script:Fail -ne 0) {
    Note ("failed: " + ($script:Failed -join " "))
    exit 1
}
exit 0
