@echo off
REM Build della suite di test FluentValidator con il compilatore a riga di comando.
REM Equivalente cmd di build.ps1, con i check di runtime attivi.
REM
REM   build_tests.bat            -> Win32 (default)
REM   build_tests.bat Win64
REM   build_tests.bat Linux64    -> richiede l'SDK Linux deployato dalla IDE
setlocal

set PLATFORM=%~1
if "%PLATFORM%"=="" set PLATFORM=Win32

if /i "%PLATFORM%"=="Win32" goto :p_win32
if /i "%PLATFORM%"=="Win64" goto :p_win64
if /i "%PLATFORM%"=="Linux64" goto :p_linux64
echo Piattaforma non supportata: %PLATFORM% ^(attese: Win32, Win64, Linux64^)
exit /b 1

:p_win32
set PLATFORM=Win32
set DCCEXE=dcc32.exe
set LIBDIR=win32
set NS=System;System.Win;Winapi;Vcl;Data
goto :platform_done

:p_win64
set PLATFORM=Win64
set DCCEXE=dcc64.exe
set LIBDIR=win64
set NS=System;System.Win;Winapi;Vcl;Data
goto :platform_done

:p_linux64
set PLATFORM=Linux64
set DCCEXE=dcclinux64.exe
set LIBDIR=linux64
set NS=System;Posix;Data
goto :platform_done

:platform_done
set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0
set DCC="%BDS%\bin\%DCCEXE%"
set BRCC="%BDS%\bin\brcc32.exe"
set LIB=%BDS%\lib\%LIBDIR%\release
set DUNITX=%BDS%\source\DUnitX
set OUT=.\%PLATFORM%\Debug

cd /d "%~dp0"

REM Il .res non e' sotto controllo di versione: si rigenera dal .rc.
if not exist "FluentValidatorTests.res" %BRCC% "FluentValidatorTests.rc" -fo"FluentValidatorTests.res"

%DCC% FluentValidatorTests.dpr ^
  -B ^
  --no-config ^
  -NS%NS% ^
  -U"%LIB%";"%DUNITX%";"..\src";"..\src\Validators" ^
  -I"%LIB%" ^
  -R"%LIB%" ^
  -O"%LIB%" ^
  -E"%OUT%" ^
  -NU"%OUT%\dcu" ^
  -DDEBUG ^
  -$O- -$W+ -$R+ -$Q+ -v -w-

endlocal
