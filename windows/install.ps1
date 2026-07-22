# install.ps1 - rune installer (the Torvik package manager):
#   iwr -useb https://raw.githubusercontent.com/torvik-lang/rune/main/windows/install.ps1 | iex
#
# rune is versioned and released independently from Torvik, from its own repo.
# Installs just rune into %USERPROFILE%\.torvik\bin (the same place Torvik uses),
# alongside an existing torvc.exe. You usually won't run this directly - the
# Torvik installer pulls rune for you. Pin with $env:RUNE_VERSION='v1.4.0'.
$ErrorActionPreference = 'Stop'
$InstallDir = Join-Path $env:USERPROFILE '.torvik'
$BinDir     = Join-Path $InstallDir 'bin'
$Org = 'https://github.com/torvik-lang/rune'
$Raw = 'https://raw.githubusercontent.com/torvik-lang/rune/main'
$OS = 'windows'; $Arch = 'x86_64'
function Download($url, $out) { Invoke-WebRequest -UseBasicParsing $url -OutFile $out }

if ($env:RUNE_VERSION) {
    $V = $env:RUNE_VERSION -replace '^v',''
} else {
    $V = ((Invoke-WebRequest -UseBasicParsing "$Raw/VERSION").Content -split "`n" |
          Where-Object { $_ -match '^\s*rune\s*=\s*(.+?)\s*$' } |
          ForEach-Object { $Matches[1].Trim() } | Select-Object -First 1)
    if (-not $V) { Write-Host 'error: could not determine the latest rune version (network or GitHub error).' -ForegroundColor Red; exit 1 }
}
Write-Host "Installing rune v$V ($OS/$Arch)..."
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

$tmp = Join-Path $BinDir 'rune.exe.new'
try { Download "$Org/releases/download/v$V/rune-$OS-$Arch.exe" $tmp }
catch {
    Write-Host "error: rune v$V has no $OS/$Arch build." -ForegroundColor Red
    Write-Host '  See https://github.com/torvik-lang/rune/releases'
    Remove-Item -Force -ErrorAction SilentlyContinue $tmp; exit 1
}
# rune.exe may be the very process running this (a self-update). Windows won't
# overwrite a running exe but will let you rename it aside; do that if locked.
$final = Join-Path $BinDir 'rune.exe'
if (Test-Path $final) {
    try { Move-Item -Force $tmp $final -ErrorAction Stop }
    catch { Rename-Item -Path $final -NewName 'rune.exe.old' -Force; Move-Item -Force $tmp $final }
} else { Move-Item -Force $tmp $final }
"rune = $V" | Set-Content -Encoding ASCII (Join-Path $InstallDir 'rune.VERSION')

$userPath = [Environment]::GetEnvironmentVariable('Path','User')
if ($userPath -notlike "*$BinDir*") { [Environment]::SetEnvironmentVariable('Path', "$BinDir;$userPath", 'User') }

Write-Host ''
Write-Host "rune v$V installed."
if (-not (Test-Path (Join-Path $BinDir 'torvc.exe'))) {
    Write-Host "note: Torvik (torvc) isn't installed yet. rune manages Torvik but needs it to build projects:" -ForegroundColor Yellow
    Write-Host '  iwr -useb https://raw.githubusercontent.com/torvik-lang/torvik/main/windows/install.ps1 | iex'
}
Write-Host '>>> Open a NEW terminal (so PATH refreshes), then:  rune version'
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BinDir 'rune.exe.old')
