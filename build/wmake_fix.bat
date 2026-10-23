@echo off
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNOBUILD=f77lib f77wfc f77wfl browser dlgprs
set OWGUINOBUILD=
set OWDOCBUILD=0
set OWNEWWGML=1
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\cmnvars.bat"
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
cd /d "%OWROOT%\bld\wmake"
"%OWROOT%\build\binbuild\builder.exe" build os_nt cpu_386
echo RC=%ERRORLEVEL%
dir "%OWROOT%\bld\wmake\nt386\" 2>&1
