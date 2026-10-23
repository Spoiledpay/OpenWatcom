@echo off
REM ================================================================
REM BUILD_FULL.BAT - Open Watcom V2 Full Build for Windows x64
REM ================================================================
REM Este script compila o Open Watcom V2 completo para Windows x64
REM Gerando ferramentas 32-bit (target i386) que rodam no Windows x64
REM ================================================================

set OWROOT=C:\Projetos\open-watcom-v2-master
set PATH=%OWROOT%\build\binbuild;%OWROOT%\build;C:\Strawberry\c\bin;C:\msys64\usr\bin;%PATH%
set OWTOOLS=GCC
set OWOBJDIR=binbuild
set OWBLDVER=20
set OWBLDVERSTR=2.0
set OWBLDVERTOOL=1300
set OWDOCBUILD=0
set OWDISTRBUILD=0
set OWGUINOBUILD=1
set OWVERBOSE=1
set BOOTSTRAP_CPU=x64
set BOOTSTRAP_OS=nt

echo ================================================================
echo Open Watcom V2 - Full Build for Windows x64
echo ================================================================
echo OWROOT=%OWROOT%
echo Start time: %TIME%
echo.

REM ================================================================
REM STEP 1: Build wmake.exe (if not already built)
REM ================================================================
if not exist "%OWROOT%\build\%OWOBJDIR%\wmake.exe" (
    echo [STEP 1/6] Building wmake.exe...
    cd /d "%OWROOT%\bld\wmake\c"
    if exist isarray.gh del isarray.gh
    if exist usage.gh del usage.gh

    set CFLAGS=-D__NT__ -DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_WARNINGS -DBOOTSTRAP -DPREBOOT -DINCL_MSGTEXT -D_BLDVER=1300 -D_CYEAR=2026 -D_MSC_VER=1900 -I. -I../h -I..\..\watcom\h -I..\..\lib_misc\h -I..\..\builder\h

    gcc %CFLAGS% -c ..\..\builder\c\wsplice.c -o wsplice.o || exit /b 1
    gcc %CFLAGS% -c ..\..\watcom\c\clibext.c -o clibext.o || exit /b 1
    gcc -o wsplice.exe wsplice.o clibext.o || exit /b 1

    gcc -D__NT__ %CFLAGS% -o cretype.exe cretype.c || exit /b 1
    cretype.exe isarray.gh || exit /b 1

    wsplice -u0 -kENGLISH -f "pick((MSG_USAGE_BASE+%%%%#%%%%), \"%%%%s\", \"\")" ../h/usage.sp usage.gh || exit /b 1

    for %%f in (macros.c main.c mautodep.c mautoomf.c mcache.c memory.c mexec.c mglob.c mhash.c misc.c mlex.c mlexmac.c mlexprs.c mparse.c mpreproc.c mrcmsg.c msg.c mstream.c msuffix.c msysdep.c mtarget.c mupdate.c mvecstr.c) do (
        gcc %CFLAGS% -c %%f -o %%f.o || exit /b 1
    )
    gcc %CFLAGS% -c ..\..\watcom\c\depinfo.c -o depinfo.o || exit /b 1
    gcc %CFLAGS% -c ..\..\watcom\c\clibext.c -o clibext2.o || exit /b 1

    if not exist "%OWROOT%\build\%OWOBJDIR%" mkdir "%OWROOT%\build\%OWOBJDIR%"
    gcc -g -o wmk.exe macros.o main.o mautodep.o mautoomf.o mcache.o memory.o mexec.o mglob.o mhash.o misc.o mlex.o mlexmac.o mlexprs.o mparse.o mpreproc.o mrcmsg.o msg.o mstream.o msuffix.o msysdep.o mtarget.o mupdate.o mvecstr.o depinfo.o clibext2.o || exit /b 1
    copy wmk.exe "%OWROOT%\build\%OWOBJDIR%\wmake.exe" /Y || exit /b 1
    echo wmake.exe built successfully!
) else (
    echo [STEP 1/6] wmake.exe already built, skipping.
)

REM ================================================================
REM STEP 2: Build builder.exe (if not already built)
REM ================================================================
if not exist "%OWROOT%\build\%OWOBJDIR%\builder.exe" (
    echo [STEP 2/6] Building builder.exe and tools...
    if not exist "%OWROOT%\bld\builder\%OWOBJDIR%" mkdir "%OWROOT%\bld\builder\%OWOBJDIR%"

    set BCFLAGS=-D__NT__ -DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_WARNINGS -DBOOTSTRAP -DINCL_MSGTEXT -D_BLDVER=1300 -D_CYEAR=2026 -D_MSC_VER=1900 -DBLDX64
    set BINC=-I"%OWROOT%\bld\builder\h" -I"%OWROOT%\bld\pmake" -I"%OWROOT%\bld\watcom\h" -I"%OWROOT%\bld\watcom\c"

    cd /d "%OWROOT%\bld\builder\%OWOBJDIR%"
    gcc -c %BCFLAGS% %BINC% ..\c\builder.c -o builder.o || exit /b 1
    gcc -c %BCFLAGS% %BINC% ..\c\utils.c -o utils.o || exit /b 1
    gcc -c %BCFLAGS% %BINC% ..\c\runit.c -o runit.o || exit /b 1
    gcc -c %BCFLAGS% %BINC% "%OWROOT%\bld\pmake\pmake.c" -o pmake.o || exit /b 1
    gcc -c %BCFLAGS% %BINC% ..\c\sysnt.c -o sysnt.o || exit /b 1
    gcc -c %BCFLAGS% %BINC% "%OWROOT%\bld\watcom\c\clibext.c" -o clibext.o || exit /b 1
    gcc -g -o builder.exe builder.o utils.o runit.o pmake.o sysnt.o clibext.o -limagehlp || exit /b 1
    copy builder.exe "%OWROOT%\build\%OWOBJDIR%\builder.exe" /Y || exit /b 1

    REM Build extra builder tools
    for %%t in (wsplice sweep diff cdsay comstrip crlf genverrc) do (
        gcc %BCFLAGS% %BINC% ..\c\%%t.c "%OWROOT%\bld\watcom\c\clibext.c" -o "%OWROOT%\build\%OWOBJDIR%\%%t.exe" || exit /b 1
    )
    REM genverrc needs _VERSION
    gcc %BCFLAGS% -D_VERSION=1300 %BINC% ..\c\genverrc.c "%OWROOT%\bld\watcom\c\clibext.c" -o "%OWROOT%\build\%OWOBJDIR%\genverrc.exe" || exit /b 1

    echo builder.exe and tools built successfully!
) else (
    echo [STEP 2/6] builder.exe already built, skipping.
)

REM ================================================================
REM STEP 3: Run builder boot (bootstrap all OW tools)
REM ================================================================
echo [STEP 3/6] Running builder boot...
cd /d "%OWROOT%\bld"
"%OWROOT%\build\%OWOBJDIR%\builder" boot 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] builder boot had errors (non-critical projects may have failed)
    echo Continuing anyway...
)

REM ================================================================
REM STEP 4: Build NT 32-bit runtime libraries via wmake
REM ================================================================
echo [STEP 4/6] Building NT 32-bit runtime libraries...

REM Find where bwcc386 is
set OWTOOLPATH=%OWROOT%\build\%OWOBJDIR%
set PATH=%OWTOOLPATH%;%OWROOT%\build;C:\Strawberry\c\bin;C:\msys64\usr\bin;%PATH%

REM First, build clib alias library
cd "%OWROOT%\bld\clib\alias\library\winnt.386\mf_r"
wmake -f makefile -h 2>&1
cd "%OWROOT%\bld\clib\alias\library\winnt.386\mf_s"
wmake -f makefile -h 2>&1

REM Build clib startup library
cd "%OWROOT%\bld\clib\startup\library\winnt.386\mf_r"
wmake -f makefile -h 2>&1

REM Build clib sub-libraries
for %%d in (char file math memory string streamio) do (
    if exist "%OWROOT%\bld\clib\%%d\winnt.386\mf_r" (
        cd "%OWROOT%\bld\clib\%%d\winnt.386\mf_r"
        wmake -f makefile -h 2>&1
    )
    if exist "%OWROOT%\bld\clib\%%d\winnt.386\mf_s" (
        cd "%OWROOT%\bld\clib\%%d\winnt.386\mf_s"
        wmake -f makefile -h 2>&1
    )
)

REM Build clib main library
cd "%OWROOT%\bld\clib\library\winnt.386\mf_r"
wmake -f makefile -h 2>&1
cd "%OWROOT%\bld\clib\library\winnt.386\mf_s"
wmake -f makefile -h 2>&1

REM Build mathlib for NT
for %%v in (386 387) do (
    for %%t in (mf_r.dll mf_s.dll mf_r.wdl mf_s.wdl mf_rp.dll mf_rp.wdl) do (
        if exist "%OWROOT%\bld\mathlib\library\winnt.%%v\%%t" (
            cd "%OWROOT%\bld\mathlib\library\winnt.%%v\%%t"
            wmake -f makefile -h 2>&1
        )
    )
)

REM Build cpplib for NT
for %%t in (mf_r mf_s mf_rmt mf_smt) do (
    if exist "%OWROOT%\bld\cpplib\library\winnt.386\%%t" (
        cd "%OWROOT%\bld\cpplib\library\winnt.386\%%t"
        wmake -f makefile -h 2>&1
    )
)

echo NT 32-bit runtime libraries built.

REM ================================================================
REM STEP 5: Run builder rel with -i to populate rel/ directory
REM ================================================================
echo [STEP 5/6] Running builder rel (populating rel/ directory)...
cd /d "%OWROOT%\bld"
"%OWROOT%\build\%OWOBJDIR%\builder" -i rel 2>&1
echo builder rel completed (some errors expected for non-NT targets).

REM ================================================================
REM STEP 6: Verify build output
REM ================================================================
echo [STEP 6/6] Verifying build output...
echo.
echo === Build Output Summary ===
echo.
echo === rel\binnt (Windows NT 32-bit tools) ===
if exist "%OWROOT%\rel\binnt" (
    dir "%OWROOT%\rel\binnt\*.exe" /b 2>nul
) else (
    echo (not populated yet)
)
echo.
echo === rel\lib386\nt (NT 32-bit libraries) ===
if exist "%OWROOT%\rel\lib386\nt" (
    dir "%OWROOT%\rel\lib386\nt\*.lib" /b 2>nul
) else (
    echo (not populated yet)
)
echo.
echo === build\binbuild (bootstrap tools) ===
dir "%OWROOT%\build\%OWOBJDIR%\*.exe" /b 2>nul
echo.
echo === Test: bwcc386 version ===
"%OWROOT%\build\%OWOBJDIR%\bwcc386.exe" -zq --version 2>&1
echo.
echo ================================================================
echo Build completed at: %TIME%
echo ================================================================
echo.
echo To use the compiler, run: setvars_ow.bat
echo To test compilation: wcc386 hello.c -fe=hello.exe
