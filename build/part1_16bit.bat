@echo off
REM Parte 1: wdis + compiladores 16-bit (wcc/wpp) com bld 386 forçado
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
call "%OWROOT%\build\bumpver.bat"
call "%OWROOT%\cmnvars.bat"
set WATCOM=%OWROOT%\rel
set INCLUDE=%WATCOM%\h;%WATCOM%\h\nt
set LIBPATH=%WATCOM%\lib386\nt;%WATCOM%\lib386
set WLINK_LNK=%OWROOT%\build\bwlink.lnk
for %%P in (ndisasm cg cc plusplus) do (
  echo ============ BUILD %%P os_nt cpu_386 ============
  cd /d "%OWROOT%\bld\%%P"
  "%OWROOT%\build\binbuild\builder.exe" build os_nt cpu_386
  echo RC_%%P=%ERRORLEVEL%
)
echo === CPREL ===
cd /d "%OWROOT%\bld"
"%OWROOT%\build\binbuild\builder.exe" cprel os_nt cpu_386
echo CPREL_RC=%ERRORLEVEL%
dir "%OWROOT%\rel\binnt\wdis.exe" "%OWROOT%\rel\binnt\wcc.exe" "%OWROOT%\rel\binnt\wpp.exe" 2>&1
