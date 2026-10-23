@echo off
REM ctx_checkpoint.bat - checkpoint de auditoria opcional via ctx.exe (Fase A).
REM Uso: call "%OWROOT%\build\ctx_checkpoint.bat"
REM Sem ctx.exe no PATH: no-op silencioso, sempre RC=0. Nunca quebra o build.
where ctx.exe >nul 2>nul
if errorlevel 1 exit /b 0
if "%OWROOT%"=="" set OWROOT=%~dp0..
pushd "%OWROOT%" >nul 2>&1
if errorlevel 1 exit /b 0
ctx.exe --offline audit checkpoint >nul 2>&1
popd >nul 2>&1
exit /b 0
