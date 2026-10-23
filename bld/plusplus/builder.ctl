# C++ compiler Builder Control file
# =================================

set PROJDIR=<CWD>

[ INCLUDE "<OWROOT>/build/master.ctl" ]

cdsay .

# 16-bit compiler (wpp.exe) - incluído na distro Windows completa
[ INCLUDE i86/builder.ctl ]
[ INCLUDE 386/builder.ctl ]
# Cross targets (Alpha/MIPS/PPC hosted on NT) - distro completa
[ INCLUDE axp/builder.ctl ]
[ INCLUDE mps/builder.ctl ]
[ INCLUDE ppc/builder.ctl ]

cdsay .
