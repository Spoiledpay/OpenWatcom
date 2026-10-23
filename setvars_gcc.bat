@echo off
REM *****************************************************************
REM SETVARS_GCC.BAT - Windows GCC/MinGW version
REM *****************************************************************
REM Call this before building to set up the environment for GCC/MinGW

REM Set OWROOT to the Open Watcom source tree root
if "%OWROOT%" == "" set OWROOT=C:\Projetos\open-watcom-v2-master

REM Set OWTOOLS to identify the toolchain used by build process
REM Supported values: WATCOM VISUALC INTEL GCC
set OWTOOLS=GCC

REM Build control variables
set OWDOCBUILD=0
set OWDISTRBUILD=0
set OWGUINOBUILD=1
set OWOBJDIR=binbuild

REM Add MSYS2 POSIX tools to PATH (sed, awk, grep, cp, rm, etc.)
set OWMSYS2PATH=C:\msys64\usr\bin

REM Strawberry MinGW paths for GCC toolchain
set OWMINGWBIN=C:\Strawberry\c\bin

REM No GhostScript needed initially
set OWGHOSTSCRIPTPATH=

REM No DOSBOX needed initially
set OWDOSBOX=

REM Set bootstrap CPU/OS for wmake makeinit
set BOOTSTRAP_CPU=x64
set BOOTSTRAP_OS=nt

REM Set PATH - include MSYS2 tools and MinGW
set PATH=%OWMINGWBIN%;%OWMSYS2PATH%;%PATH%

REM Invoke the common environment setup
call "%OWROOT%\cmnvars.bat"

echo Environment set for GCC/MinGW build
echo OWROOT=%OWROOT%
echo OWTOOLS=%OWTOOLS%

cd "%OWROOT%"
