@echo off
REM Build mkdisk host tools (langdat,mkinf,uzip,mkexezip) with OW self-hosted tools
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNOBUILD=wclass ide ide2make browser dlgprs f77lib f77wfc f77wfl
set OWNEWWGML=1
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\cmnvars.bat"
REM cmnvars restaura WATCOM/INCLUDE originais: reaplicar self-host rel/
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
echo WATCOM=%WATCOM% INCLUDE=%INCLUDE%
REM 1) libs estaticas ziplib/zlib (dependencias do mkexezip/uzip)
if not exist "%OWROOT%\bld\setupgui\ziplib\binbuild" mkdir "%OWROOT%\bld\setupgui\ziplib\binbuild"
cd /d "%OWROOT%\bld\setupgui\ziplib\binbuild"
"%OWROOT%\build\binbuild\wmake.exe" -f ..\binmake bootstrap=1 verbose=1 bld_os=nt bld_cpu=386
echo ZIPLIB_RC=%ERRORLEVEL%
if not exist "%OWROOT%\bld\setupgui\zlib\binbuild" mkdir "%OWROOT%\bld\setupgui\zlib\binbuild"
cd /d "%OWROOT%\bld\setupgui\zlib\binbuild"
"%OWROOT%\build\binbuild\wmake.exe" -f ..\binmake bootstrap=1 verbose=1 bld_os=nt bld_cpu=386
echo ZLIB_RC=%ERRORLEVEL%
if not exist "%OWROOT%\bld\setupgui\mkdisk\binbuild" mkdir "%OWROOT%\bld\setupgui\mkdisk\binbuild"
cd /d "%OWROOT%\bld\setupgui\mkdisk\binbuild"
"%OWROOT%\build\binbuild\wmake.exe" -f ..\binmake bootstrap=1 verbose=1 bld_os=nt bld_cpu=386
echo MKDISK_RC=%ERRORLEVEL%
dir /b
