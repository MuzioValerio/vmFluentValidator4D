# Build della suite di test FluentValidator con il compilatore a riga di comando.
# Niente msbuild, nessuna dipendenza dalla IDE.
#
#   .\build.ps1                    # Win32 (default)
#   .\build.ps1 -Platform Win64
#   .\build.ps1 -Platform Linux64
#
# Win32 e Win64 sono verificati (249 test verdi su entrambi). Linux64 compila
# tutte le unit ma il link richiede l'SDK Linux deployato dalla IDE
# (Tools > Options > Deployment > SDK Manager): non e' mai stato eseguito
# end-to-end da qui.
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
$DUNITX = "$BDS\source\DUnitX"
$OUT = ".\$Platform\Debug"

New-Item -ItemType Directory -Force "$OUT\dcu" | Out-Null
# Il .res non e' sotto controllo di versione: si rigenera dal .rc.
if (-not (Test-Path ".\FluentValidatorTests.res")) {
  & $BRCC ".\FluentValidatorTests.rc" -fo".\FluentValidatorTests.res"
}
& $DCC FluentValidatorTests.dpr -B --no-config `
  "-NS$namespaces" `
  "-U$LIB;$DUNITX;..\src;..\src\Validators" `
  "-I$LIB" "-R$LIB" "-O$LIB" `
  "-E$OUT" "-NU$OUT\dcu" `
  -DDEBUG -w-
if ($LASTEXITCODE -ne 0) { throw "Build dei test per $Platform fallita (exit $LASTEXITCODE)" }
