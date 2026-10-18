# Build degli esempi FluentValidator con il compilatore a riga di comando.
# Stesso approccio di Tests\build.ps1 e Packages\build.ps1: dcc diretto,
# niente msbuild, nessuna dipendenza dalla IDE.
#
#   .\build.ps1                          # tutti gli esempi, Win32
#   .\build.ps1 -Only Example2           # solo quello indicato
#   .\build.ps1 -Platform Win64          # tutti gli esempi, Win64
#
# Linux64 compila ma il link richiede l'SDK Linux deployato dalla IDE.
param(
  [string[]]$Only,
  [ValidateSet('Win32', 'Win64', 'Linux64')][string]$Platform = 'Win32'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$BDS = "C:\Program Files (x86)\Embarcadero\Studio\37.0"

# Compilatore, cartella lib e namespace di default dipendono dalla piattaforma.
$compiler   = @{ Win32 = 'dcc32.exe'; Win64 = 'dcc64.exe'; Linux64 = 'dcclinux64.exe' }[$Platform]
$libDir     = @{ Win32 = 'win32';     Win64 = 'win64';     Linux64 = 'linux64'        }[$Platform]
$namespaces = if ($Platform -eq 'Linux64') { 'System;Posix;Data' }
              else { 'System;System.Win;Winapi;Vcl;Data' }

$DCC = "$BDS\bin\$compiler"
$BRCC = "$BDS\bin\brcc32.exe"
$LIB = "$BDS\lib\$libDir\release"
$OUT = ".\$Platform\Debug"

$examples = @('Example1', 'Example2', 'Example3_VerificaModifiche')
if ($Only) { $examples = $examples | Where-Object { $Only -contains $_ } }

New-Item -ItemType Directory -Force "$OUT\dcu" | Out-Null

foreach ($e in $examples) {
  Write-Host "--- $e ($Platform) ---"
  # Il .res non e' sotto controllo di versione: si rigenera dal .rc.
  if (-not (Test-Path ".\$e.res")) {
    & $BRCC ".\$e.rc" -fo".\$e.res"
  }
  & $DCC "$e.dpr" -B --no-config `
    "-NS$namespaces" `
    "-U$LIB;..\src;..\src\Validators" `
    "-I$LIB" "-R$LIB" "-O$LIB" `
    "-E$OUT" "-NU$OUT\dcu" `
    -DDEBUG -w-
  if ($LASTEXITCODE -ne 0) { throw "Build di $e per $Platform fallita (exit $LASTEXITCODE)" }
}
