# codegen Builder Control file
# ============================

set PROJDIR=<CWD>

[ INCLUDE "<OWROOT>/build/master.ctl" ]

cdsay .

[ INCLUDE intel/386/builder.ctl ]
# 16-bit codegen (cgi86) - necessário p/ wcc.exe/wpp.exe
[ INCLUDE intel/i86/builder.ctl ]
# RISC codegen (Alpha/MIPS/PPC) - necessário p/ cross compilers NT
[ INCLUDE risc/axp/builder.ctl ]
[ INCLUDE risc/mps/builder.ctl ]
[ INCLUDE risc/ppc/builder.ctl ]

cdsay .
