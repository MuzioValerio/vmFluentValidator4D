# Build del package runtime vmFluentValidator con il compilatore a riga di comando.
# Stesso approccio di Tests\build.ps1: dcc diretto, niente msbuild.
#
#   .\build.ps1                    # Win32 (default)
#   .\build.ps1 -Platform Win64
#   .\build.ps1 -Platform Linux64
#
# Win32 e Win64 producono .bpl + .dcp. Linux64 compila tutte le unit ma il link
# della .so richiede l'SDK Linux deployato dalla IDE: non verificato.
param([ValidateSet('Win32', 'Win64', 'Linux64')][string]$Platform = 'Win32')

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
$OUT = ".\$Platform\Release"

New-Item -ItemType Directory -Force "$OUT\dcu" | Out-Null
# Il .res del package non e' sotto controllo di versione: si rigenera dal .rc.
if (-not (Test-Path ".\vmFluentValidator.res")) {
  & $BRCC ".\vmFluentValidator.rc" -fo".\vmFluentValidator.res"
}
& $DCC vmFluentValidator.dpk -B --no-config `
  "-NS$namespaces" `
  "-U$LIB;..\src;..\src\Validators" `
  "-I$LIB" "-R$LIB" "-O$LIB" `
  "-LE$OUT" "-LN$OUT" "-NU$OUT\dcu" `
  -w-
if ($LASTEXITCODE -ne 0) { throw "Build del package per $Platform fallita (exit $LASTEXITCODE)" }
