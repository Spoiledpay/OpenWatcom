@echo off
set OWTOOLS=WATCOM
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNEWWGML=1
set OWNOBUILD=f77lib f77wfc f77wfl
set "OWROOT=C:\Projetos\open-watcom-v2-master"
set "WATCOM=%OWROOT%\rel"
set "PATH=%WATCOM%\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%"
call "%OWROOT%\cmnvars.bat"
cd /d "%OWROOT%\bld"
..\build\binbuild\builder rel
cd /d "%OWROOT%"
