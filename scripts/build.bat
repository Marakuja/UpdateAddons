@echo off

set buildDir=%~dp0..\build
if not exist %buildDir% mkdir %buildDir%

pushd %buildDir%

:: copy code to build
xcopy ..\code . /s /y /d

:: copy changelog.md and VERSION to builddir
xcopy ..\changelog.md . /y /d
xcopy ..\VERSION . /y /d

popd