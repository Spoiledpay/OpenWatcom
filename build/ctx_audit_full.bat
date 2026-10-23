@echo off
REM ctx_audit_full.bat - auditoria profunda ON-DEMAND via ctx.exe (Fase C).
REM Uso: call "%OWROOT%\build\ctx_audit_full.bat"  (ex.: pre-release, nightly)
REM Nao e' chamado pela suite quente (test_examples) por ser lento; roda sob
REM demanda. Sem ctx.exe no PATH: no-op silencioso, sempre RC=0.
REM Com ctx.exe: verify + health + audit list em build\tmp_audit\ (offline).
REM Nunca falha o build: sai sempre RC=0 (auditoria nao bloqueia release).
where ctx.exe >nul 2>nul
if errorlevel 1 exit /b 0
if "%OWROOT%"=="" set OWROOT=%~dp0..
pushd "%OWROOT%" >nul 2>&1
if errorlevel 1 exit /b 0
set AUDDIR=%OWROOT%\build\tmp_audit
if not exist "%AUDDIR%" mkdir "%AUDDIR%" >nul 2>&1
echo === ctx verify (%DATE% %TIME%) === >"%AUDDIR%\audit_full.log" 2>&1
ctx.exe --offline verify >>"%AUDDIR%\audit_full.log" 2>&1
echo. >>"%AUDDIR%\audit_full.log" 2>&1
echo === ctx health (%DATE% %TIME%) === >>"%AUDDIR%\audit_full.log" 2>&1
ctx.exe --offline health >>"%AUDDIR%\audit_full.log" 2>&1
echo. >>"%AUDDIR%\audit_full.log" 2>&1
echo === ctx audit list (%DATE% %TIME%) === >>"%AUDDIR%\audit_full.log" 2>&1
ctx.exe --offline audit list >>"%AUDDIR%\audit_full.log" 2>&1
echo. >>"%AUDDIR%\audit_full.log" 2>&1
echo === ctx build list (%DATE% %TIME%) === >>"%AUDDIR%\audit_full.log" 2>&1
ctx.exe --offline build list >>"%AUDDIR%\audit_full.log" 2>&1
popd >nul 2>&1
exit /b 0
