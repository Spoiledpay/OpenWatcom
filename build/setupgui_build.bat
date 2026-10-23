@echo off
REM Build setupgui csetup.exe (nt386.gui) with OW self-hosted tools
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
set OWDISTRBUILD=0
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\cmnvars.bat"
REM cmnvars restaura WATCOM/INCLUDE: reaplicar self-host
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
echo WATCOM=%WATCOM% OWGUINOBUILD=[%OWGUINOBUILD%]
cd /d "%OWROOT%\bld\setupgui\nt386.gui"
"%OWROOT%\build\binbuild\builder.exe" build os_nt cpu_386
echo SETUPGUI_RC=%ERRORLEVEL%
dir /b *.exe 2>nul
