@echo off
set OWROOT=C:\Projetos\open-watcom-v2-master
set OWTOOLS=WATCOM
set WATCOM=%OWROOT%\rel
set OWOBJDIR=binbuild
set OWVERBOSE=1
REM WATCOM self-host no x64: força bld 386 (ver win_complete.bat)
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
for %%P in (causeway wipfc vi wprof wsample mstools cvpack idebatch ide browser) do (
  echo ============ BUILD %%P os_nt cpu_386 ============
  cd /d "%OWROOT%\bld\%%P" 2>nul
  if errorlevel 1 (
    echo SKIP %%P - no dir
  ) else (
    "%OWROOT%\build\binbuild\builder.exe" build os_nt cpu_386
    echo RC_%%P=%ERRORLEVEL%
  )
)
echo === CPREL ===
cd /d "%OWROOT%\bld"
"%OWROOT%\build\binbuild\builder.exe" cprel os_nt cpu_386
echo CPREL_RC=%ERRORLEVEL%
