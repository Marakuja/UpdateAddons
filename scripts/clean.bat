@echo off

set buildDir=%~dp0..\build

if exist %buildDir% (
    pushd %buildDir%
    :: delete files
    del /s /f /q *.*
    :: delete directories
    for /f %%f in ('dir /ad /b .') do rd /s /q .\%%f
    popd
)