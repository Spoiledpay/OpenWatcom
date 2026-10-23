@echo off
REM ctx_log.bat - proveniencia opcional via ctx.exe (diario de codigo).
REM Uso: call "%OWROOT%\build\ctx_log.bat" <artefato>
REM Sem ctx.exe no PATH: no-op silencioso, sempre RC=0. Nunca quebra o build.
REM Com ctx.exe: registra o artefato no store do repo (%OWROOT%\.ctx),
REM 100% local e offline (nenhuma rede). Requer %OWROOT% definido.
if "%~1"=="" exit /b 0
where ctx.exe >nul 2>nul
if errorlevel 1 exit /b 0
if "%OWROOT%"=="" set OWROOT=%~dp0..
pushd "%OWROOT%" >nul 2>&1
if errorlevel 1 exit /b 0
ctx.exe --offline build record "%~1" >nul 2>&1
popd >nul 2>&1
exit /b 0
