@echo off
:: Name:    UpdateAddons.bat
:: Author:  Andreas Mürell
:: Date:    2018-07-23
:: Comment: Starts off powershell script updateaddons.ps1 with parameters given into this batch

setlocal enableextensions

cd /D "%~dp0"

title %~n0 %*

:: --------------------------------------------

:MAIN
echo %TIME% - Starting UpdateAddons.bat
call :EvalParams %*
call :START_SCRIPT
echo %TIME% - Leaving UpdateAddons.bat
if not defined EDIT pause
goto:eof


:: --------------------------------------------
:: functions

:EvalParams
if "%1"=="" goto NoMoreParams
for %%i in (-scan -edit) do (
  if /i "%1"=="%%i" echo %TIME% - Info: Option %%i detected
)
:: SCAN
if /i "%1"=="-scan" set SCAN= -Scan

:: EDIT
if /i "%1"=="-edit" set EDIT= -Edit

shift /1
goto EvalParams

:NoMoreParams
goto:eof

:: --------------------------------------------

:START_SCRIPT
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0UpdateAddons.ps1'%SCAN%%EDIT%"
goto:eof

endlocal
