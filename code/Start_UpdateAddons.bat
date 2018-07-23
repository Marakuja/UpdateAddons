@echo off
:: Name:    UpdateAddons.bat
:: Author:  Andreas Mürell
:: Date:    2018-07-23
:: Comment: Starts off powershell script updateaddons.ps1 with parameters given into this batch

setlocal enableextensions

cd /D "%~dp0"

title %~n0 %*
set /p VERSION=<%~dp0about\VERSION

:: --------------------------------------------

:MAIN
echo %TIME% - Starting UpdateAddons.bat (Version %VERSION%)
call :EvalParams %*
call :START_SCRIPT
echo %TIME% - Leaving UpdateAddons.bat
pause
goto:eof


:: --------------------------------------------
:: functions

:EvalParams
if "%1"=="" goto NoMoreParams
for %%i in (-scan -debug) do (
  if /i "%1"=="%%i" echo %TIME% - Info: Option %%i detected
)
:: SCAN
if "%1"=="-scan" set SCAN=-scan
:: DEBUG
if "%1"=="-debug" set DEBUG=-DEBUG

shift /1
goto EvalParams

:NoMoreParams
goto:eof

:: --------------------------------------------

:START_SCRIPT
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0updateaddons.ps1' %SCAN% %DEBUG%";
goto:eof

endlocal
