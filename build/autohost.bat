@echo off
set OWTOOLS=WATCOM
REM Self-host no x64: wmake 64-bit detecta bld x64, mas toolchain WATCOM
REM só tem compiladores 386 (build/mif/local.mif) -> força 386
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNEWWGML=1
set "OWROOT=C:\Projetos\open-watcom-v2-master"
set "WATCOM=%OWROOT%\rel"
set "PATH=%WATCOM%\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%"
call "%OWROOT%\cmnvars.bat"
cd /d "%OWROOT%\bld"
..\build\binbuild\builder build
cd /d "%OWROOT%"
