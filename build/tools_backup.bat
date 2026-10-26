@echo off
REM ================================================================
REM tools_backup.bat - snapshot/restore the Open Watcom bootstrap
REM ================================================================
REM Uso:
REM   tools_backup.bat
REM       cria ..\ow-tools-backup\<timestamp>\ com build\binbuild,
REM       rel\binnt, distrib\ow\bin e build\version.bin
REM
REM   tools_backup.bat restore <backup-dir>
REM       restaura os mesmos diretorios (overwrite, sem purge)
REM
REM Nunca e chamado automaticamente pela pipeline. Use antes de
REM clean.bat/bootclean ou de qualquer rebuild destrutivo.
REM ================================================================
setlocal EnableExtensions
if "%OWROOT%"=="" set "OWROOT=%~dp0.."
for %%I in ("%OWROOT%") do set "OWROOT=%%~fI"

if /i "%~1"=="restore" goto restore

if not exist "%OWROOT%\build\binbuild" (
    echo ERRO: %OWROOT%\build\binbuild nao existe.
    exit /b 1
)

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
if "%STAMP%"=="" set "STAMP=backup"
set "BASE=%OWROOT%\..\ow-tools-backup"
set "DST=%BASE%\%STAMP%"
if exist "%DST%" set "DST=%BASE%\%STAMP%_%RANDOM%"
mkdir "%DST%" >nul 2>&1
if not exist "%DST%" (
    echo ERRO: nao foi possivel criar %DST%
    exit /b 1
)

echo Backup para: %DST%
call :copy_tree "%OWROOT%\build\binbuild" "%DST%\binbuild"
call :copy_tree "%OWROOT%\rel\binnt" "%DST%\rel-binnt"
call :copy_tree "%OWROOT%\distrib\ow\bin" "%DST%\distrib-bin"
copy /Y "%OWROOT%\build\version.bin" "%DST%\version.bin" >nul 2>&1

set "VER="
for /f %%V in ('type "%OWROOT%\build\version.bin" 2^>nul') do set "VER=%%V"
> "%DST%\MANIFEST.txt" echo backup=%STAMP%
>>"%DST%\MANIFEST.txt" echo version=%VER%
>>"%DST%\MANIFEST.txt" echo binbuild_files=0
>>"%DST%\MANIFEST.txt" echo rel_binnt_files=0
>>"%DST%\MANIFEST.txt" echo distrib_files=0
for /f %%C in ('dir /b /a-d "%DST%\binbuild" 2^>nul ^| find /c /v ""') do (
    powershell -NoProfile -Command "(Get-Content '%DST%\MANIFEST.txt') -replace 'binbuild_files=0','binbuild_files=%%C' | Set-Content '%DST%\MANIFEST.txt'"
)
for /f %%C in ('dir /b /a-d "%DST%\rel-binnt" 2^>nul ^| find /c /v ""') do (
    powershell -NoProfile -Command "(Get-Content '%DST%\MANIFEST.txt') -replace 'rel_binnt_files=0','rel_binnt_files=%%C' | Set-Content '%DST%\MANIFEST.txt'"
)
for /f %%C in ('dir /b /a-d "%DST%\distrib-bin" 2^>nul ^| find /c /v ""') do (
    powershell -NoProfile -Command "(Get-Content '%DST%\MANIFEST.txt') -replace 'distrib_files=0','distrib_files=%%C' | Set-Content '%DST%\MANIFEST.txt'"
)
echo.
echo Backup concluido.
type "%DST%\MANIFEST.txt"
exit /b 0

:copy_tree
robocopy "%~1" "%~2" /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS >nul
if errorlevel 8 (
    echo ERRO: robocopy falhou para %~1
    exit /b 1
)
exit /b 0

:restore
if "%~2"=="" (
    echo Uso: tools_backup.bat restore ^<backup-dir^>
    exit /b 1
)
set "SRC=%~2"
if not exist "%SRC%\binbuild" (
    echo ERRO: %SRC%\binbuild nao existe.
    exit /b 1
)
echo Restaurando de: %SRC%
robocopy "%SRC%\binbuild" "%OWROOT%\build\binbuild" /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS
if errorlevel 8 exit /b 1
if exist "%SRC%\rel-binnt" robocopy "%SRC%\rel-binnt" "%OWROOT%\rel\binnt" /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS
if errorlevel 8 exit /b 1
if exist "%SRC%\distrib-bin" robocopy "%SRC%\distrib-bin" "%OWROOT%\distrib\ow\bin" /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS
if errorlevel 8 exit /b 1
if exist "%SRC%\version.bin" copy /Y "%SRC%\version.bin" "%OWROOT%\build\version.bin" >nul
echo Restore concluido.
exit /b 0
