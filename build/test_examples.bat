@echo off
REM Testa compilador OW rel/ com exemplos C/C++/Fortran (sem input interativo)
set OWROOT=C:\Projetos\open-watcom-v2-master
set WATCOM=%OWROOT%\rel
set PATH=%WATCOM%\binnt;%OWROOT%\build\binbuild;%PATH%
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIB386=%WATCOM%\lib386
set LIBPATH=%WATCOM%\lib386\nt
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
set T=%OWROOT%\build\tmp_test
if not exist "%T%" mkdir "%T%"
set PASS=0
set FAIL=0

echo [1/4] hello.c (C, console) ...
"%WATCOM%\binnt\wcc386.exe" -fo="%T%\hello.obj" -s -i="%WATCOM%\h" -i="%WATCOM%\h\nt" "%OWROOT%\examples\hello.c" >"%T%\t1.log" 2>&1
if errorlevel 1 ( echo FAIL compile & type "%T%\t1.log" & set /a FAIL+=1 ) else (
"%WATCOM%\binnt\wlink.exe" form windows nt name "%T%\hello.exe" file "%T%\hello.obj" libpath "%LIB386%" libpath "%LIBPATH%" library clib3r.lib,kernel32.lib,user32.lib >>"%T%\t1.log" 2>&1
if errorlevel 1 ( echo FAIL link & type "%T%\t1.log" & set /a FAIL+=1 ) else (
"%T%\hello.exe" >"%T%\t1.out" 2>&1
if errorlevel 1 ( echo FAIL run & set /a FAIL+=1 ) else ( echo PASS & type "%T%\t1.out" & set /a PASS+=1 )))

echo [2/4] hello.cpp (C++) ...
"%WATCOM%\binnt\wpp386.exe" -fo="%T%\hello_cpp.obj" -s -i="%WATCOM%\h" -i="%WATCOM%\h\nt" "%OWROOT%\examples\hello.cpp" >"%T%\t2.log" 2>&1
if errorlevel 1 ( echo FAIL compile & type "%T%\t2.log" & set /a FAIL+=1 ) else (
"%WATCOM%\binnt\wlink.exe" form windows nt name "%T%\hello_cpp.exe" file "%T%\hello_cpp.obj" libpath "%LIB386%" libpath "%LIBPATH%" library plib3r.lib,clib3r.lib,kernel32.lib,user32.lib >>"%T%\t2.log" 2>&1
if errorlevel 1 ( echo FAIL link & type "%T%\t2.log" & set /a FAIL+=1 ) else (
"%T%\hello_cpp.exe" >"%T%\t2.out" 2>&1
if errorlevel 1 ( echo FAIL run & set /a FAIL+=1 ) else ( echo PASS & type "%T%\t2.out" & set /a PASS+=1 )))

echo [3/4] math_test.c (C, -fpc) ...
"%WATCOM%\binnt\wcc386.exe" -fo="%T%\math.obj" -s -fpc -i="%WATCOM%\h" -i="%WATCOM%\h\nt" "%OWROOT%\examples\math_test.c" >"%T%\t3.log" 2>&1
if errorlevel 1 ( echo FAIL compile & type "%T%\t3.log" & set /a FAIL+=1 ) else (
"%WATCOM%\binnt\wlink.exe" form windows nt name "%T%\math.exe" file "%T%\math.obj" libpath "%LIB386%" libpath "%LIBPATH%" library math3r.lib,clib3r.lib,clbrdll.lib,kernel32.lib,user32.lib >>"%T%\t3.log" 2>&1
if errorlevel 1 ( echo FAIL link & type "%T%\t3.log" & set /a FAIL+=1 ) else (
copy "%WATCOM%\binnt\clbr20.dll" "%T%\" /Y >nul
"%T%\math.exe" >"%T%\t3.out" 2>&1
if errorlevel 1 ( echo FAIL run & set /a FAIL+=1 ) else ( echo PASS & type "%T%\t3.out" & set /a PASS+=1 )))

echo [4/4] hello.for (Fortran, wfl386 compile+link) ...
copy "%OWROOT%\examples\hello.for" "%T%\wfl_hello.for" /Y >nul
cd /d "%T%"
"%WATCOM%\binnt\wfl386.exe" wfl_hello.for -fe=wfl_hello.exe >"%T%\t4.log" 2>&1
if errorlevel 1 ( echo FAIL wfl386 & type "%T%\t4.log" & set /a FAIL+=1 ) else (
if not exist "%T%\wfl_hello.exe" ( echo FAIL no-exe & set /a FAIL+=1 ) else (
"%T%\wfl_hello.exe" >"%T%\t4.out" 2>&1
if errorlevel 1 ( echo FAIL run & set /a FAIL+=1 ) else ( echo PASS & type "%T%\t4.out" & set /a PASS+=1 )))
cd /d "%OWROOT%"

REM Proveniencia opcional (no-op sem ctx.exe no PATH; nunca falha)
if exist "%T%\hello.exe" call "%OWROOT%\build\ctx_log.bat" "%T%\hello.exe"
if exist "%T%\hello_cpp.exe" call "%OWROOT%\build\ctx_log.bat" "%T%\hello_cpp.exe"
if exist "%T%\math.exe" call "%OWROOT%\build\ctx_log.bat" "%T%\math.exe"
if exist "%T%\wfl_hello.exe" call "%OWROOT%\build\ctx_log.bat" "%T%\wfl_hello.exe"

REM Fase A: memoria do veredito (no-op sem ctx.exe; nunca falha)
call "%OWROOT%\build\ctx_mem.bat" "test_examples PASS=%PASS% FAIL=%FAIL%" "Suite C/C++/math/Fortran via wcc386/wpp386/wfl386" note

REM Fase B: smells por-arquivo nos 2 fontes fixados (no-op sem ctx.exe; nunca falha)
call "%OWROOT%\build\ctx_smells.bat" "bld\f77\wfl\c\wfl.c" "%T%\smells_wfl.log"
call "%OWROOT%\build\ctx_smells.bat" "bld\wl\c\cmdutils.c" "%T%\smells_cmdutils.log"

echo =======================
echo PASS=%PASS% FAIL=%FAIL%
if %FAIL% NEQ 0 exit /b 1
