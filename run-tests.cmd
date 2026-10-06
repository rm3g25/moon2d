@echo off
rem Builds the test suite and runs it.
rem Exit code: 0 - all green, 1 - a test is red, 2 - the build failed.
setlocal
cd /d "%~dp0"

if defined BDS goto :Build

rem RAD Studio says where it lives in the registry; of several versions
rem the last listed wins.
for /f "delims=" %%K in ('reg query "HKCU\Software\Embarcadero\BDS" 2^>nul') do (
  for /f "tokens=2,*" %%A in ('reg query "%%K" /v RootDir 2^>nul ^| find "RootDir"') do set "BdsRoot=%%B"
)
if not defined BdsRoot goto :NoCompiler
if not "%BdsRoot:~-1%"=="\" set "BdsRoot=%BdsRoot%\"
call "%BdsRoot%bin\rsvars.bat"
if not defined BDS goto :NoCompiler

:Build
msbuild Tests\Moon2D.Tests.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /nologo /v:minimal
if errorlevel 1 exit /b 2

bin\Moon2D.Tests.exe %*
exit /b %ERRORLEVEL%

:NoCompiler
echo RAD Studio is not found: run this from a RAD Studio command prompt.
exit /b 2
