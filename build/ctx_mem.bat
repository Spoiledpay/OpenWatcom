@echo off
REM ctx_mem.bat - memoria opcional via ctx.exe (Fase A).
REM Uso: call "%OWROOT%\build\ctx_mem.bat" "<titulo>" "<descricao>" [tipo]
REM Sem ctx.exe no PATH: no-op silencioso, sempre RC=0. Nunca quebra o build.
if "%~1"=="" exit /b 0
where ctx.exe >nul 2>nul
if errorlevel 1 exit /b 0
if "%OWROOT%"=="" set OWROOT=%~dp0..
pushd "%OWROOT%" >nul 2>&1
if errorlevel 1 exit /b 0
set MEMTYPE=note
if not "%~3"=="" set MEMTYPE=%~3
ctx.exe --offline memory add --title "%~1" --description "%~2" --type %MEMTYPE% >nul 2>&1
popd >nul 2>&1
exit /b 0
