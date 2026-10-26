@echo off
REM Completa distro Windows NT386 C/C++ (tools+libs) com self-host
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
REM WATCOM self-host no x64: força bld 386 (wmake 64-bit auto-detecta x64,
REM mas toolchain WATCOM só define compiladores 386 em local.mif)
set BOOTSTRAP_CPU=386
set BOOTSTRAP_OS=nt
set OWNOBUILD=f77lib f77wfc f77wfl browser dlgprs
set OWGUINOBUILD=
set OWDOCBUILD=0
set OWNEWWGML=1
set OWDISTRBUILD=0
set PATH=%OWROOT%\rel\binnt;%OWROOT%\build\binbuild;%OWROOT%\build;%PATH%
call "%OWROOT%\build\bumpver.bat"
call "%OWROOT%\cmnvars.bat"
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
set LIB=%WATCOM%\lib386\nt;%WATCOM%\lib386
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
echo === START %TIME% ===
for %%P in (watcom hdr w32api clib mathlib cpplib rtdll wres orl owl dwarf cfloat wasm nwlib wl wmake wtouch cg cc plusplus rc wcl ndisasm exedump dmpobj wstrip mstools wclass wcl idebatch uninstal) do (
  echo ============ BUILD %%P os_nt cpu_386 ============
  cd /d "%OWROOT%\bld\%%P"
  "%OWROOT%\build\binbuild\builder.exe" build os_nt cpu_386
  echo RC_%%P=%ERRORLEVEL%
)
echo === rel/cprel os_nt cpu_386 ===
cd /d "%OWROOT%\bld"
"%OWROOT%\build\binbuild\builder.exe" cprel os_nt cpu_386
echo CPREL_RC=%ERRORLEVEL%
echo === DONE %TIME% ===
dir "%OWROOT%\rel\binnt\wmake.exe" "%OWROOT%\rel\binnt\wtouch.exe" "%OWROOT%\rel\binnt\wdump.exe" "%OWROOT%\rel\binnt\dmpobj.exe" 2>&1
