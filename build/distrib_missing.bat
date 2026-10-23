@echo off
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNEWWGML=1
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\cmnvars.bat"
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set OWRELROOT=%OWROOT%\rel
cd /d "%OWROOT%\distrib\ow"
"%OWROOT%\build\binbuild\builder.exe" missing os_nt cpu_386 instwin32
echo MISSING_RC=%ERRORLEVEL%
