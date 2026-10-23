@echo off
REM bumpver.bat - auto-incrementa o patch da LabsObjects Edition.
REM Uso: call "%OWROOT%\build\bumpver.bat" (com OWROOT definido).
REM Le build\version.bin, soma 1, grava de volta e exporta OWBLDVER_PATCH.
REM O banner vira "Version 2.0.<N>" (ver bld/watcom/h/banner.h).
set "VFILE=%OWROOT%\build\version.bin"
if "%OWROOT%" == "" set "VFILE=%~dp0version.bin"
if not exist "%VFILE%" echo 0>"%VFILE%"
set OWBLDVER_PATCH=0
set /p OWBLDVER_PATCH=<"%VFILE%"
if "%OWBLDVER_PATCH%" == "" set OWBLDVER_PATCH=0
set /a OWBLDVER_PATCH=OWBLDVER_PATCH+1
>"%VFILE%" echo %OWBLDVER_PATCH%
echo OWBLDVER_PATCH=%OWBLDVER_PATCH%
