@echo off
REM Build Windows x86 installer (distrib/ow nt386) com tools self-hosted
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNOBUILD=wclass ide ide2make browser dlgprs f77lib f77wfc f77wfl
set OWGUINOBUILD=
set OWDOCBUILD=0
set OWNEWWGML=1
set OWDISTRBUILD=1
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\cmnvars.bat"
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
set OWRELROOT=%OWROOT%\rel
echo OWRELROOT=%OWRELROOT%
cd /d "%OWROOT%\distrib\ow"
"%OWROOT%\build\binbuild\builder.exe" install os_nt cpu_386 instwin32
echo DISTRIB_RC=%ERRORLEVEL%
dir /b bin 2>nul
dir /b ..\..\rel\*.exe 2>nul
REM Proveniencia opcional dos instaladores (no-op sem ctx.exe; nunca falha)
for %%F in (bin\*.exe) do call "%OWROOT%\build\ctx_log.bat" "%%~fF"
REM Fase A: memoria + checkpoint de auditoria (no-op sem ctx.exe; nunca falha)
call "%OWROOT%\build\ctx_mem.bat" "distrib_build DISTRIB_RC=%ERRORLEVEL%" "Instaladores c+f77 rebuildados" note
call "%OWROOT%\build\ctx_checkpoint.bat"
