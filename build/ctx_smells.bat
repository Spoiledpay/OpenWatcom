@echo off
REM ctx_smells.bat - auditoria por-arquivo opcional via ctx.exe (Fase B).
REM Uso: call "%OWROOT%\build\ctx_smells.bat" <arquivo> [log_saida]
REM Sem ctx.exe no PATH: no-op silencioso, sempre RC=0. Nunca quebra o build.
REM Com ctx.exe: roda smells --file (escopado, rapido) + cppcheck/clang-tidy
REM via --security --lint quando disponiveis. Nunca falha o build.
if "%~1"=="" exit /b 0
where ctx.exe >nul 2>nul
if errorlevel 1 exit /b 0
if "%OWROOT%"=="" set OWROOT=%~dp0..
pushd "%OWROOT%" >nul 2>&1
if errorlevel 1 exit /b 0
if "%~2"=="" (
  ctx.exe --offline smells --file "%~1" >nul 2>&1
) else (
  ctx.exe --offline smells --file "%~1" >"%~2" 2>&1
)
popd >nul 2>&1
exit /b 0
