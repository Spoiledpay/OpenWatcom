@echo off
REM *****************************************************************
REM SETVARS_OW.BAT - Open Watcom V2 Environment for End Users
REM *****************************************************************
REM Use this script to compile C/C++ programs with Open Watcom V2.
REM No GCC/MinGW needed - only the OW tools (wcc386, wlink, etc.).
REM
REM Usage:  setvars_ow.bat
REM         wcc386 programa.c -fo=programa.obj -s
REM         wlink form windows nt name programa.exe file programa.obj library clib3r.lib,kernel32.lib,user32.lib
REM
REM Or in one step (for C++ use wpp386):
REM         wcl386 programa.c -fe=programa.exe -l=nt
REM
REM For floating-point math, use -fpc to avoid inline FPU issues:
REM         wcc386 programa.c -fo=programa.obj -fpc
REM         wlink ... library math3r.lib,clib3r.lib,clbrdll.lib,kernel32.lib,user32.lib
REM *****************************************************************

REM Set OWROOT to the Open Watcom release directory
if "%OWROOT%" == "" set OWROOT=C:\Projetos\open-watcom-v2-master\rel

REM Set WATCOM to the release directory
set WATCOM=%OWROOT%

REM Add OW tools to PATH
set PATH=%OWROOT%\binnt;%PATH%

REM Set include paths for C/C++ headers
set INCLUDE=%OWROOT%\h;%OWROOT%\h\nt

REM Set library paths for the linker (libpath + convenience var)
set LIBPATH=%OWROOT%\lib386\nt
set LIB386=%OWROOT%\lib386

echo Open Watcom V2 environment set
echo   WATCOM=%WATCOM%
echo   PATH includes %OWROOT%\binnt
echo   INCLUDE=%INCLUDE%
echo.
echo To compile:  wcc386 source.c -fo=source.obj -s -i%%INCLUDE%%
echo.
echo To link (with libpath to avoid default lib search errors):
echo   wlink form windows nt name prog.exe file source.obj ^
echo       libpath "%LIB386%" libpath "%LIBPATH%" ^
echo       library clib3r.lib,kernel32.lib,user32.lib
echo.
echo For programs with floating-point math, add -fpc and math libs:
echo   wcc386 source.c -fo=source.obj -fpc
echo   wlink ... library math3r.lib,clib3r.lib,clbrdll.lib,kernel32.lib,user32.lib
echo.
